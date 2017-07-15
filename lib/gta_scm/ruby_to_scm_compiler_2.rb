
require 'gta_scm/ruby_to_scm_compiler'

# TODO:
# while loops
# next loop keyword
# for i in 0..12
# array/struct syntax:
#   $cars = IntegerArray[8]
#   @coords = Vector3[ 500.0 , 400.0 , 20.0 ]
#   foo(Vector3[],1000) => foo(0.0,0.0,0.0,1000)
# cast: 123.to_f
# functions returning true/false when used in if statements (use temp vars on stack?)
# constants
# switch statements
# syntax for raw global/local vars (GLOBALS[12]/LOCALS[2]) ($123 / @12)
# handle nested math operators with three-address-code
# allow calling routines with goto(&f1) / gosub(&f2)
# allowed to get var address with &$test ? need to compile as block_pass($test)
# declare function as using stack or static vars for returns/params
#   stack: recursion permitted, doesn't consume globals
#   static: consumes globals vars, smaller calls, no stack adjustment, no recursion permitted
#   use static for common calls

=begin
helper methods:

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

class GtaScm::RubyToScmCompiler2 < GtaScm::RubyToScmCompiler
  using RefinedParserNodes

  attr_accessor :state
  attr_accessor :opcodes
  attr_accessor :opcode_names
  attr_accessor :functions
  attr_accessor :current_function
  attr_accessor :last_child_was_return
  attr_accessor :label_type
  attr_accessor :loop_labels
  attr_accessor :stack_locations
  attr_accessor :script_block_hash
  attr_accessor :main_block_hash

  def compile_lvars_as_temp_vars?; true; end

  def initialize(*args)
    super
    self.functions = {
      # top-level stack frame for local vars
      nil => {
        locals: {},
        instances: {},
        globals: {}
      }
    }
    self.opcodes = GtaScm::OpcodeDefinitions.new
    self.opcodes.load_definitions!("san-andreas")
    self.opcode_names = Hash[self.opcodes.names2opcodes.map{|k,v| [k.downcase.to_sym,k]}]
    self.current_function = nil
    self.label_type = :label
    self.loop_labels = []
    self.stack_locations = {
      stack: :"_stack",
      sc: :"_sc",
      size: 32
    }
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

    when node.match( :block , [0] => :send , [0,1] => :main , [1] => :args , [2] => [:begin,:block] )
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
    when node.match( :block , [0] => :send , [0,1] => :function , [1] => :args , [2] => [:begin,:return,:send] )
      on_function_block( node )
    # when node.match( :block , [0] => :send , [0,1] => :function , [1] => :args , [2] => [:begin,:return,:send] )
    #   debugger
    #   on_function_block( node )

    when node.match( :def , [1] => :args , [2] => [:begin,:return,:send] )
      on_function_block( node )

    # when node.match( :send , [1] => :function )

    when node.match( :block , [0] => :send , [0,1] => :declare , [1] => :args )
      on_declare_block( node )

    when node.match( :send , [1] => [:float,:int] )
      on_declare_call( node )

    when node.match( :block, [0] => :send, [0,1] => :loop, [2] => [:begin,:send])
      on_loop( node )

    when node.match( :if ) && node[2]
      on_if_else(node)

    when node.match( :if )
      on_if(node)

    when node.match( :break )
      on_break(node)

    # Generic block
    when node.match( :block )
      transform_node(node[0])

    # Assignment
    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => [:lvar,:ivar,:gvar,:int,:float,:string] )
      on_assign( node )

    # Multi-assignment
    when node.match( :masgn , [0] => :mlhs , [1] => :array )
      on_multi_assign( node )

    when node.match( [:ivasgn,:gvasgn,:lvasgn] , [1] => :send , [1,1] => :block_pass)
      on_dereference_assign( node )

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
      on_array_declare(node)

    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send, [1,0,1] => [:FloatArray,:IntegerArray], [1,1] => :new)
      on_array_declare(node)

    # Compare
    when node.match( :send , [1] => [:>,:<,:>=,:<=,:==,:!=] )
      on_compare(node)

    # Math expression
    when compilable_math_expression?(node)
      on_math_expression(node)

    # unknown function call, complain later when generating instructions
    when node.match( :send ) || node.match( :lvasgn , [1] => :send)
      debugger
      [[:unknown_call, node[1] ]]

    # Return
    when node.match( :return )
      on_return( node )

    # FIXME: are these appropriate? they don't generate instructions
    when node.match( [:lvar,:ivar,:gvar] )
      on_var_use(node)

    when node.match( [:int,:float,:string] )
      on_immediate_use(node)

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

  def current_stack_vars
    slots = []
    if self.current_function
      slots += self.functions[self.current_function][:returns].map{|k,v| k }
      slots += self.functions[self.current_function][:arguments].map{|k,v|
        # k
        safe_lvar_return_var(k,self.current_function) ? nil : k
      }.compact
    end
    # slots += [:__why]
    slots += self.functions[self.current_function][:locals].map{|k,v|
      safe_lvar_return_var(k,self.current_function) ? nil : k
    }.compact
  end

  def resolved_lvar_stack_offset(lvar_name)
    slots = current_stack_vars
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
    resolved_types = self.functions[nil][:globals][gvar_name(name)].map do |var_or_val|
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
        self.functions[nil][:instances][ lhs[1] ] ||= []
        self.functions[nil][:instances][ lhs[1] ] << [ self.current_function , rhs ]
      end
    end

    lhs
  end

  def on_var_use(node)
    case node.type
    when :lvar
      on_lvar_use(node)
    when :ivar
      on_ivar_use(node)
    when :gvar
      on_gvar_use(node)
    else
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
  def on_const_use(*)
  end
  # CONST = 1
  def on_const_assign(*)
  end

  def on_immediate_use(node)
    case node.type
    when :int
      [:int32,node[0]]
    when :float
      [:float32,node[0]]
    else
      raise "unknown immediate #{node.inspect}"
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

    begin
      self.script_block_hash = hash
      body = []
      # body += transform_node( sexp(:lvasgn,[sexp(:lvar,[:"__#{self.current_function||"nil"}"]),sexp(:int,[-1111])]) )
      body += transform_node(node[2])
    ensure
      self.script_block_hash = nil
    end

    [
      [:labeldef,:start_script],
      *function_prologue(nil),
      *body,
      [:labeldef,:end_script],
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
        body << [:goto,[[:label,loop_label]]]
      end
    ensure
      self.main_block_hash = nil
    end

    body
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
        returns:   {},
        arguments: {},
        locals:    {},
        invokes:   []
      }
      node[1].each do |arg|
        self.functions[self.current_function][:arguments][ arg[0] ] ||= []
      end
    end

    body = []
    # body += transform_node( sexp(:lvasgn,[sexp(:lvar,[:"__#{self.current_function||"nil"}"]),sexp(:int,[-2222])]) )
    body += transform_node(node[2])

    prologue = []
    epilogue = []
    # transform_node( sexp(:lvasgn,[sexp(:lvar,[:"__#{self.current_function||"nil"}"]),sexp(:int,[-1])]) )
    if generating?
      prologue += function_prologue(self.current_function)
      # debugger
      # prologue += transform_node( sexp(:lvasgn,[sexp(:lvar,[:"__#{self.current_function||"nil"}"]),sexp(:int,[-1])]) )
      if !self.last_child_was_return
        epilogue += function_epilogue(self.current_function)
        epilogue += [[:return]]
      end
    end


    [
      [:goto,[[self.label_type,:"function_end_#{self.current_function}"]]],
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

  def resolve_lvar_type(lvar_name,function_name)
    
  end

  def function_prologue(function_name)
    prologue = []
    self.functions[function_name][:locals].each_pair do |lvar_name,uses|
      lvar_type = resolve_lvar_type(lvar_name,function_name)
      # prologue << [ :stack_push , lvar_name ]
    end
    stack_adjust = function_stack_size(function_name)
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
    when node.match(:lvasgn)
      on_lvar_assign(node,rhs)
    when node.match(:ivasgn)
      on_ivar_assign(node,rhs)
    when node.match(:gvasgn)
      on_gvar_assign(node,rhs)
    when node.match( :op_asgn , [0] => [:lvasgn] )
      on_lvar_assign(node[0],nil)
    when node.match( :send , [0] => [:lvar] )
      on_lvar_assign(node[0],nil)
    when node.match( :send , [0] => [:ivar] )
      on_ivar_assign(node[0],nil)
    else
      raise "unknown assignment_lhs #{node.inspect}"
    end
  end

  def assignment_rhs(node)
    case
    when node.match([:lvasgn,:ivasgn,:gvasgn], [1] => [:int,:float,:string])
      on_immediate_use(node[1])
    when node.match([:lvasgn,:ivasgn,:gvasgn], [1] => [:lvar,:gvar,:ivar])
      on_var_use(node[1])
    when node.match( :op_asgn , [2] => :lvar )
      on_var_use(node[2])
    when node.match( :op_asgn, [0] => [:lvasgn,:ivasgn,:gvasgn], [1] => [:+,:-,:*,:/], [2] => [:lvar,:ivar,:gvar])
      on_var_use(node[2])
    when node.match( :op_asgn, [0] => [:lvasgn,:ivasgn,:gvasgn], [1] => [:+,:-,:*,:/], [2] => [:int,:float])
      on_immediate_use(node[2])
    when node.match( :send, [1] => [:+,:-,:*,:/], [2] => [:int,:float])
      on_immediate_use(node[2])
    when node.match([:lvar,:gvar,:ivar])
      on_var_use(node)
    when node.match([:float,:int])
      on_immediate_use(node)
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
      transform_node(node[2])
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
    [self.current_function || "label",prefix,@generate_label_counter].join("_").to_sym
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
      [:goto,[[:label,loop_start]]],
      [:labeldef,loop_end]
    ]
  end

  def on_if(node)
    andor_value,conditions = transform_conditions(node[0])
    body = transform_node(node[1])

    false_label = generate_label!(:if)
    [
      [:andor,[[:int8,andor_value]]],
      *conditions,
      [:goto_if_false,[[self.label_type,false_label]]],
      *body,
      [:labeldef,false_label]
    ]
  end

  def on_if_else(node)
    andor_value,conditions = transform_conditions(node[0])

    true_body = transform_node(node[1])
    false_body = transform_node(node[2])

    end_label = generate_label!(:if)
    false_label = generate_label!(:if)
    [
      [:andor,[[:int8,andor_value]]],
      *conditions,
      [:goto_if_false,[[self.label_type,false_label]]],
      *true_body,
      [:goto,[[self.label_type,end_label]]],
      [:labeldef,false_label],
      *false_body,
      [:labeldef,end_label]
    ]
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
    
    # [
    #   :assign,
    #   [lhs,]
    # ]
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
        arguments: function_call_arguments(node).map{|a| transform_node(a)}
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

    if arguments.size != self.functions[function_name][:arguments].size
      raise "wrong number of arguments for #{function_name} (expected #{self.functions[function_name][:arguments].size}, invoked with #{arguments.size})"
    end

    argument_assigns = []
    arguments.each_with_index do |argument,argument_index|
      # stack_index = self.functions[function_name][:returns].size + argument_index
      # debugger
      stack_index = if idx = self.safe_lvar_return_var(argument[0],function_name)
        idx
      else
        self.functions[function_name][:returns].size + argument_index
      end

      rhs = transform_node(argument)
      rhs_type = resolve_var_type(rhs,self.current_function)
      lhs = [:stack,stack_index,:"argument_#{argument_index}",rhs_type]
      argument_assigns << [:assign, [ lhs , rhs ]]
    end
    
    [
      *argument_assigns,
      # [:stack_adjust, (self.functions[function_name][:returns].size + self.functions[function_name][:arguments].size)]
    ]
  end

  def function_call_return_assignments(node,function_name)
    return_vars = function_call_return_vars(node,function_name)
    
    if return_vars.size != self.functions[function_name][:returns].size
      raise "wrong number of return args (function returns #{self.functions[function_name][:returns].size}, invoked with #{return_vars.size})"
    end

    return_var_types = resolve_function_return_types(function_name)
    return_var_assigns = []
    return_vars.each_with_index do |return_var,return_index|
      rhs = [:stack,return_index,:"return_#{return_index}",return_var_types[return_index]]
      return_var_assigns << [:assign,[return_var,rhs]]
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

    [
      [opcode_name,arguments + return_vars]
    ]
  end

  def opcode_call_name(node,negated = false)
    name = case
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
    case
    # no return vars
    when node.match(:send)
      []
    # single var assignment
    when node.match( [:lvasgn,:ivasgn,:gvasgn] )
      [
        assignment_lhs(node,[return_types[0],nil])
      ]
    # multiple var assignment
    when node.match( :masgn )
      vars = []
      node[0].each_with_index do |var,index|
        vars << [assignment_lhs(var,[return_types[index],nil])]
      end
      vars
    else
      debugger
      raise "unknown opcode return vars #{node.inspect} #{return_types.inspect}"
    end
  end

  def opcode_call_arguments(node)
    arguments = case
    when node.match(:send)
      node[2..-1]
    when node.match( [:lvasgn,:ivasgn,:gvasgn] , [1] => :send )
      node[1][2..-1]
    when node.match( :masgn , [1] => :send )
      node[1][2..-1]
    else
      raise "unknown opcode call arguments #{node.inspect}"
    end
    arguments.map do |argument|
      if argument.immediate_value?
        transform_node(argument)
      else
        on_var_use(argument)
      end
    end
  end

  def on_array_declare(node)
    []
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
    [
      [:EmitNodes, false],
      *transform_node(node[2]),
      [:EmitNodes, true]
    ]
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
        
        if rhs_scope
          opcode_name << "_to_#{rhs_scope}_#{rhs_type}"
        end

        if opcode_name == "set_var_int_to_lvar_float"
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

        if opcode_name == "mult_val_by_int_var"
          debugger
        end

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
    when :var_array
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

end




