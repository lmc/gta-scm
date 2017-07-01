
require 'gta_scm/ruby_to_scm_compiler'

# TODO:
# negated opcode calls: !locate_player_3d(coords1,coords2)
# while loops
# next loop keyword
# for i in 0..12
# timer use/assign:  @timer_a / @timer_b = 0
# arrays: @cars = IntegerArray.new(8)
# structs: @coords = Vector3.new(100.0,200.0,300.0)
# cast: 123.to_f
# functions returning true/false when used in if statements
# syntax for raw global/local vars (GLOBALS[12]/LOCALS[2])
# handle nested math operators with three-address-code

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
      size: 0
    }
  end

  def opcode(name)
    self.opcodes[ self.opcode_names[name] ]
  end

  def opcode_return_types(name)
    self.opcode(name).arguments.select{|a| a[:var]}.map{|a| a[:type]}
  end

  def transform_code(node,generate_v1_tokens = true)
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
    # s(:block,
    #   s(:send, nil, :function,
    #     s(:sym, :my_stack_function)),
    #   s(:args,
    #     s(:arg, :arg1),
    #     s(:arg, :arg2)),
    #   s(:begin,
    #     [body]
    when node.match( :block , [0] => :send , [0,1] => :script , [1] => :args , [2] => [:begin,:block] )
      on_script_block( node )

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

    # when node.match( :send , [1] => :function )

    when node.match( :block, [0] => :send, [0,1] => :loop, [2] => [:begin])
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

    # Compare
    when node.match( :send , [1] => [:>,:<,:>=,:<=,:==,:!=] )
      on_compare(node)

    # Math expression
    when compilable_math_expression?(node)
      on_math_expression(node)

    # unknown function call, complain later when generating instructions
    when node.match( :send ) || node.match( :lvasgn , [1] => :send)
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
        if node[1] == :timer
          debugger
        end

        [:stack,resolved_lvar_stack_offset(node[0]),node[0],resolved_lvar_type(node[0],current_function)]
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
      slots += self.functions[self.current_function][:arguments].map{|k,v| k }
    end
    slots += self.functions[self.current_function][:locals].map{|k,v| k}
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
      :TODO_resolve_gvar_type
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
      if resolved_types.uniq.size > 1
        raise "multiple resolved types for #{lvar_name}: #{resolved_types.inspect}"
      end
      # debugger
      # self.functions[function_name][:arguments][lvar_name] = resolved_types[0]
      return resolved_types[0]

    elsif self.functions[function_name].andand[:locals].andand.key?(lvar_name)
      resolved_types = self.functions[function_name][:locals][lvar_name].map do |var_or_val|
        resolve_var_type(var_or_val,function_name)
      end
      if resolved_types.uniq.size > 1
        raise "multiple resolved types for #{lvar_name}: #{resolved_types.inspect}"
      end
      return resolved_types[0]
    else
      nil
    end
  end

  def resolved_ivar_type(name)
    resolved_types = self.functions[nil][:instances][ivar_name(name)].map do |(caller,var_or_val)|
      resolve_var_type(var_or_val,nil)
    end
    if resolved_types.uniq.size > 1
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
      [:gvar,gvar_name(node[0])]
    else
      raise "unknown gvar #{node.inspect}"
    end
  end
  # $gvar = 1
  def on_gvar_assign(node,rhs)
    on_gvar_use(node)
  end

  def ivar_name(name)
    name.to_s.gsub(/^@/,'').to_sym
  end

  # @ivar
  def on_ivar_use(node)
    case node.type
    when :ivar, :ivasgn
      if generating?
        [:ivar,ivar_name(node[0]),resolved_ivar_type(node[0])]
      else
        [:ivar,ivar_name(node[0])]
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
    hash = eval_hash_node(node[0][2])
    self.stack_locations[:stack] = hash[:stack]         if hash[:stack]
    self.stack_locations[:sc]    = hash[:stack_counter] if hash[:stack_counter]
    self.stack_locations[:size]  = hash[:stack_size]    if hash[:stack_size]

    [
      [:labeldef,:start_script],
      *function_prologue(nil),
      *transform_node(node[2]),
      [:labeldef,:end_script],
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
    self.current_function = node[0][2][0]

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

    body = transform_node(node[2])

    prologue = []
    epilogue = []
    if generating?
      prologue = function_prologue(self.current_function)
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
    stack_size += self.functions[function_name][:arguments].size if self.functions[function_name][:arguments]
    stack_size += self.functions[function_name][:locals].size    if self.functions[function_name][:locals]
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
    else
      raise "unknown assignment_lhs #{node.inspect}"
    end
  end

  def assignment_rhs(node)
    case
    when node.match([:lvasgn,:ivasgn,:gvasgn], [1] => [:int,:float,:string])
      on_immediate_use(node[1])
    when node.match([:lvasgn,:ivasgn,:gvasgn], [1] => :lvar)
      on_var_use(node[1])
    when node.match( :op_asgn , [2] => :lvar )
      on_var_use(node[2])
    when node.match( :op_asgn, [0] => [:lvasgn,:ivasgn,:gvasgn], [1] => [:+,:-,:*,:/], [2] => [:lvar])
      on_var_use(node[2])
    when node.match( :op_asgn, [0] => [:lvasgn,:ivasgn,:gvasgn], [1] => [:+,:-,:*,:/], [2] => [:int,:float])
      on_immediate_use(node[2])
    when node.match( :send, [1] => [:+,:-,:*,:/], [2] => [:int,:float])
      on_immediate_use(node[2])
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
      [:andif,[[:int8,andor_value]]],
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
      [:andif,[[:int8,andor_value]]],
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
      [:gosub, :"function_#{function_name}"],
      *function_call_return_assignments(node,function_name),
    ]
  end

  def function_call_name(node)
    if node.match(:send)
      node[1]
    elsif node.match([:lvasgn,:ivasgn,:gvasgn])
      node[1][1]
    else
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
      stack_index = self.functions[function_name][:returns].size + argument_index
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
        assigns << on_var_assign(node,return_types[idx])
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
  def on_opcode_call(node)
    opcode_name = opcode_call_name(node)
    return_types = opcode_return_types(opcode_name)
    return_vars = opcode_return_vars(node,return_types)

    arguments = opcode_call_arguments(node)

    [
      [opcode_name,arguments + return_vars]
    ]
  end

  def opcode_call_name(node)
    case
    when node.match(:send)
      node[1]
    when node.match([:masgn,:lvasgn],[1] => :send)
      node[1][1]
    else
      raise "unknown opcode name #{node.inspect}"
    end
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
      if generating? && rhs[0][0] == :stack
        lhs[3] = rhs[0][3]
      end
      assignments << [:assign,[ lhs, rhs ]]
    end
    assignments
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
    elsif node.match( :send , [0] => [:lvar,:ivar,:gvar] , [1] => [:+,:-,:*,:/] , [2] => [:lvar,:ivar,:gvar,:int,:float,:begin] )
      return true
    elsif node.match( :begin )
      return compilable_math_expression?( node[0] , level + 1 )
    else
      return false
    end
  end

  def tac_id
    if !@tac_id
      reset_tac_id!
    end
    @tac_id += 1
    :"_tac_#{@tac_id}"
  end

  def reset_tac_id!
    @tac_id = 0
    @tac_instructions = []
  end

  def on_math_expression(node,level = 0)
    if level == 0
      reset_tac_id!
    end

    # debugger

    if node.match( [:lvasgn,:ivasgn,:gvasgn] )
      on_math_expression( node[1] , level + 1 )
    # elsif node.match( :send , [0] => :begin , [0,0] => :send )
    #   on_math_expression(node[0])
    elsif node.match( :send , [0] => [:lvar,:ivar,:gvar] , [1] => [:+,:-,:*,:/] , [2] => [:lvar,:ivar,:gvar,:int,:float] )
      # simple expression only
      rhs = assignment_rhs(node)
      lhs = assignment_lhs(node,nil)
      operator = assignment_operator(node)
      var = self.tac_id
      debugger
      @tac_instructions += [
        [:assign, var, lhs],
        [:assign_operator, var, operator, rhs]
      ]
    elsif node.match( :send , [0] => [:lvar,:ivar,:gvar,:begin] , [1] => [:+,:-,:*,:/] , [2] => [:begin,:lvar,:ivar,:gvar,:int,:float] )

      # FIXME: handle unresolved left/right hand sides
      # FIXME: can you even generate this thing recursively or do you need a stack?

      lhs,rhs = nil,nil

      if node[2].match([:send,:begin])
        on_math_expression( node[2] , level + 1 )
      else
        rhs = assignment_rhs( node )
        # debugger
        # node
      end

      if node[0].match([:send,:begin])
        on_math_expression( node[0] , level + 1 )
      else
        lhs = assignment_rhs(lhs)
        # debugger
        # node
      end

      if lhs || rhs
        debugger
        node
      end

      # debugger
      # "foo"
      # node

    elsif node.match( :begin )
      on_math_expression( node[0] , level + 1 )
    else
      debugger
      raise "???"
    end

    debugger

    # instructions

    @tac_instructions

  end


  def eval_hash_node(node)
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

        opcode_name = "set_#{lhs_scope}_#{lhs_type}"
        
        if rhs_scope
          opcode_name << "_to_#{rhs_scope}_#{rhs_type}"
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

        if rhs_scope
          opcode_name << "#{rhs_type}_#{rhs_scope}"
        else
          opcode_name << "val"
        end

        opcode_name << "_#{opcode_parts[1]}_"
        opcode_name << "#{lhs_type}_#{lhs_scope}"

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
      if arg[0] == :stack
        [
          :var_array,
          :"#{self.stack_locations[:stack]}#{arg[1]>0 ? :+ : :-}#{arg[1].abs*4}",
          self.stack_locations[:sc],
          -1 || self.stack_locations[:size],
          [:var,arg[3] == :float ? :float32 : :int32]
        ]
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
      tokens[3][1] == :float32 ? :float : :int
    when :stack
      tokens[3] == :float32 ? :float : :int
    else
      # return [:unknown] if generating?
      debugger
      tokens
    end
  end

  def transform_v1_assign_scope(tokens)
    case tokens[0]
    when :var,:var_array
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

end




