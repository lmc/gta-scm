
require 'gta_scm/ruby_to_scm_compiler'

# NOTE: can use vlstring for text opcodes, possibly more?
#   todo: find out if string var assigns will work

# TODO:
# inline logging `log("var = #{var}")`
# some way to assign variable allocator assignments (ie. put specific vars in the temp bucket)
# properly emit (end_var_args) for (start_new_script)
# emit smallest immediate int size possible
# share function defs between compiler instances
# while loops
# next loop keyword
# for i in 0..12
# array/struct syntax:
#   $cars = IntegerArray[8]
#   @coords = Vector3[ 500.0 , 400.0 , 20.0 ]
#   foo(Vector3[],1000) => foo(0.0,0.0,0.0,1000)
#   last thing left: instance/stack struct vars
# functions returning true/false when used in if statements (use temp vars on stack?)
# switch statements
# syntax for raw global/local vars (GLOBALS[12]/LOCALS[2]) ($123 / @12)
# allow calling routines with goto(&f1) / gosub(&f2)
# allowed to get var address with &$test ? need to compile as block_pass($test)
# declare function as using stack or static vars for returns/params
#   stack: recursion permitted, doesn't consume globals
#   static: consumes globals vars, smaller calls, no stack adjustment, no recursion permitted
#   use static for common calls

# DONE: stack inspector for debugger
# put breakpoint code to eval on stack? should have at least 32 bytes free on stack due to stackless gosub to breakpoint
# should debugger actually generate `stack[sc+0] = pc; goto(breakpoint)` for gosub-free breakpoint?

=begin
helper methods:

TODO: check stack canaries when yielding? high performance + will still catch/blame errors

def stack_verify_limit(next_up)
  next_up += $_sc
  if next_up >= $_stack_limit
  goto_if_false(:error_stack_overflow) 
  return

stack[+0] = next_up
gosub(stack_verify_limit)
stack[+0] = args as normal
gosub(function_as_normal)

def stack_verify_empty
  if $_sc == 0
  goto_if_false(:error_stack_populated_on_yield)
  return

script do
  main(wait: 0) do
    stack_adjust(-1)
    wait(0)
    stack_adjust(+1)

    code()
  end
end
=end

class GtaScm::RubyToScmCompiler2
  using GtaScm::RubyToScmCompiler::RefinedParserNodes

  attr_accessor :state
  attr_accessor :opcodes
  attr_accessor :opcode_names
  attr_accessor :functions
  attr_accessor :current_function
  attr_accessor :in_declare_block
  attr_accessor :in_functions_block
  attr_accessor :last_child_was_return
  attr_accessor :label_type
  attr_accessor :loop_labels
  attr_accessor :stack_locations
  attr_accessor :script_block_hash
  attr_accessor :main_block_hash
  attr_accessor :constants
  attr_accessor :scripts
  attr_accessor :struct_definitions
  attr_accessor :external_id
  attr_accessor :label_prefix

  def compile_lvars_as_temp_vars?; true; end

  def initialize(*args)
    self.functions = {
      # top-level stack frame for local vars
      nil => {
        locals: {},
        instances: {},
        globals: {},
        instance_arrays: {},
        global_arrays: {},
        instance_structs: {},
        global_structs: {},
        local_structs: {}
      }
    }
    self.opcodes = GtaScm::OpcodeDefinitions.new
    self.opcodes.load_definitions!("san-andreas")
    self.opcode_names = Hash[self.opcodes.names2opcodes.map{|k,v| [k.downcase.to_sym,k]}]
    self.current_function = nil
    self.in_functions_block = false
    self.in_declare_block = false
    self.label_type = :label
    self.loop_labels = []
    self.stack_locations = {
      stack: :"_stack",
      sc: :"_sc",
      size: 32
    }
    self.constants = {
      PLAYER: [:var,:_8],
      PLAYER_CHAR: [:var,:_12],
      DEBUGGER_ADDR: [:label,:debug_breakpoint_entry]
    }
    self.scripts = {}
    self.struct_definitions = {
      Vector3: { x: :float, y: :float, z: :float }
    }
    self.external_id = nil
  end

  def compiler_data(options = {})
    options.reverse_merge!(keep_instance_scope: false)
    data = {}
    data[:functions] = self.functions.deep_dup
    if options[:keep_instance_scope]

    elsif options[:use_instance_scope]
      data[:functions][nil][:instances] = @original_compiler_data[:functions][nil][:instances]
      data[:functions][nil][:instance_structs] = @original_compiler_data[:functions][nil][:instance_structs]
      data[:functions][nil][:instance_arrays] = @original_compiler_data[:functions][nil][:instance_arrays]
    else
      data[:functions][nil][:instances] = {}
      data[:functions][nil][:instance_structs] = {}
      data[:functions][nil][:instance_arrays] = {}
    end
    data[:functions][nil][:locals] = {}
    data[:constants] = self.constants.deep_dup
    if options[:keep_instance_scope]
      data[:instance_assigns] = [@ivar_lvar_id_counter,@ivar_lvar_ids]
    elsif options[:use_instance_scope]
      data[:instance_assigns] = @original_compiler_data[:instance_assigns]
    end
    data
  end

  def compiler_data=(val)
    val = val.deep_dup
    @original_compiler_data = val
    if val.present?
      self.functions = val[:functions]
      self.constants = val[:constants]
      if val[:instance_assigns]
        debugger
        @ivar_lvar_id_counter = val[:instance_assigns][0]
        @ivar_lvar_ids = val[:instance_assigns][1]
      end
    end
  end

  def opcode(name)
    if name.match(/^not_/)
      name = name[4..-1].to_sym
    end
    self.opcodes[ self.opcode_names[name] ]
  end

  def opcode_return_types(name)
    self.opcode(name).arguments.select{|a| a[:var]}.map{|a| a[:type]}
  end

  def transform_code(node,generate_v1_tokens = true)
    # node = self.transform_source(node)

    self.state = :scanning
    transform_node(node)
    # transform_node(node)
    self.state = :generating
    transformed = transform_node(node)

    if generate_v1_tokens
      transformed = transform_to_v1_tokens(transformed)
    end

    return transformed
  end

  DIRECT_GLOBAL_VAR_REGEX = %r{(\$\d+)}
  DIRECT_LOCAL_VAR_REGEX  = %r{(\@\d+)}
  def transform_source(code)
    code = code.dup
    code.gsub!( %r{\$(\d+)} , "\$_\\1")
    code.gsub!( %r{\@(\d+)} , "\@_\\1")
    code.gsub!( %r{\&((\@|\$)?(\w+))} , "block_pass(\\1)")
    code
  end

  def transform_node(node)
    case

    # generic block, seperate instructions as children
    when node.match( :begin )
      transforms = []
      self.last_child_was_return = false
      node.each do |child|
        self.last_child_was_return = true if child.type == :return
        tc = transform_node(child)
        debugger if !tc
        transforms += tc
      end
      transforms

    # Script declare
    # 
    # script(name: "foo") do
    #   ...
    # end
    #
    when node.match( :block , [0] => :send , [0,1] => :script , [1] => :args , [2] => [:begin,:block] )
      on_script_block( node )

    when node.match( :block , [0] => :send , [0,1] => :main , [1] => :args , [2] => [:begin,:block,:send] )
      on_main_block( node )

    # Function declare
    # 
    # function(:name) do |arg1|
    #   ...
    # end
    # 
    # s(:block,
    #   s(:send, nil, :function,
    #     s(:sym, :my_stack_function)),
    #   s(:args,
    #     s(:arg, :arg1),
    #     s(:arg, :arg2)),
    #   s(:begin,
    #     [body]
    when node.match( :block , [0] => :send , [0,1] => :function , [1] => :args , [2] => [:begin,:return,:send,:if] )
      on_function_block( node )
    # when node.match( :block , [0] => :send , [0,1] => :function , [1] => :args , [2] => [:begin,:return,:send] )
    #   debugger
    #   on_function_block( node )

    when node.match( :def , [1] => :args , [2] => [:begin,:return,:send,:if] )
      on_function_block( node )

    when node.match( :block , [0] => :send , [0,1] => :functions , [1] => [:args] , [2] => [:begin,:return,:send,:if,:def,:array] )
      on_functions_block( node )

    # when node.match( :send , [1] => :function )

    when node.match( :block , [0] => :send , [0,1] => :declare , [1] => :args )
      on_declare_block( node )

    when node.match( :send , [1] => [:float,:int] )
      on_declare_call( node )

    when node.match( :block, [0] => :send, [0,1] => :loop, [2] => [:begin,:send])
      on_loop( node )

    when node.match( :block, [0] => :send, [0,1] => :binary, [2] => [:begin,:send])
      on_binary_block( node )
    when node.match( :block, [0] => :send, [0,0] => :lvar, [0,0,0] => self.binary_block_lvar, [0,1] => [:replace,:delete,:patch,:include] )
      on_binary_block_call_block( node )
    when node.match( :send, [0] => :lvar, [0,0] => self.binary_block_lvar, [1] => [:replace,:delete,:patch,:include] )
      on_binary_block_call( node )

    when node.match( :if ) && node[2]
      on_if_else(node)

    when node.match( :if )
      on_if(node)

    when node.match( :break )
      on_break(node)

    # Generic block
    when node.match( :block )
      transform_node(node[0])

    # Operator Assign
    when node.match( [:op_asgn] , [0] => [:lvasgn,:ivasgn,:gvasgn], [1] => [:+,:-,:*,:/] )
      on_operator_assign( node )

    # Opcode call with no returns
    when node.match( :send ) && self.opcode_names[ node[1] ]
      on_opcode_call(node)

    # Opcode call with single return value
    # 
    # func_tmp2 = get_game_timer()
    #
    # s(:lvasgn, :func_tmp2,
    #   s(:send, nil, :get_game_timer))
    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send ) && self.opcode_names[ node[1][1] ]
      on_opcode_call(node)

    when node.match( :send , [1] => [:[],:[]=] ) && self.opcode_names[ node[3].andand[1] ]
      on_opcode_call(node)

    # Opcode call with multiple return values
    # 
    # x,y,z = get_char_coordinates(player_char)
    # 
    # s(:masgn,
    #   s(:mlhs,
    #     s(:lvasgn, :tx),
    #     s(:lvasgn, :ty),
    #     s(:lvasgn, :tz)),
    #   s(:send, nil, :get_char_coordinates,
    #     s(:lvar, :player_char)))
    when node.match( :masgn , [1] => :send ) && self.opcode_names[ node[1][1] ]
      on_opcode_call(node)

    # Negated opcode call
    when node.match( :send , [0] => :send , [1] => :! ) && self.opcode_names[ node[0][1] ]
      on_opcode_call(node[0],true)

    # Function call
    # 
    # my_function()
    #
    # 
    when node.match( :send ) && self.functions[ node[1] ]
      on_function_call(node)


    # Function call with single return value
    #
    # return_val = my_stack_function(@local_var,temp_var)
    #
    # s(:lvasgn, :return_val,
    #   s(:send, nil, :my_stack_function,
    #     s(:ivar, :@local_var),
    #     s(:lvar, :temp_var)))
    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send ) && self.functions[ node[1][1] ]
      on_function_call(node)

    # Function call with multiple return values
    #
    # x,y,z = my_stack_function(@local_var,temp_var)
    #
    # s(:masgn,
    #   s(:mlhs,
    #     s(:lvasgn, :x),
    #     s(:lvasgn, :y),
    #     s(:lvasgn, :z)),
    #   s(:send, nil, :my_stack_function,
    #     s(:ivar, :@local_var),
    #     s(:lvar, :temp_var)))
    when node.match( :masgn , [0] => :mlhs , [1] => :send ) && self.functions[ node[1][1] ]
      on_function_call(node)


    # Assignment
    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => [:lvar,:ivar,:gvar,:int,:float,:str,:const] )
      on_assign( node )

    when node.match( :send , [0] => [:lvar,:ivar,:gvar,:int,:float,:string] , [1] => :[]=, [3] => [:lvar,:ivar,:gvar,:int,:float,:string] )
      on_assign( node )

    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1,0] => [:lvar,:ivar,:gvar,:int,:float,:string] , [1,1] => :[] , [1,2] => [:lvar,:ivar,:gvar,:int,:float,:string] )
      on_assign( node )

    when node.match( :send, [0] => [:lvar,:ivar,:gvar] ) && node[1].match(/\w+=$/)
      on_assign( node )

    # Multi-assignment
    when node.match( :masgn , [0] => :mlhs , [1] => :array )
      on_multi_assign( node )

    when node.match( [:ivasgn,:gvasgn,:lvasgn] , [1] => :send , [1,1] => :block_pass)
      on_dereference_assign( node )



    # Return results of opcode call
    #
    # return get_char_coordinates(player_char)
    #
    # s(:return,
    #   s(:send, nil, :get_char_coordinates,
    #     s(:lvar, :player_char)))
    when node.match( :return , [0] => :send ) && self.opcode_names[ node[0][1] ]
      raise "FIXME: handle return directly from opcode call"

    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send, [1,1] => [:FloatArray,:IntegerArray])
      on_array_var_declare(node)

    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send, [1,0,1] => [:FloatArray,:IntegerArray], [1,1] => [:new,:[]])
      on_array_var_declare(node)

    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send, [1,0,1] => self.struct_definitions.keys, [1,1] => [:new,:[]])
      on_struct_var_declare(node)

    when node.match( :casgn )
      on_constant_declare(node)

    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send, [1,1] => [:to_i,:to_f] )
      on_type_cast(node)

    # Compare
    when node.match( :send , [1] => [:>,:<,:>=,:<=,:==,:!=] )
      on_compare(node)

    # Math expression
    when compilable_math_expression?(node)
      on_math_expression(node)

    when node.match( :send , [1] => [:debugger])
      on_debugger(node)

    when node.match( :send , [1] => [:log,:puts,:log_int,:log_float,:log_hex] , [2] => [:str,:dstr,:ivar,:gvar,:lvar,:send])
      on_log(node)

    # Return
    when node.match( :return )
      on_return( node )

    # FIXME: are these appropriate? they don't generate instructions
    when node.match( [:lvar,:ivar,:gvar] )
      on_var_use(node)

    when node.match( [:int,:float,:str] )
      on_immediate_use(node)

    when node.match( :send, [0] => :gvar, [1] => :[] )
      on_global_array_use(node)

    when node.match( :send, [0] => :ivar, [1] => :[] )
      on_instance_array_use(node)

    when node.match( :send, [0] => :gvar ) && self.functions[nil][:global_structs][ gvar_name(node[0][0]) ]
      on_var_use(node)

    # unknown function call, complain later when generating instructions
    when (node.match( :send ) || node.match( :lvasgn , [1] => :send)) && ![ :[], :[]= ].include?(node[1])
      if generating?
        debugger
        raise "unknown call #{node.inspect}"
      else
        [[:unknown_call, node[1] ]]
      end

    # raw s-expression output (is this is a good idea or horrible?)
    when node.match( :array , [0] => :sym )
      [
        eval(node.source_code)
      ]

    when :const
      on_const_use(node)


    # Default case
    else
      debugger
      node
      nil
    end
  end

  # lvar
  def on_lvar_use(node)
    case node.type
    when :lvar, :lvasgn
      if generating?
        # if node[0] == :x3
        #   x = is_lvar_safe_return_value?(node[0],self.current_function)
        #   debugger
        # end
        # debugger

        if return_var = safe_lvar_return_var(node[0],self.current_function)
          [:stack,resolved_lvar_stack_offset(return_var),node[0],resolved_lvar_type(node[0],current_function)]
        else
          [:stack,resolved_lvar_stack_offset(node[0]),node[0],resolved_lvar_type(node[0],current_function)]
        end
      else
        [:lvar,node[0]]
      end
    else
      raise "unknown lvar #{node.inspect}"
    end
  end
  # lvar = 1
  def on_lvar_assign(node,rhs)
    lhs = on_lvar_use(node)

    if scanning?
      if lhs[0] == :lvar && !self.functions[self.current_function][:arguments].andand[ lhs[1] ]
        self.functions[self.current_function][:locals][ lhs[1] ] ||= []
        if rhs
          self.functions[self.current_function][:locals][ lhs[1] ] << rhs
        end
      end
    end

    return lhs
  end

  def current_stack_vars(function_name)
    current_stack_vars_buckets(function_name).flatten
  end

  def current_stack_vars_buckets(function_name)
    slots = []
    # if !self.functions[function_name] || !self.functions[function_name][:returns]
    #   debugger
    # end
    if function_name
      slots << self.functions[function_name][:returns].map{|k,v| k }
      slots << self.functions[function_name][:arguments].map{|k,v|
        safe_lvar_return_var(k,function_name) ? nil : k
      }.compact
    end
    slots << self.functions[function_name][:locals].map{|k,v|
      safe_lvar_return_var(k,function_name) ? nil : k
    }.compact
  end

  def resolved_lvar_stack_offset(lvar_name,function_name = self.current_function)
    slots = current_stack_vars(function_name)
    if index = slots.index(lvar_name)
      (slots.size - index) * -1
    else
      debugger
      raise "no resolved stack offset for #{lvar_name} in #{self.current_function}"
    end
  end

  def resolve_function_return_types(function_name)
    self.functions[function_name][:returns].map do |return_index,observed_uses|
      resolved_types = observed_uses.map do |use|
        self.resolve_var_type(use,function_name)
      end
      if resolved_types.uniq.size > 1
        raise "multiple return types for #{function_name} return index #{return_index}: #{resolved_types.inspect}"
      end
      resolved_types[0]
    end
  end

  def resolve_var_type(var_or_val,caller)
    var_or_val = [var_or_val] if var_or_val.is_a?(Symbol) # HACK: rewrap these

    case var_or_val[0]
    when :ivar
      resolved_ivar_type(var_or_val[1])
    when :gvar
      # :TODO_resolve_gvar_type
      resolved_gvar_type(var_or_val[1])
    when :lvar
      resolved_lvar_type(var_or_val[1],caller)
    when :int32,:int16,:int8,:int
      :int
    when :float32,:float
      :float
    when :stack
      var_or_val[3]
    when :var_array
      resolve_var_type(var_or_val[4],nil)
    when :lvar_array
      resolve_var_type(var_or_val[4],nil)
    when :var
      resolved_gvar_type(var_or_val[1])
    when :vlstring
      :string8
    else
      debugger
      raise "unknown var type #{var_or_val.inspect}"
    end
  end

  def resolved_lvar_type(lvar_name, function_name)
    if self.functions[function_name].andand[:arguments].andand.key?(lvar_name)

      argument_index = self.functions[function_name][:arguments].keys.index(lvar_name)
      invoked_with = self.functions[function_name][:invokes].map do |invoke|
        [ invoke[:caller] , invoke[:arguments][argument_index] ]
      end
      resolved_types = invoked_with.map do |(caller,var_or_val)|
        resolve_var_type(var_or_val,caller)
      end
      if resolved_types.compact.uniq.size > 1
        raise "multiple resolved types for #{lvar_name}: #{resolved_types.inspect}"
      end
      # debugger
      # self.functions[function_name][:arguments][lvar_name] = resolved_types[0]
      return resolved_types[0]

    elsif self.functions[function_name].andand[:locals].andand.key?(lvar_name)
      resolved_types = self.functions[function_name][:locals][lvar_name].map do |var_or_val|
        resolve_var_type(var_or_val,function_name)
      end
      if resolved_types.compact.uniq.size > 1
        raise "multiple resolved types for #{lvar_name}: #{resolved_types.inspect}"
      end
      return resolved_types[0]
    else
      nil
    end
  end

  def resolved_ivar_type(name)
    if name == :@timer_a || name == :@timer_b
      return :int
    end
    if !self.functions[nil][:instances][ivar_name(name)]
      debugger
    end
    resolved_types = self.functions[nil][:instances][ivar_name(name)].map do |(caller,var_or_val)|
      resolve_var_type(var_or_val,nil)
    end
    # if name == :input_arg
    #   debugger
    # end
    if resolved_types.compact.uniq.size > 1
      raise "multiple resolved types for ivar #{name}: #{resolved_types.inspect}"
    end
    resolved_types[0]
  end

  def resolved_return_var_name(function_name,return_var_index)
    maybe_names = self.functions[function_name][:returns][return_var_index].map{|u| u[0] == :lvar ? u[1] : nil}.compact
    if maybe_names.uniq.size > 1
      raise "multiple return var names?"
    end
    maybe_names[0]
  end

  def gvar_name(name)
    name.to_s.gsub(/^\$/,'').to_sym
  end

  # $gvar
  def on_gvar_use(node)
    case node.type
    when :gvar, :gvasgn
      if generating?
        [:var,gvar_name(node[0]),resolved_gvar_type(node[0])]
      else
        [:var,gvar_name(node[0])]
      end
    else
      raise "unknown gvar #{node.inspect}"
    end
  end
  # $gvar = 1
  # def on_gvar_assign(node,rhs)
  #   on_gvar_use(node)
  # end
  def on_gvar_assign(node,rhs)
    lhs = on_gvar_use(node)

    if scanning?
      self.functions[nil][:globals][ lhs[1] ] ||= []
      if rhs
        self.functions[nil][:globals][ lhs[1] ] << rhs
      end
    end

    return lhs
  end

  def resolved_gvar_type(name)
    uses = self.functions[nil][:globals][gvar_name(name)]
    debugger if !uses
    raise "unknown gvar #{name}" if !uses
    resolved_types = uses.map do |var_or_val|
      resolve_var_type(var_or_val,nil)
    end
    if resolved_types.compact.uniq.size > 1
      raise "multiple resolved types for gvar #{name}: #{resolved_types.inspect}"
    end
    resolved_types[0]
  end

  def ivar_name(name)
    name.to_s.gsub(/^@/,'').to_sym
  end

  def ivar_lvar_id(name)
    if name =~ /timer_a/i
      return 32
    elsif name =~ /timer_b/i
      return 33
    end

    if name =~ /^_\d+$/
      return name.to_s.gsub("_","").to_i
    end

    @ivar_lvar_ids ||= {}
    @ivar_lvar_id_counter ||= -1
    if @ivar_lvar_ids[name]
      return @ivar_lvar_ids[name]
    else
      @ivar_lvar_id_counter += 1
      if @ivar_lvar_id_counter >= 32
        raise "ran out of lvar ids"
      end
      @ivar_lvar_ids[name] = @ivar_lvar_id_counter
      return @ivar_lvar_ids[name]
    end
  end

  # @ivar
  def on_ivar_use(node)
    name = ivar_name(node[0])
    case node.type
    when :ivar, :ivasgn
      if generating?
        ivar_id = ivar_lvar_id(name)
        # [:ivar,ivar_name(node[0]),resolved_ivar_type(node[0])]
        [:lvar,ivar_id,name,resolved_ivar_type(node[0])]
      else
        [:ivar,name]
      end
    else
      raise "unknown ivar #{node.inspect}"
    end
  end
  # @ivar = 1
  def on_ivar_assign(node,rhs)
    lhs = on_ivar_use(node)

    if scanning?
      if lhs[0] == :ivar && rhs
        if rhs[0].nil? && rhs[1].nil?
          debugger
        end
        self.functions[nil][:instances][ lhs[1] ] ||= []
        self.functions[nil][:instances][ lhs[1] ] << [ self.current_function , rhs ]
      end
    end

    lhs
  end

  def on_var_use(node)
    case node.type
    when :lvar, :lvasgn
      on_lvar_use(node)
    when :ivar, :ivasgn
      on_ivar_use(node)
    when :gvar, :gvasgn
      on_gvar_use(node)
    when :const
      on_const_use(node)
    when :int, :float
      on_immediate_use(node)
    when sexp?(node[0]) && node[0].type == :gvar && self.functions[nil][:global_arrays][gvar_name(node[0][0])] && :send
      on_global_array_use(node)
    when sexp?(node[0]) && node[0].type == :ivar && self.functions[nil][:instance_arrays][ivar_name(node[0][0])] && :send
      on_instance_array_use(node)
    when struct_var?(node[0]) && :send
      var = sexp(node[0].type,[:"#{node[0][0]}_#{node[1]}"])
      on_var_use(var)
    when node.match( :send , [1] => :block_pass )
      raise "handle block_pass"
    when node[0][0].match(/^\$_\d+$/) && :send # $_0[]
      on_global_array_use(node)
    else
      debugger
      raise "unknown var use #{node.inspect}"
    end
  end

  def on_var_assign(node,rhs)
    case node.type
    when :lvar, :lvasgn
      on_lvar_assign(node,rhs)
    when :ivar, :ivasgn
      on_ivar_assign(node,rhs)
    when :gvar, :gvasgn
      on_gvar_assign(node,rhs)
    else
      debugger
      raise "unknown var assign #{node.inspect}"
    end
  end

  # CONST
  def on_const_use(node)
    if value = self.constants[node[1]]
      return value
    else
      raise "unknown constant #{node[1]}"
    end
  end
  # CONST = 1
  def on_const_assign(*)
  end

  def on_immediate_use(node)
    case node.type
    when :int
      if node[0] >= -128 && node[0] <= 128-1
        [:int8,node[0]]
      elsif node[0] >= -32768 && node[0] <= 32768-1
        [:int16,node[0]]
      else
        [:int32,node[0]]
      end
    when :float
      [:float32,node[0]]
    when :str
      [:vlstring,node[0]]
    else
      raise "unknown immediate #{node.inspect}"
    end
  end

  def on_global_array_use(node)

    if node[0][0].match(/^\$_\d+$/)
      array = [:int,-1]
      array_var = node[0][0].to_s.gsub(/[\$_]/,"").to_i
    else
      array = self.functions[nil][:global_arrays][gvar_name(node[0][0])]
      array_var = gvar_name(node[0][0])
    end

    index_var,index_var_type,array_offset = array_index_var_type_offset(node[2])

    if !array_offset.nil?
      array_offset *= 4
      if array_var.is_a?(Numeric)
        array_var += array_offset
      else
        sign = array_offset > 0 ? :+ : :-
        array_var = :"#{array_var}#{sign}#{array_offset.abs}"
      end
    end

    if !array
      debugger
    end

    array_size = array[1]
    array_type = array_type_token(array[0])

    if generating? && index_var_type == :lvar
      # debugger
      index_var = ivar_lvar_id(index_var)
    end

    [:var_array,array_var,index_var,array_size,[array_type,index_var_type]]
  end

  def on_instance_array_use(node)
    array = self.functions[nil][:instance_arrays][ivar_name(node[0][0])]

    array_var = ivar_name(node[0][0])
    index_var,index_var_type,array_offset = array_index_var_type_offset(node[2])

    if generating?
      array_var = ivar_lvar_id(array_var)
    end

    if !array_offset.nil?
      sign = array_offset > 0 ? :+ : :-
      # array_offset *= 4
      if generating?
        array_var = array_var.send(sign,array_offset.abs)
      else
        array_var = :"#{array_var}#{sign}#{array_offset.abs}"
      end
    end

    array_size = array[1]
    array_type = array_type_token(array[0])

    if generating? && index_var_type == :lvar
      index_var = ivar_lvar_id(index_var)
    end

    [:lvar_array,array_var,index_var,array_size,[array_type,index_var_type]]
  end

  def array_type_token(type)
    type = {
      int: :int32,
      float: :float32,
    }[type]
    raise "unknown array_type_token #{type}" if !type
    return type
  end

  def array_index_var_type_offset(index_var)
    case index_var.type
    when :gvar
      [gvar_name(index_var[0]),:var,nil]
    when :ivar
      [ivar_name(index_var[0]),:lvar,nil]
    when :send
      case index_var[0].type
      when :gvar
        offset = index_var[2][0]
        offset *= -1 if index_var[1] == :-
        [gvar_name(index_var[0][0]),:var,offset]
      when :ivar
        offset = index_var[2][0]
        offset *= -1 if index_var[1] == :-
        [ivar_name(index_var[0][0]),:lvar,offset]
      else
        raise "unknown array_index_var_type_offset #{index_var.inspect}"
      end
    else
      debugger
      raise "unknown array_index_var_type_offset #{index_var.inspect}"
    end
  end

  # Script declare
  # 
  # script(name: "foo") do
  #   ...
  # end
  #
  def on_script_block(node)
    hash = eval_hash_node(node[0][2]) || {}
    self.stack_locations[:stack] = hash[:stack]         if hash[:stack]
    self.stack_locations[:sc]    = hash[:stack_counter] if hash[:stack_counter]
    self.stack_locations[:size]  = hash[:stack_size]    if hash[:stack_size]

    script_name = hash[:name] || "noname"

    begin
      self.scripts[script_name] = hash
      self.script_block_hash = hash
      body = []
      # body += transform_node( sexp(:lvasgn,[sexp(:lvar,[:"__#{self.current_function||"nil"}"]),sexp(:int,[-1111])]) )
      body += transform_node(node[2])
    ensure
      self.script_block_hash = nil
    end

    [
      [:labeldef,:"start_script_#{script_name}"],
      *function_prologue(nil),
      *body,
      [:labeldef,:"end_script_#{script_name}"],
    ]
  end


  def on_main_block(node)
    hash = eval_hash_node(node[0][2]) || {}
    hash[:loop] = true if hash[:loop].nil?
    hash[:wait] = 0 if hash[:wait].nil?

    body = []
    begin
      self.main_block_hash = hash
      if hash[:loop]
        loop_label = :"#{self.script_block_hash[:name]}_main_loop"
        body << [:labeldef,loop_label]
      end
      if hash[:wait]
        body += function_epilogue(nil)
        body << [:wait,[[:int32,hash[:wait]]]]
        body += function_prologue(nil)
      end
      body += transform_node(node[2])
      if hash[:loop]
        body << [:goto,[[self.label_type,loop_label]]]
      end
    ensure
      self.main_block_hash = nil
    end

    body
  end

  def on_functions_block(node)
    hash = eval_hash_node(node[0][2]) || {}

    begin
      self.in_functions_block = true
      body = transform_node(node[2])
    ensure
      self.in_functions_block = false
    end

    label_name = generate_label!(:end_functions)
    label_def = [
      [:labeldef,label_name]
    ]
    goto = [
      [:goto,[[:label,label_name]]]
    ]

    if hash[:bare]
      goto = []
      label_def = []
    end

    [
      *goto,
      *body,
      *label_def
    ]
  end

  # Function declare
  # 
  # function(:name) do |arg1|
  #   ...
  # end
  # 
  # s(:block,
  #   s(:send, nil, :function,
  #     s(:sym, :my_stack_function)),
  #   s(:args,
  #     s(:arg, :arg1),
  #     s(:arg, :arg2)),
  #   s(:begin,
  #     [body]
  def on_function_block(node)
    self.current_function = self.function_block_name(node)

    if scanning?
      self.functions[self.current_function] ||= {
        returns:       {},
        arguments:     {},
        locals:        {},
        local_structs: {},
        invokes:       []
      }
      node[1].each do |arg|
        self.functions[self.current_function][:arguments][ arg[0] ] ||= []
      end
    end

    body = []
    body += transform_node(node[2])

    prologue = []
    epilogue = []
    if generating?
      prologue += function_prologue(self.current_function)
      if !self.last_child_was_return
        epilogue += function_epilogue(self.current_function)
        epilogue += [[:return]]
      end
    end

    goto = [
      [:goto,[[self.label_type,:"function_end_#{self.current_function}"]]]
    ]

    if self.in_functions_block
      goto = []
    end


    [
      *goto,
      [:labeldef,:"function_#{self.current_function}"],
      *prologue,
      *body,
      *epilogue,
      [:labeldef,:"function_end_#{self.current_function}"],
    ]
    
  ensure
    self.current_function = nil
  end

  def function_block_name(node)
    case
    when node.match(:block)
      node[0][2][0]
    when node.match(:def)
      node[0]
    else
      raise "unknown function_block_name #{node.inspect}"
    end
  end

  # def resolve_lvar_type(lvar_name,function_name)
    
  # end

  def function_prologue(function_name)
    prologue = []
    self.functions[function_name][:locals].each_pair do |lvar_name,uses|
      lvar_type = resolved_lvar_type(lvar_name,function_name)
      # prologue << [ :stack_push , lvar_name ]
    end
    stack_adjust = function_stack_size(function_name)
    if function_name.nil?
      prologue << [ :stack_zero ]
    end
    if stack_adjust != 0
      prologue << [ :stack_adjust , stack_adjust ]
    end
    prologue
  end

  def function_epilogue(function_name)
    epilogue = []
    stack_adjust = function_stack_size(function_name)
    if stack_adjust != 0
      epilogue << [ :stack_adjust , stack_adjust * -1 ]
    end
    epilogue
  end

  def function_stack_size(function_name)
    stack_size = 0

    stack_size += self.functions[function_name][:returns].size   if self.functions[function_name][:returns]

    # stack_size += self.functions[function_name][:arguments].size if self.functions[function_name][:arguments]
    if self.functions[function_name][:arguments]
      self.functions[function_name][:arguments].each do |arg|
        if !safe_lvar_return_var(arg[0],function_name)
          stack_size += 1
        end
      end
    end

    # stack_size += self.functions[function_name][:locals].size    if self.functions[function_name][:locals]

    self.functions[function_name][:locals].each do |local|
      if !safe_lvar_return_var(local[0],function_name)
        stack_size += 1
      end
    end

    stack_size
  end

  def assignment_lhs(node,rhs)
    case
    when node.match([:lvasgn,:lvar])
      on_lvar_assign(node,rhs)
    when node.match([:ivasgn,:ivar])
      on_ivar_assign(node,rhs)
    when node.match([:gvasgn,:gvar])
      on_gvar_assign(node,rhs)
    when node.match( :op_asgn , [0] => [:lvasgn] )
      on_lvar_assign(node[0],rhs)
    when node.match( :op_asgn , [0] => [:gvasgn] )
      on_gvar_assign(node[0],rhs)
    when node.match( :send , [0] => [:lvar] )
      on_lvar_assign(node[0],rhs)
    when node.match( :op_asgn , [0] => [:ivasgn] )
      on_ivar_assign(node[0],rhs)
    when node.match( :send , [0] => [:ivar] )
      on_ivar_assign(node[0],rhs)
    when node.match( :send, [0] => [:gvar,:ivar], [1] => :[]=)
      on_global_array_use(node)
    when node.match( :send, [0] => [:lvar,:ivar,:gvar] ) && node[1].match(/=$/)
      var = sexp(node[0].type,["#{node[0][0]}_#{node[1]}".gsub(/=/,'').to_sym])
      assignment_lhs(var,nil)
    else
      debugger
      raise "unknown assignment_lhs #{node.inspect}"
    end
  end

  def assignment_rhs(node)
    case
    when node.match([:lvasgn,:ivasgn,:gvasgn], [1] => [:int,:float,:str])
      on_immediate_use(node[1])
    when node.match([:lvasgn,:ivasgn,:gvasgn], [1] => [:lvar,:gvar,:ivar])
      on_var_use(node[1])
    when node.match( :op_asgn , [2] => :lvar )
      on_var_use(node[2])
    when node.match( :op_asgn, [0] => [:lvasgn,:ivasgn,:gvasgn], [1] => [:+,:-,:*,:/], [2] => [:lvar,:ivar,:gvar,:const])
      on_var_use(node[2])
    when node.match( :op_asgn, [0] => [:lvasgn,:ivasgn,:gvasgn], [1] => [:+,:-,:*,:/], [2] => [:int,:float])
      on_immediate_use(node[2])
    when node.match( :send, [1] => [:+,:-,:*,:/], [2] => [:int,:float])
      on_immediate_use(node[2])
    when node.match([:lvar,:gvar,:ivar])
      on_var_use(node)
    when node.match([:float,:int])
      on_immediate_use(node)
    when node.match( :send, [1] => :[]= )
      assignment_rhs(node[3])
    # when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1,0] => [:lvar,:ivar,:gvar,:int,:float,:string] , [1,1] => :[] , [1,2] => [:lvar,:ivar,:gvar,:int,:float,:string] )
    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1,0] => [:gvar] , [1,1] => :[] , [1,2] => [:lvar,:ivar,:gvar,:int,:float,:string] )
      on_global_array_use(node[1])
    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1,0] => [:ivar] , [1,1] => :[] , [1,2] => [:lvar,:ivar,:gvar,:int,:float,:string] )
      on_instance_array_use(node[1])
    # when node.match( :send, [1] => :[] )
    #   assignment_rhs(node[3])
    when node.match( :send, [0] => [:lvar,:ivar,:gvar] ) && struct_var?(node[0])
      if node[2]
        assignment_rhs(node[2])
      else
        var = sexp(node[0].type,["#{node[0][0]}_#{node[1]}".gsub(/=/,'').to_sym])
        assignment_rhs(var)
      end
    when node.match( [:lvasgn,:ivasgn,:gvasgn], [1] => [:const])
      on_const_use(node[1])
    else
      debugger
      raise "unknown assignment_rhs #{node.inspect}"
    end
  end

  def compare_lhs(node)
    case
    when node.match( :send , [1] => [:>,:<,:>=,:<=,:==,:!=] )
      transform_node(node[0])
    else
      raise "unknown compare lhs #{node.inspect}"
    end
  end

  def compare_rhs(node)
    case
    when node.match( :send , [1] => [:>,:<,:>=,:<=,:==,:!=] )
      # debugger
      transform_node(node[2])
      # assignment_rhs(node[2])
    else
      raise "unknown compare lhs #{node.inspect}"
    end
  end

  def compare_operator(node)
    case
    when node.match( :send , [1] => [:>,:<,:>=,:<=,:==,:!=] )
      node[1]
    else
      raise "unknown compare lhs #{node.inspect}"
    end
  end

  def generate_label!(prefix = nil)
    @generate_label_counter ||= 0
    @generate_label_counter += 1
    [self.label_prefix,self.current_function || "label",prefix,@generate_label_counter].join("_").to_sym
  end

  def on_loop(node)
    loop_start = generate_label!(:loop_start)
    loop_end = generate_label!(:loop_end)

    begin
      self.loop_labels << [loop_start,loop_end]
      body = transform_node(node[2])
    ensure
      self.loop_labels -= [ [loop_start,loop_end] ]
    end

    [
      [:labeldef,loop_start],
      *body,
      [:goto,[[self.label_type,loop_start]]],
      [:labeldef,loop_end]
    ]
  end

  def on_if(node)
    andor_value, conditions = transform_conditions(node[0])
    body = transform_node(node[1])

    false_label = generate_label!(:if)

    # debugger

    [
      *andor_instruction(andor_value),
      *conditions,
      [:goto_if_false,[[self.label_type,false_label]]],
      *body,
      [:labeldef,false_label]
    ]
  end

  def on_if_else(node)
    andor_value, conditions = transform_conditions(node[0])

    true_body = transform_node(node[1])
    false_body = transform_node(node[2])

    end_label = generate_label!(:if)
    false_label = generate_label!(:if)
    [
      *andor_instruction(andor_value),
      *conditions,
      [:goto_if_false,[[self.label_type,false_label]]],
      *true_body,
      [:goto,[[self.label_type,end_label]]],
      [:labeldef,false_label],
      *false_body,
      [:labeldef,end_label]
    ]
  end

  def andor_instruction(andor_value)
    if andor_value > 0
      [ [:andor,[[:int8,andor_value]]] ]
    else
      []
    end
  end

  def transform_conditions(node,parent_logical_operator = nil)
    case node.type

    # if with single condition
    when :send
      return [0, transform_node(node)]
    # if with multiple conditions
    when :and, :or
      if parent_logical_operator && node.type != parent_logical_operator
        raise "cannot mix AND/OR in one IF statement"
      end

      conditions = node.map do |condition_node|
        case condition_node.type
        when :and, :or
          transform_conditions(condition_node,node.type)
        when :send
          transform_node(condition_node)[0]
        else
          raise "unknown condition node #{condition_node.inspect}"
        end
      end

      if conditions[0][0].is_a?(Array)
        conditions = [ *conditions[0] , *conditions[1..-1] ]
      end


      if parent_logical_operator
        return conditions
      elsif conditions.size > 8
        raise "cannot have more than 8 conditions in one IF statement"
      else
        andor_id = node.type == :and ? 0 : 20
        andor_id += (conditions.size - 1)
        return [andor_id,conditions]
      end

    else
      raise "unknown andor value #{node.inspect}"
    end
  end

  def on_break(node)
    current_loop = self.loop_labels.last

    [
      [:goto,[[self.label_type,current_loop.last]]]
    ]
  end

  # Assignment
  def on_assign(node)
    rhs = self.assignment_rhs(node)
    lhs = self.assignment_lhs(node,rhs)

    [
      [:assign,[lhs,rhs]]
    ]
  end

  def on_multi_assign(node)
    if node[0].size != node[1].size
      raise "mismatched number of multi assigns (#{node[0].size} vs. #{node[1].size})"
    end

    instructions = []
    node[0].each_with_index do |left,index|
      right = node[1][index]
      rhs = self.assignment_rhs(right)
      lhs = self.assignment_lhs(left,rhs)
      instructions << [:assign,[lhs,rhs]]
    end
    instructions
  end

  def on_dereference_assign(node)
    lhs = self.assignment_lhs(node,[:int32,nil])
    deref_value = node[1][2]
    if self.functions[deref_value[1]]
      [
        [:assign,[lhs,[self.label_type,:"function_#{deref_value[1]}"]]]
      ]
    else
      raise "dunno how to deref #{node.inspect}"
    end
  end

  # Operator Assign
  def on_operator_assign(node)
    rhs = assignment_rhs(node)
    lhs = assignment_lhs(node,nil)
    operator = assignment_operator(node)

    [
      [:assign_operator, [lhs, operator, rhs]]
    ]
  end

  def assignment_operator(node)
    if node.match( [:op_asgn,:send] , [1] => [:+,:-,:*,:/] )
      node[1]
    else
      raise "unknown assignment operator #{node.inspect}"
    end
  end

  # Function call with return values
  #
  # return_val = my_stack_function(@local_var,temp_var)
  #
  # s(:lvasgn, :return_val,
  #   s(:send, nil, :my_stack_function,
  #     s(:ivar, :@local_var),
  #     s(:lvar, :temp_var)))
  def on_function_call(node)
    function_name = function_call_name(node)

    if scanning?
      self.functions[function_name][:invokes] << {
        caller: self.current_function,
        arguments: function_call_argument_assignments(node,function_name).map{ |inst| inst[1][1] }
      }
    end

    [
      *function_call_argument_assignments(node,function_name),
      [:gosub, [[self.label_type,:"function_#{function_name}"]]],
      *function_call_return_assignments(node,function_name),
    ]
  end

  def function_call_name(node)
    if node.match(:send)
      node[1]
    elsif node.match([:lvasgn,:ivasgn,:gvasgn])
      node[1][1]
    elsif node.match(:masgn)
      node[1][1]
    else
      debugger
      raise "unknown function call name #{node.inspect}"
    end
  end

  def function_call_argument_assignments(node,function_name)
    arguments = function_call_arguments(node)

    argument_assigns = []
    argument_index = 0
    arguments.each do |argument|
      if struct_class = struct_var?(argument)
        vars = expand_struct_vars(argument)
        vars.each_with_index do |rhs,idx|
          rhs_type = self.struct_definitions[struct_class].values[idx]
          stack_index = self.safe_lvar_return_var(argument[0],function_name) || self.functions[function_name][:returns].size + argument_index
          lhs = [:stack,stack_index,:"argument_#{argument_index}",rhs_type]
          argument_assigns << [:assign, [lhs,rhs]]
          argument_index += 1
        end
      else
        stack_index = self.safe_lvar_return_var(argument[0],function_name) || self.functions[function_name][:returns].size + argument_index
        rhs = transform_node(argument)
        rhs_type = resolve_var_type(rhs,self.current_function)
        lhs = [:stack,stack_index,:"argument_#{argument_index}",rhs_type]
        argument_assigns << [:assign, [ lhs , rhs ]]
        argument_index += 1
      end
    end

    if argument_assigns.size != self.functions[function_name][:arguments].size
      raise "wrong number of arguments for #{function_name} (expected #{self.functions[function_name][:arguments].size}, invoked with #{arguments.size})"
    end
    
    [
      *argument_assigns,
      # [:stack_adjust, (self.functions[function_name][:returns].size + self.functions[function_name][:arguments].size)]
    ]
  end

  def function_call_return_assignments(node,function_name)
    return_vars = function_call_return_vars(node,function_name)
    
    return_var_types = resolve_function_return_types(function_name)
    return_var_assigns = []
    return_index = 0
    return_vars.each_with_index do |return_var|
      if struct_class = struct_var?(return_var)
        self.struct_definitions[struct_class].each_pair do |def_name,def_type|
          base = return_var.dup
          case base[0]
          when :var
            base[1] = :"#{base[1]}_#{def_name}"
          end
          rhs = [:stack,return_index,:"return_#{return_index}",return_var_types[return_index]]
          return_var_assigns << [:assign,[base,rhs]]
          return_index += 1
        end
      else
        rhs = [:stack,return_index,:"return_#{return_index}",return_var_types[return_index]]
        return_var_assigns << [:assign,[return_var,rhs]]
        return_index += 1
      end
    end

    if return_var_assigns.size != self.functions[function_name][:returns].size
      raise "wrong number of return args (function returns #{self.functions[function_name][:returns].size}, invoked with #{return_var_assigns.size})"
    end

    [
      # [:stack_adjust, (self.functions[function_name][:returns].size + self.functions[function_name][:arguments].size) * -1],
      *return_var_assigns,
    ]
  end

  def function_call_arguments(node)
    case
    when node.match( [:masgn,:lvasgn,:ivasgn,:gvasgn] , [1] => :send )
      node[1][2..-1]
    when node.match( :send )
      node[2..-1]
    else
      raise "unknown function call arguments #{node.inspect}"
    end
  end

  def function_call_return_vars(node,function_name)
    return_types = resolve_function_return_types(function_name)

    case
    # single var assignment
    when node.match( [:lvasgn,:ivasgn,:gvasgn] )
      [
        on_var_assign(node,return_types[0])
      ]
    when node.match( :masgn , [0] => :mlhs , [1] => :send )
      assigns = []
      node[0].each_with_index do |var,idx|
        assigns << on_var_assign(var,return_types[idx])
      end
      assigns
    when node.match( :send )
      []
    else
      debugger
      raise "unknown opcode return vars #{node.inspect}"
    end
  end


  # Opcode call with return values
  # 
  # func_tmp2 = get_game_timer()
  #
  # s(:lvasgn, :func_tmp2,
  #   s(:send, nil, :get_game_timer))
  #
  # when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send ) && !!(self.opcode_names[ node[1][1] ])
  def on_opcode_call(node,negated = false)
    opcode_name = opcode_call_name(node,negated)
    return_types = opcode_return_types(opcode_name)
    return_vars = opcode_return_vars(node,return_types)

    arguments = opcode_call_arguments(node)
    arguments += return_vars
    arguments += [ [:end_var_args] ] if need_var_args?(opcode_name)

    # if opcode_name.to_sym == :get_char_coordinates && arguments[1] && arguments[1].is_a?(Array)
    #   debugger
    # end

    if arguments.size == 0
      [ [opcode_name] ]
    else
      [ [opcode_name,arguments] ]
    end
  end

  def opcode_call_name(node,negated = false)
    name = case
    when node.match(:send, [1] => :[]=, [3] => :send)
      node[3][1]
    when node.match(:send)
      node[1]
    when node.match([:masgn,:lvasgn,:ivasgn,:gvasgn],[1] => :send)
      node[1][1]
    else
      raise "unknown opcode name #{node.inspect}"
    end
    name = :"not_#{name}" if negated
    name
  end

  def opcode_return_vars(node,return_types)
    out = []

    return_vars = case
    when node.match(:send, [0] => :gvar, [1] => :[]=, [3] => :send)
      on_global_array_use(node)
    when node.match(:send, [0] => :ivar, [1] => :[]=, [3] => :send)
      on_instance_array_use(node)
    # no return vars
    when node.match(:send)
      []
    # single var assignment
    when node.match( [:lvasgn,:ivasgn,:gvasgn] )
      if struct_var?(node)
        expand_struct_vars(node)
      else
        [ assignment_lhs(node,[return_types[0],nil]) ]
      end
    # multiple var assignment
    when node.match( :masgn )
      vars = []
      node[0].each_with_index do |var,index|
        vars << assignment_lhs(var,[return_types[index],nil])
      end
      vars
    else
      debugger
      raise "unknown opcode return vars #{node.inspect} #{return_types.inspect}"
    end

    return_vars
  end

  def opcode_call_arguments(node)
    arguments = case
    when node.match(:send, [1] => :[]=, [3] => :send)
      node[3][2..-1]
    when node.match(:send)
      node[2..-1]
    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send )
      node[1][2..-1]
    when node.match( :masgn , [1] => :send )
      node[1][2..-1]
    else
      raise "unknown opcode call arguments #{node.inspect}"
    end

    out = []

    arguments.each do |argument|
      if argument.immediate_value?
        out += [ transform_node(argument) ]
      elsif struct_var?(argument)
        out += expand_struct_vars(argument)
      else
        out += [ on_var_use(argument) ]
      end
    end

    out
  end

  def need_var_args?(opcode_name)
    [:start_new_script,:start_new_streamed_script].include?(opcode_name)
  end

  def struct_var?(node)
    if sexp?(node)
      if node.match([:gvasgn,:gvar]) && self.functions[nil][:global_structs][gvar_name(node[0])]
        self.functions[nil][:global_structs][gvar_name(node[0])]
      elsif node.match([:ivasgn,:ivar]) && self.functions[nil][:instance_structs][ivar_name(node[0])]
        self.functions[nil][:instance_structs][ivar_name(node[0])]
      elsif node.match([:lvasgn,:lvar]) && self.functions[self.current_function][:local_structs][node[0]]
        self.functions[self.current_function][:local_structs][node[0]]
      else
        false
      end
    else
      if node.nil?
        false
      elsif node[0] == :var && self.functions[nil][:global_structs][node[1]]
        self.functions[nil][:global_structs][node[1]]
      elsif node[0] == :lvar && self.functions[nil][:instance_structs][node[1]]
        self.functions[nil][:instance_structs][node[1]]
      elsif node[0] == :var_array && self.functions[self.current_function][:local_structs][node[1]]
        self.functions[self.current_function][:local_structs][node[1]]
      else
        false
      end
    end
  end

  def expand_struct_vars(node)

    struct_class = case node.type
    when :gvar, :gvasgn, :var
      self.functions[nil][:global_structs][gvar_name(node[0])]
    when :ivar, :ivasgn
      self.functions[nil][:instance_structs][ivar_name(node[0])]
    when :lvar, :lvasgn
      self.functions[self.current_function][node[0]]
    end

    definition = self.struct_definitions[struct_class]
    definition.map do |def_name,def_type|
      base = sexp(node.type,[:"#{node[0]}_#{def_name}"])
      var = on_var_use(base)
      # case var[0]
      # when :var
      #   var[2] = def_type
      # end
      var
    end

  end

  def on_array_var_declare(node)
    array_size = array_declare_size(node)
    array_type = array_class_type(node)

    instructions = []
    instructions << [:EmitNodes,false] if !self.in_declare_block

    if !array_size
      debugger
    end

    case node.type
    when :gvasgn
      name = gvar_name(node[0])
      opcode_name = :"set_var_#{array_type}"
      default_value = array_type == :float ? [:float32,0.0] : [:int8,0]
      self.functions[nil][:global_arrays][name] = [array_type,array_size]
      array_size.times do |index|
        var_name = "#{name}"
        var_name << "_#{index}" if index > 0
        instructions << [opcode_name,[ [:var,:"#{var_name}"] , default_value ]]
      end
    when :ivasgn
      self.functions[nil][:instance_arrays][ivar_name(node[0])] = [array_type,array_size]
    when :lvasgn
      raise "cannot use local vars as arrays"
    end

    instructions << [:EmitNodes,true] if !self.in_declare_block
    return instructions
  end

  def array_declare_size(node)
    on_var_use(node[1][2])[1]
  end

  def array_class_type(node)
    types = {
      IntegerArray: :int,
      FloatArray: :float,
    }
    type = if types.keys.include?(node[1][1])
      node[1][1]
    else
      node[1][0][1]
    end

    type = types[type]
    return type if type
    raise "unknown array_class_type #{type.inspect}"
  end

  def on_struct_var_declare(node)
    var_name = node[0]

    struct_class = node[1][0][1]
    arguments = node[1][2..-1]
    definition = self.struct_definitions[struct_class]

    case node.type
    when :gvasgn
      self.functions[nil][:global_structs][gvar_name(var_name)] = struct_class
    when :ivasgn
      self.functions[nil][:instance_structs][ivar_name(var_name)] = struct_class
    when :lvasgn
      self.functions[self.current_function][var_name] = struct_class
    else
      raise "wtf"
    end

    if arguments.size != definition.size
      raise "expected #{definition.size} elements for #{struct_class}, got #{arguments.size}"
    end

    instructions = []

    arguments.each_with_index do |arg,idx|
      def_name = definition.keys[idx]
      def_type = definition.values[idx]
      rhs = assignment_rhs(arg)
      base = sexp(node.type,[:"#{node[0]}_#{def_name}"])
      lhs = assignment_lhs(base,rhs)
      instructions << [:assign,[lhs,rhs]]
    end

    return instructions
  end

  def on_constant_declare(node)
    self.constants[ node[1] ] = transform_node(node[2])
    return []
  end

  def on_type_cast(node)
    lhs_type,rhs_type = cast_types(node[1][1])
    rhs = assignment_rhs(node[1][0])
    lhs = assignment_lhs(node,[lhs_type,nil])
    [
      [:assign_cast,[lhs,node[1][1],rhs]]
    ]
  end

  def cast_types(operator)
    case operator
    when :to_f
      [:float,:int]
    when :to_i
      [:int,:float]
    else
      raise "unknown cast type #{node[1][1]}"
    end
  end

  def on_compare(node)
    rhs = self.compare_rhs(node)
    lhs = self.compare_lhs(node)
    operator = self.compare_operator(node)

    [
      [:compare, [lhs,operator,rhs] ]
    ]
  end

  # Return
  def on_return(node)

    if scanning?
      if !self.current_function
        raise "returning outside a function"
      end
      node.each_with_index do |return_var,return_index|
        self.functions[self.current_function][:returns][return_index] ||= []
        self.functions[self.current_function][:returns][return_index] << transform_node(return_var)
      end
    end

    return_var_assignments = return_assignments(node)

    epilogue = []
    if generating?
      epilogue = function_epilogue(self.current_function)
    end

    [
      *return_var_assignments,
      *epilogue,
      [:return]
    ]
  end

  def return_assignments(node)
    assignments = []
    node.each_with_index do |return_value,return_index|
      rhs = transform_node(return_value)
      lhs = [:stack,resolved_lvar_stack_offset(return_index),:"return_#{return_index}",nil]

      if generating? && rhs[0] == :stack
        lhs[3] = rhs[3]
      end
      if generating? && rhs[0][0] == :stack
        lhs[3] = rhs[0][3]
      end

      if generating? && [lhs[0],rhs[0]] == [:stack,:stack] && lhs[1] == rhs[1]
        # skip, it's assigning to the same var
      else
        assignments << [:assign,[ lhs, rhs ]]
      end
    end
    assignments
  end

  def on_declare_block(node)
    raise "can't nest declare blocks" if self.in_declare_block
    self.in_declare_block = true
    [
      [:EmitNodes, false],
      *transform_node(node[2]),
      [:EmitNodes, true]
    ]
  ensure
    self.in_declare_block = false
  end

  def on_declare_call(node)
    # make empty [:int,nil] use for declared type
    on_var_assign(node[2],[node[1],nil])
    return []
  end

  def scanning?
    self.state == :scanning
  end
  def generating?
    self.state == :generating
  end

  def compilable_math_expression?(node, level = 0)
    if node.match( [:lvasgn,:ivasgn,:gvasgn] )
      return compilable_math_expression?( node[1] , level + 1 )
    elsif node.match( :send , [0] => [:lvar,:ivar,:gvar,:begin] , [1] => [:+,:-,:*,:/] , [2] => [:lvar,:ivar,:gvar,:int,:float,:begin] )
      return true
    elsif node.match( :begin )
      return compilable_math_expression?( node[0] , level + 1 )
    else
      return false
    end
  end

  def tac_id(rhs = nil)
    if !@tac_id
      reset_tac_id!
    end
    @tac_id += 1
    # [:tac,@tac_id]
    on_lvar_assign( sexp(:lvar,[:"_tac_#{@tac_id}"]) , rhs )
  end

  def reset_tac_id!
    @tac_id = 0
    @tac_instructions = []
    @tac_nodes_to_ids = {}
    @tac_type = nil
  end

  def on_math_expression(node,level = 0)
    if level == 0
      reset_tac_id!
    end

    nnn = if node.match( [:lvasgn,:ivasgn,:gvasgn] )
      rhc = on_math_expression( node[1] , level + 1 )
      rhc_tac_id = @tac_nodes_to_ids[node[1]]
      lhs = assignment_lhs(node,rhc_tac_id)
      [
        *rhc,
        [:assign, [lhs, rhc_tac_id]]
      ]
    # elsif node.match( :send , [0] => :begin , [0,0] => :send )
    #   on_math_expression(node[0])
    elsif node.match( :send , [0] => [:lvar,:ivar,:gvar] , [1] => [:+,:-,:*,:/] , [2] => [:lvar,:ivar,:gvar,:int,:float] )
      # simple expression only
      rhs = assignment_rhs(node)
      lhs = assignment_lhs(node,nil)
      operator = assignment_operator(node)
      var = self.tac_id(rhs)
      @tac_nodes_to_ids[node] = var
      [
        [:assign, [var, lhs]],
        [:assign_operator, [var, operator, rhs]]
      ]
    elsif node.match( :send , [0] => [:lvar,:ivar,:gvar,:begin] , [1] => [:+,:-,:*,:/] , [2] => [:begin,:lvar,:ivar,:gvar,:int,:float] )

      lhs,rhs = nil,nil
      operator = assignment_operator(node)

      if node[2].match([:send,:begin])
        rhc = on_math_expression( node[2] , level + 1 )
      else
        rhs = assignment_rhs( node )
      end

      if node[0].match([:send,:begin])
        lhc = on_math_expression( node[0] , level + 1 )
      else
        lhs = assignment_lhs(node,nil)
      end

      case
      when lhc && rhs
        lhc_tac_id = @tac_nodes_to_ids[node[0]]
        rhc_tac_id = self.tac_id
        @tac_nodes_to_ids[node] = rhc_tac_id
        [
          *lhc,
          [:assign, [rhc_tac_id, lhc_tac_id]],
          [:assign_operator, [rhc_tac_id, operator, rhs]],
        ]
      when rhc && lhs
        lhc_tac_id = self.tac_id
        rhc_tac_id = @tac_nodes_to_ids[node[2]]
        @tac_nodes_to_ids[node] = lhc_tac_id
        [
          *rhc,
          [:assign, [lhc_tac_id, lhs]],
          [:assign_operator, [lhc_tac_id, operator, rhc_tac_id]],
        ]
      when lhc && rhc
        lhc_tac_id = @tac_nodes_to_ids[node[0]]
        rhc_tac_id = @tac_nodes_to_ids[node[2]]
        @tac_nodes_to_ids[node] = lhc_tac_id
        [
          *lhc,
          *rhc,
          [:assign_operator, [lhc_tac_id, operator, rhc_tac_id]]
        ]
      else

        debugger
        "foo"
        # node

      end
    elsif node.match( :begin )
      child = on_math_expression( node[0] , level + 1 )

      # copy single-child IDs up
      # debugger
      if @tac_nodes_to_ids[node[0]] && node.size == 1
        @tac_nodes_to_ids[node] = @tac_nodes_to_ids[node[0]]
      end

      child
    else
      debugger
      raise "???"
    end

    # debugger
    # nnn.each do |instructions|
    #   instructions[1].each do |arg|
    #     if arg[0] == :tac
    #       arg[2] = @tac_type
    #     end
    #   end
    # end
    nnn

  end

  def on_debugger(node)
    [
      [:gosub,[self.constants[:DEBUGGER_ADDR]]]
    ]
  end

  def on_log(node)
    logger_name = node[1]
    instructions = []

    case logger_name
    when :log_int, :log_hex
      id = {log_int: -1, log_hex: -3}[logger_name]
      var = on_var_use(node[2])
      instructions += logger_call(:function_debug_logger,[:int32,id])
      instructions += logger_call(:function_debug_logger,var)
    when :log_float
      var = on_var_use(node[2])
      instructions += logger_call(:function_debug_logger,[:int32,-2])
      instructions += logger_call(:function_debug_logger,var)
    else
      if node[2].type == :str
        str = node[2][0] + "\0"
        groups = str.chars.in_groups_of(4,"\0")
        ints = groups.map do |group|
          group.join.unpack("l<")[0]
        end
        ints.each do |int|
          instructions += logger_call(:function_debug_logger,[:int32,int])
        end
      else
        var = on_var_use(node[2])
        instructions += logger_call(:function_debug_logger,var)
      end
    end
    instructions
  end

  def logger_call(function_name,argument)
    [
      [:assign,[ [:var,:_debug_logger_argument], argument ]],
      [:gosub,[ [:label,:"#{function_name}"] ]]
    ]
  end


  def eval_hash_node(node)
    return {} if node.nil?
    hash = node.location.expression.source
    hash = "{#{hash}}" if hash[0] != "{"
    eval(hash)
  end

  def transform_to_v1_tokens(tokens)
    tokens.map do |line|
      line[1] = transform_args_to_v1_tokens(line[1]) if line[1].is_a?(Array)
      case line[0]
      when :stack_zero
        [:set_var_int,[ [:var,self.stack_locations[:sc]] , [:int8,0] ]]
      when :stack_adjust
        [:add_val_to_int_var,[ [:var,self.stack_locations[:sc]] , [:int8,line[1]] ]]
      when :assign
        lhs_type = transform_v1_assign_type(line[1][0])
        lhs_scope = transform_v1_assign_scope(line[1][0])

        rhs_type = transform_v1_assign_type(line[1][1])
        rhs_scope = transform_v1_assign_scope(line[1][1])

        if rhs_type != lhs_type
          logger.warn "Types do not match!"
          lhs_type = rhs_type
        end

        opcode_name = "set_#{lhs_scope}_#{lhs_type}"
        
        if lhs_scope == :var && rhs_type == :string8
          opcode_name = "set_var_text_label"
        elsif lhs_scope == :lvar && rhs_type == :string8
          opcode_name = "set_lvar_text_label"
        elsif rhs_scope
          opcode_name << "_to_#{rhs_scope}_#{rhs_type}"
        end

        if opcode_name == "set_var_string8"
          debugger
        end

        [
          :"#{opcode_name}",
          line[1]
        ]
      when :assign_operator
        lhs_type = transform_v1_assign_type(line[1][0])
        lhs_scope = transform_v1_assign_scope(line[1][0])

        rhs_type = transform_v1_assign_type(line[1][2])
        rhs_scope = transform_v1_assign_scope(line[1][2])

        opcode_parts = transform_v1_assign_operator_words(line[1][1])

        opcode_name = "#{opcode_parts[0]}_"

        if line[1][1] == :* || line[1][1] == :/
          # debugger
          opcode_name << "#{lhs_type}_#{lhs_scope}"
          opcode_name << "_#{opcode_parts[1]}_"
          opcode_name << (rhs_scope ? "#{rhs_type}_#{rhs_scope}" : "val")
        else
          opcode_name << (rhs_scope ? "#{rhs_type}_#{rhs_scope}" : "val")
          opcode_name << "_#{opcode_parts[1]}_"
          opcode_name << "#{lhs_type}_#{lhs_scope}"
        end

        if opcode_name == "set_var_string8"
          debugger
        end

        [
          :"#{opcode_name}",
          [ line[1][0] , line[1][2] ]
        ]
      when :assign_cast
        lhs_type = transform_v1_assign_type(line[1][0])
        lhs_scope = transform_v1_assign_scope(line[1][0])

        rhs_type = transform_v1_assign_type(line[1][2])
        rhs_scope = transform_v1_assign_scope(line[1][2])

        lhs_type,rhs_type = cast_types(line[1][1])

        opcode_name = "cset_#{lhs_scope}_#{lhs_type}_to_#{rhs_scope}_#{rhs_type}"

        [
          :"#{opcode_name}",
          [ line[1][0] , line[1][2] ]
        ]

      when :compare
        lhs_type = transform_v1_assign_type(line[1][0])
        lhs_scope = transform_v1_assign_scope(line[1][0])

        rhs_type = transform_v1_assign_type(line[1][2])
        rhs_scope = transform_v1_assign_scope(line[1][2])

        opcode_parts = transform_v1_compare_operator_words(line[1][1])

        opcode_name = "#{opcode_parts[0]}is_"
        
        if lhs_scope
          opcode_name << "#{lhs_type}_#{lhs_scope}_"
        else
          opcode_name << "number_"
        end

        opcode_name << opcode_parts[1]

        if rhs_scope
          opcode_name << "_#{rhs_type}_#{rhs_scope}"
        else
          opcode_name << "_number"
        end

        [
          :"#{opcode_name}",
          [line[1][0],line[1][2]]
        ]
      else
        line
      end

    end
  end

  def transform_args_to_v1_tokens(args)
    args.map do |arg|
      case arg[0]
      when :stack
        type = case arg[3]
        when :float32, :float
          :float32
        when :int32, :int
          :int32
        else
          :int32
        end

        [
          :var_array,
          :"#{self.stack_locations[:stack]}#{arg[1]>0 ? :+ : :-}#{arg[1].abs*4}",
          self.stack_locations[:sc],
          self.stack_locations[:size],
          [type,:var]
        ]
      when :var
        if value = dma_var(arg[1])
          [
            :dmavar,
            value,
            arg[2]
          ]
        else
          arg
        end
      when :lvar
        if value = dma_var(arg[2])
          [
            :lvar,
            value,
            value,
            arg[3],
          ]
        else
          arg
        end
      else
        arg
      end
    end
  end

  def transform_v1_assign_type(tokens)
    case tokens[0]
    when :float,:float32
      :float
    when :int,:int8,:int16,:int32
      :int
    when :var_array, :lvar_array
      case tokens[4][0]
      when :float32, :float
        :float
      when :int32, :int
        :int
      when nil
        nil
      else
        debugger
        raise "???"
      end
    when :stack
      case tokens[3]
      when :float32, :float
        :float
      when :int32, :int
        :int
      when nil
        nil
      else
        debugger
        raise "????"
      end
    when :lvar
      tokens[3]
    when :var, :dmavar
      tokens[2]
    when :vlstring
      :string8
    when :label, :mission_label
      :int
    else
      # return [:unknown] if generating?
      debugger
      tokens
    end
  end

  def transform_v1_assign_scope(tokens)
    case tokens[0]
    when :var,:var_array,:dmavar
      :var
    when :lvar,:lvar_array
      :lvar
    when :int,:int8,:int16,:int32
      nil
    when :float,:float32
      nil
    when :vlstring
      nil
    when :label, :mission_label
      nil
    else
      # return [:unknown] if generating?
      debugger
      tokens
    end

  end

  def transform_v1_assign_operator_words(operator)
    {
      :+ => ["add","to"],
      :- => ["sub","from"],
      :* => ["mult","by"],
      :/ => ["div","by"],
    }[operator]
  end

  def transform_v1_compare_operator_words(operator)
    {
      :"==" => [nil,"equal_to"],
      :"!=" => ["not_","equal_to"],
      :>=  => [nil,"greater_or_equal_to"],
      :>  => [nil,"greater_than"],
      :<=  => ["not_","greater_than"],
      :<  => ["not_","greater_or_equal_to"]
    }[operator]
  end

  def sexp(type,children = [])
    Parser::AST::Node.new(type,children)
  end

  def sexp?(node)
    node.is_a?(Parser::AST::Node)
  end

  def dma_var(name)
    return nil if !name || !name.to_s.match(/^_(\d+)$/)
    $1.to_i
  end

  def safe_lvar_return_var(lvar_name,function_name)
    # return nil
    return nil if !self.functions[function_name][:returns]
    resolved_lvars = self.functions[function_name][:returns].map do |k,v|
      v = v.map{|vv| vv[0] == :lvar ? vv[1] : nil}
      v = v.uniq.size == 1 ? v.first : nil
      [v,k]
    end
    Hash[resolved_lvars][lvar_name]
  end

  # FIXME: harmonize returns/args/locals for symbol export
  def export_symbols
    if self.scripts.size > 1
      raise "multiple scripts detected, confused about symbol export"
    end

    script_name = self.scripts.keys.first

    frames = []

    frame = {
      script: script_name,
      type: :script,
      name: script_name,
      range_labels: [:"start_script_#{script_name}",:"end_script_#{script_name}"],
      range_offsets: [], # gets filled in later
      stack: {}
    }

    if self.external_id
      frame[:external_id] = self.external_id
    end

    current_stack_vars(nil).each do |var_name|
      frame[:stack][ resolved_lvar_stack_offset(var_name,nil) ] = [var_name,resolved_lvar_type(var_name,nil),:local]
    end

    frames << frame

    instance_vars_to_types = Hash[ self.functions[nil][:instances].map{|k,v| [k,resolved_ivar_type(k)]} ]
    functions = {}
    self.functions.each_pair do |function_name,variables|
      next if function_name.nil?

      frame = {
        script: script_name,
        type: :function,
        name: function_name,
        range_labels: [:"function_#{function_name}",:"function_end_#{function_name}"],
        range_offsets: [], # gets filled in later
        stack: {}
      }

      if self.external_id
        frame[:external_id] = self.external_id
      end

      buckets = current_stack_vars_buckets(function_name)
      buckets.each_with_index do |bucket,bucket_id|
        bucket_name = {0 => :return, 1 => :argument, 2 => :local}[bucket_id]
        bucket.each do |var_name|
          unless stack_offset = safe_lvar_return_var(var_name,function_name)
            stack_offset = resolved_lvar_stack_offset(var_name,function_name)
          end
          type = resolved_lvar_type(var_name,function_name)
          if var_name.is_a?(Numeric)
            type = resolve_function_return_types(function_name)[var_name]
          end
          if bucket_name == :return && (return_name = resolved_return_var_name(function_name,var_name))
            var_name = return_name
          end
          frame[:stack][ stack_offset ] = [var_name,type,bucket_name]
        end
      end


      frames << frame

      # locals = variables[:locals].each_pair.map {|k,v|

      #   unless stack_offset = safe_lvar_return_var(k,name)
      #     stack_offset = resolved_lvar_stack_offset(k,name)
      #   end

      #   [stack_offset,k,resolved_lvar_type(k,name)]
      # }
      # functions[name] = {
      #   label: :"function_#{name}",
      #   end_label: :"function_#{name}",
      #   locals: locals,
      #   stack: current_stack_vars(name)
      # }
    end

    {
      frames: frames
    }

    # frames
    # script: foo
    # range: 1000,2000
    # -3: x float
    # -2: y float
    # -1: z float
  end


  attr_accessor :binary_block_filename
  attr_accessor :binary_block_offset
  attr_accessor :binary_block_lvar
  attr_accessor :binary_block_slices
  def on_binary_block(node)
    self.binary_block_filename = node[0][2][0]
    self.binary_block_offset = 0
    self.binary_block_lvar = node[1][0][0]
    self.binary_block_slices = [
      # [0,nil]
    ]

    body = transform_node(node[2])

    [
      *body
    ]
  ensure
    self.binary_block_filename = nil
    self.binary_block_offset = nil
    self.binary_block_lvar = nil
    self.binary_block_slices = nil
  end

  def on_binary_block_call_block(node)
    method_name = node[0][1]
    args = node[0][2..-1].map{|a| transform_node(a)[1] }
    body = transform_node(node[2])
    case method_name
    when :replace
      instruction = emit_next_binary_instruction(args[0])
      self.binary_block_offset = args[1]
      [
        instruction,
        *body
      ]
    when :patch
      instruction = emit_next_binary_instruction(args[0])
      self.binary_block_offset = args[1]
      [
        instruction,
        *body,
        [:PadUntil,[args[1]]]
      ]
    end
  end

  def on_binary_block_call(node)
    method_name = node[1]
    args = node[2..-1].map{|a| transform_node(a)[1] }
    instruction = nil

    case method_name
    when :delete
      instruction = emit_next_binary_instruction(args[0])
      self.binary_block_offset = args[1]
    when :include
      instruction = [:IncludeBin,[self.binary_block_filename,args[0],args[1]]]
    end

    [
      instruction
    ]
  end

  def emit_next_binary_instruction(next_offset)
    instruction = [:IncludeBin,[self.binary_block_filename,self.binary_block_offset,next_offset]]
    instruction
  end

end




