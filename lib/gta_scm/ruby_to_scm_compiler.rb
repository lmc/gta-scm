
class GtaScm::RubyToScmCompiler

  attr_accessor :scm
  attr_accessor :label_prefix
  attr_accessor :external
  attr_accessor :metadata
  attr_accessor :temp_var_assignments

  attr_accessor :var_objects
  attr_accessor :lvar_objects

  attr_accessor :function_definitions

  OBJECT_STRUCTURES = {
    Vector3: { x: :float, y: :float, z: :float }
  }

  def initialize
    self.local_method_names_to_labels = {}
    self.label_prefix = "label_"
    self.var_arrays = {}
    self.var_objects = {}
    self.lvar_arrays = {}
    self.lvar_objects = {}
    self.routines_block = false
    self.temp_var_assignments = {}
    self.function_definitions = {}
    install_constants!
  end

  def install_constants!
    self.constants_to_values ||= {}
    self.constants_to_values[:PLAYER] = [:dmavar, 8]
    self.constants_to_values[:PLAYER_CHAR] = [:dmavar, 12]
    self.constants_to_values[:TIMER_A] = [:lvar, 32]
    self.constants_to_values[:TIMER_B] = [:lvar, 33]
    # self.constants_to_values[:BREAKPOINT_PC] = [:dmavar, 12]
  end

  def parse_ruby(ruby)
    begin
      parsed = Parser::CurrentRuby.parse(ruby)
    rescue Parser::SyntaxError => exception
      raise GtaScm::RubyToScmCompiler::InputError.new("error",exception,self.metadata)
    end
  end

  def transform_node(node)
  begin
    # debugger
    if !node.respond_to?(:type)
      debugger
      node
    end

    ttt = case node.type

    when :block

      if node.children[0].type == :send && node.children[0].children[1] == :loop
        emit_loop(node,node.children[2])
      elsif node.children[0].type == :send && node.children[0].children[1] == :emit
        handle_conditional_emit(node,node.children[0].children[2].type == :true)
      elsif node.children[0].type == :send && node.children[0].children[1] == :routines
        handle_routines_declare(node)
      # elsif node.children[0].type == :send && node.children[0].children[1] == :routine
        
      else
        raise "unknown block type: #{node.inspect}"
        raise UnhandledNodeError.new(node)
      end

    when :while
      if node.children.size == 2
        emit_loop(node,node.children[1],node.children[0])
      else
        debugger
      end

    when :for

      if node.node.children[1].type == :irange
        emit_for_range_loop(node.children[0],node.children[1],node.children[2])
      else
        raise "can only handle `for + range`"
      end

    when :begin

      emit_block(node)

    when :def

      emit_method_def(node)

    # multiple assign
    # s(:masgn,
    #   s(:mlhs,
    #     s(:lvasgn, :x),
    #     s(:lvasgn, :y),
    #     s(:lvasgn, :z)),
    #   s(:send, nil, :get_char_coordinates,
    #     s(:gvar, :$_12)))
    # for opcodes, assigns seem to be the final args each time
    when :masgn

      if node.children[1].type == :send
        [ emit_assignment_opcode_call(node.children[1],node.children[0],:masgn) ]
      else
        handle_multiple_assigns(node)
      end

    # global var assign
    when :gvasgn

      # [ emit_assignment_opcode_call(node.children[1],node.children[0],:gvasgn) ]
      emit_global_var_assign(node)

    # local var assign
    when :lvasgn

      emit_local_var_assign(node)

    when :casgn

      record_constant_assign(node)

    when :op_asgn

      emit_operator_assign(node)

    when :if

      if node.children[0].type == :send && node.children[0].children[1] == :emit
        handle_conditional_emit(node, node.children[0].children[2].type == :true)
      else
        emit_if(node)
      end

    when :send
      # debugger
      if node.children[1] == :debugger
        emit_breakpoint(node)
      elsif node.children[1] == :emit
        emit_raw(node)
      elsif node.children[1] == :[]= && node.children[0].type == :gvar
        emit_global_var_assign(node)
      elsif node.children[1] == :[]= && node.children[0].type == :lvar
        emit_local_var_assign(node)
      elsif node.children[2].andand.type == :send
        # property assign
        emit_operator_assign(node)
      else
        emit_opcode_call(node)
      end

    when :break

      [ emit_break(node) ]

    when :return

      emit_return_value(node)

    else
      debugger
      raise "unknown node type #{node.type.inspect}"
    end

    # puts "transform_node - #{ttt.inspect}"

    ttt
  rescue GtaScm::RubyToScmCompiler::NodeError => exception
    raise InputError.new("transform_node",exception,self.metadata)
  end
  end

  def handle_conditional_emit(node,do_emit = true)
    # do_emit = node.children[0].children[2].type == :true
    if node.children[1].type == :begin
      nodes = transform_node(node.children[1])
    else
      nodes = transform_node(node.children[2])
    end
    if do_emit
      nodes
    else
      [
        [:EmitNodes, false],
        *nodes,
        [:EmitNodes, true]
      ]
    end
  end

  attr_accessor :routines_block
  
  def handle_routines_declare(node)
    self.routines_block = true
    nodes = transform_node(node.children[2])
    self.routines_block = false
    routines_end = generate_label!
    [
      [:goto,[[self.label_type,routines_end]]],
      *nodes,
      [:labeldef,routines_end]
    ]
  end

  attr_accessor :loop_stack
  def emit_loop(loop_node,block_node,condition_node = nil,condition_at_start = nil)
    loop_start = generate_label!
    loop_exit = generate_label!

      self.loop_stack ||= []
    begin
      if condition_node
        condition_label = generate_label!
        andor_id, conditions = emit_if_conditions(condition_node)
        condition_block = [
          *self.andor_instruction(andor_id),
          *conditions,
          [:goto_if_false, [:label,loop_exit]],
        ]
        condition_at_start = true if condition_at_start.nil?
        if condition_at_start
          condition_start_block = condition_block
        else
          condition_end_block = condition_block
        end
      end
      condition_start_block ||= []
      condition_end_block ||= []

      self.loop_stack << {start: loop_start, exit: loop_exit}
      [
        [:labeldef, loop_start],
        *condition_start_block,
        *transform_node(block_node),
        *condition_end_block,
        [:goto,[[self.label_type,loop_start]]],
        [:labeldef, loop_exit]
      ]
    ensure
      self.loop_stack.pop
    end
  end

  def emit_break(node)
    loop_exit = self.loop_stack.last[:exit]
    return [:goto, [[self.label_type, loop_exit]]]
  end

  def emit_for_range_loop(variable_node,range_node,block_node)
    
  end

  def emit_return_value(node)
    if node.children.size == 0
      [
        [:return]
      ]
    else
      condition = node.children[0].type == :true
      opcode = condition ? :not_is_ps2_keyboard_key_pressed : :is_ps2_keyboard_key_pressed
      value = condition ? 1 : 0
      [
        [opcode,[[:int8,value]]],
        [:return]
      ]
    end
  end

  def handle_multiple_assigns(node)
    instructions = []
    value_idx = 0
    node.children[0].children.each_with_index.map do |left,i|
      if left.type == :lvasgn && self.lvar_objects[ left.children[0] ]
        variable_name = left.children[0]
        OBJECT_STRUCTURES[ self.lvar_objects[ variable_name ] ].each_pair do |property,type|
          left = Parser::AST::Node.new(:lvar,[:"#{variable_name}_#{property}"])
          right = node.children[1].children[value_idx]
          value_idx += 1
          instructions << emit_n_var_assign(node,:lvar,left,right)[0]
        end
      else
        right = node.children[1].children[value_idx]
        value_idx += 1
        instructions << emit_n_var_assign(node,:lvar,left,right)[0]
      end
    end
    instructions
  end

  def emit_block(node)
    sexps = []
    node.children.each do |c|
      cc = transform_node(c)
      sexps += cc
    end
    sexps
  end

  def label_type
    self.external ? :mission_label : :label
  end

  attr_accessor :local_method_names_to_labels
  def emit_method_def(node)
    method_name = node.children[0]

    args = {name: method_name}
    if node.children[1].andand.children.andand[0].andand.children.andand[2].andand.type == :hash
      node.children[1].children[0].children[2].children.each do |pair|
        if pair.children[1].type == :array
          args[ pair.children[0].children[0] ] = pair.children[1].children
        else
          args[ pair.children[0].children[0] ] = pair.children[1].children[0]
        end
      end
    end

    # raise "can only handle :args" if node.children[1].type != :args
    method_body = case node.children[1].type
      when :send
        emit_opcode_call(node.children[1])
      when :begin
        transform_node(node.children[1])
      when :block
        if node.children[1].children[0].type == :send && node.children[1].children[0].children[1] == :routine
          handle_routine_declare(node,args)
        elsif node.children[1].children[0].type == :send && node.children[1].children[0].children[1] == :function
          handle_function_declare(node,args)
        else
          debugger
          raise "cannot handle ???"
        end
      else
        debugger
        raise "cannot handle ???"
      end

    self.local_method_names_to_labels ||= {}
    raise "method name #{method_name} already defined!" if self.local_method_names_to_labels[method_name]

    method_label = self.local_method_names_to_labels["#{method_name}"] = generate_label!
    method_end_label = self.local_method_names_to_labels["#{method_name}_end"] = generate_label!

    jump_opcode = [:goto, [[self.label_type, method_end_label]]]
    jump_opcode = nil if self.routines_block

    end_opcode = [:return]
    end_opcode = [:terminate_this_script] if args[:end_with] == :terminate_this_script
    end_opcode = nil                      if args.key?(:end_with) && args[:end_with].nil?

    [
      jump_opcode,
      [:labeldef, method_label],
      *method_body,
      end_opcode,
      [:labeldef, method_end_label]
    ].compact
  end

  def emit_local_var_assign(node)
    self.emit_n_var_assign(node,:lvar)
  end

  def emit_global_var_assign(node)
    self.emit_n_var_assign(node,:var)
  end

  def emit_n_var_assign(node,var_type,left = nil, right = nil)
    left ||= node.children[0]
    right ||= node.children[1]
    right_val = nil

    if right == :[]=
      is_array = true
      left = node
      right = node.children[3]
    end

    if !node.children[0].is_a?(Symbol) && node.children[0].type == :gvar && node.children[1] == :[]=
      if node.children[3].type == :send
        return [ emit_assignment_opcode_call(node.children[3],node) ]
      else
        # debugger
        # return [emit_assignment_opcode_call(right, node)]
      end
    end

    # if left.is_a?(Symbol) && left.to_s.match(/\A\$/)
    #   return [emit_operator_assign(node)]
    # end

    if right.type == :send
      if right.children[0].andand.type == :const && right.children[0].children[1] == :IntegerArray && right.children[1] == :new
        return record_array_assign(node)
      elsif right.children[0].andand.type == :const && right.children[0].children[1] == :Vector3 && right.children[1] == :new
        return record_object_assign(node)
      else
        return [emit_assignment_opcode_call(right, node)]
      end
    end

    type = right.type

    if type == :const
      right_val = self.constants_to_values[ right.children[1] ]
      type = self.constants_to_types[ right.children[1] ]
    end

    if type == :true || type == :false || type == :nil
      type = :int
    end

    if node.type == :gvasgn && node.children[1].type == :gvar
      # FIXME: handle types here

      left = gvar(node.children[0],nil)
      right = gvar(node.children[1].children[0],nil)
      return [ [:set_var_int_to_var_int,[left,right]] ]
    end
    if node.type == :lvasgn && node.children[1].type == :gvar
      # FIXME: handle types here
      left = lvar(node.children[0],nil)
      right = gvar(node.children[1].children[0],nil)
      return [ [:set_lvar_int_to_var_int,[left,right]] ]
    end

    # FIXME: handle :str here

    # debugger
    if type == :int
      # right_val ||= [:int32,node.children[1].children[0]]
      right_val ||= emit_value(right)
      if is_array
        left_var = emit_value(left)
      else
        left_var = case var_type
        when :var
          gvar(left,:int)
        when :lvar
          lvar(left,:int)
        else
          raise("???")
        end
      end
      return [[:"set_#{var_type}_int" , [left_var , right_val ]]]
    end
    if type == :float
      # right_val ||= [:float32,node.children[1].children[0]]
      right_val ||= emit_value(right)
      var = case var_type
      when :var
        gvar(left,:float)
      when :lvar
        lvar(left,:float)
      else
        raise("???")
      end
      return [[:"set_#{var_type}_float" , [var , right_val ]]]
    end
    if type == :str
      right_val = [:string8, node.children[1].children[0] ]
      var = case var_type
      when :var
        gvar(node.children[0],:string)
      when :lvar
        lvar(node.children[0],:string)
      else
        raise("???")
      end
      return [[:"set_#{var_type}_text_label" , [var , right_val ]]]
    end
    if type == :lvar
      return emit_operator_assign(node)
    end
    if type == :block
      nn = emit_method_def(node)
      # debugger
      return nn
    end
    if is_array
      array_name = node.children[0].children[0]
      if array_def = self.lvar_arrays[array_name]
        array_type = array_def[3] == :int32 ? :int : :float
        left = emit_value(node)
        right = emit_value(right)
        return [[:"set_lvar_#{array_type}" , [left , right ]]]
      elsif array_def = self.var_arrays[array_name]
        array_type = array_def[3] == :int32 ? :int : :float
        left = emit_value(node)
        right = emit_value(right)
        return [[:"set_var_#{array_type}" , [left , right ]]]
      end
      # var_type = array_def[]
    end

    debugger
    raise "unknown lvar assignment #{node.inspect}"
  end

  attr_accessor :constants_to_values
  attr_accessor :constants_to_types
  def record_constant_assign(node)
    # FIXME: use emit_value for timer assigns
    if node.children[1] == :TIMER_A
      # return [ [:set_lvar_int,[[:lvar,32,:timer_a],[:int32,node.children[2].children[0]]]] ]
      return [ [:set_lvar_int,[[:lvar,32,:timer_a],emit_value(node.children[2])]] ]
    elsif node.children[1] == :TIMER_B
      return [ [:set_lvar_int,[[:lvar,33,:timer_b],emit_value(node.children[2])]] ]
    elsif node.children[2].type == :array
      # raw sexp
      self.constants_to_values ||= {}
      self.constants_to_values[ node.children[1] ] = node.children[2].children.map{|n| n.children[0] }
      return []
    else
      self.constants_to_values ||= {}
      self.constants_to_values[ node.children[1] ] = emit_value( node.children[2] )
      self.constants_to_types ||= {}
      self.constants_to_types[ node.children[1] ] = node.children[2].type
      return []
    end
  end

  attr_accessor :var_arrays
  attr_accessor :lvar_arrays
  def record_array_assign(node)
    array_scope = node.type == :gvasgn ? :var_array : :lvar_array
    variable_name = node.children[0] # $:times
    if node.children[1].children[2].type == :const
      if !self.constants_to_values[ node.children[1].children[2].children[1] ]
        raise "undefined constant #{node.children[1].children[2].children[1]}"
      end
      array_size = self.constants_to_values[ node.children[1].children[2].children[1] ][1]
    else
      array_size = node.children[1].children[2].children[0]
    end
    array_type = node.children[1].children[0].children[1] == :IntegerArray ? :int32 : :float32

    instructions = []

    if array_scope == :var_array
      self.var_arrays ||= {}
      self.var_arrays[variable_name] = [array_scope,variable_name,array_size,array_type]
      # debugger
      # reserve gvar slots
      array_size.times do |i|
        i = i == 0 ? "" : "_#{i}"
        var = gvar(:"#{variable_name}#{i}",array_type)
        # var = [:var_array, var[0], 0, [array_type,]]
        instructions << [:set_var_int,[var,[:int8,0]]]
      end
    else
      self.lvar_arrays ||= {}
      self.lvar_arrays[variable_name] = [array_scope,variable_name,array_size,array_type]

      # reserve lvar slots
      array_size.times do |i|
        i = i == 0 ? "" : "_#{i}"
        var = lvar(:"#{variable_name}#{i}",array_type)
        instructions << [:set_lvar_int,[var,[:int8,0]]]
      end
    end

    return instructions
    # return []
  end

  def record_object_assign(node)
    if node.type == :lvasgn
      object_name = node.children[1].children[0].children[1]
      variable_name = node.children[0]

      self.lvar_objects[variable_name] = object_name

      instructions = []
      OBJECT_STRUCTURES[ self.lvar_objects[variable_name] ].map do |property,type|
        var = Parser::AST::Node.new(:lvar,[:"#{variable_name}_#{property}"])
        default_value = type == :int ? 0 : 0.0
        value = Parser::AST::Node.new(type,[default_value])
        instructions << [:"set_lvar_#{type}",[emit_value(var),emit_value(value)]]
      end

      return instructions
    elsif node.type == :gvasgn
      object_name = node.children[1].children[0].children[1]
      variable_name = node.children[0]

      self.var_objects[variable_name] = object_name

      instructions = []
      OBJECT_STRUCTURES[ self.var_objects[variable_name] ].map do |property,type|
        var = Parser::AST::Node.new(:gvar,[:"#{variable_name}_#{property}"])
        default_value = type == :int ? 0 : 0.0
        value = Parser::AST::Node.new(type,[default_value])
        instructions << [:"set_var_#{type}",[emit_value(var),emit_value(value)]]
      end

      return instructions

    else
      raise "handle global"
    end
  end

  def vars_for_lvar_object(variable_name)
    OBJECT_STRUCTURES[ self.lvar_objects[variable_name] ].map do |property,type|
      Parser::AST::Node.new(:lvar,[:"#{variable_name}_#{property}"])
    end
  end

  def handle_routine_declare(node,args)
    code = []
    code << [:labeldef, args[:export]] if args[:export]
    code << [:labeldef, :"routine_#{args[:name]}"]
    body = transform_node(node.children[1].children[2])
    body = optimise_tail_call(body)
    code += body
    code
  end

  def handle_function_declare(node,args)
    # debugger
    code = []
    code << [:labeldef, args[:export]] if args[:export]
    code << [:labeldef, :"routine_#{args[:name]}"]
    body = transform_node(node.children[1].children[2])
    body = optimise_tail_call(body)
    code += body
    code
  end

  def optimise_tail_call(body)
    # debugger
    body
  end

  ASSIGNMENT_OPERATORS = {
    :cast_int => [],
    :cast_float => [],
    :"=" => ["set","to"],
    :+ => ["add","to"],
    :- => ["sub","from"],
    :* => ["mult","by"],
    :/ => ["div","by"],
  }
  def emit_operator_assign(node,operator = nil,left = nil, right = nil)

    if !left && !right
      if node.children.size == 3 && ASSIGNMENT_OPERATORS[ node.children[1] ]
        left = node.children[0]
        left_value = nil

        right = node.children[2]
        right_value = nil

        operator = node.children[1]
      elsif node.children.size == 2
        left = node
        left_type = node.type
        right = node.children[1]
        right_type = right.type
        operator = :"="
      elsif node.children[1] == :[]=
        array_name = node.children[0].children[0]
        if array_def = self.lvar_arrays[array_name]
          array_type = array_def[3] == :int32 ? :int : :float
          left = emit_value(node)
          right = emit_value(node.children[3])
          return [[ :"set_lvar_#{array_type}" , [ left , right ] ]]
        elsif array_def = self.var_arrays[array_name]
          array_type = array_def[3] == :int32 ? :int : :float
          left = emit_value(node)
          right = emit_value(node.children[3])
          return [[ :"set_var_#{array_type}" , [ left , right ] ]]
        end
      elsif node.type == :send && node.children[2].type == :send && self.lvar_objects[ node.children[0].children[0] ]
        # property assign
        left_variable_name = node.children[0].children[0]
        left = node
        left_object_type = self.lvar_objects[ left_variable_name ]
        left_property = node.children[1].to_s.gsub(/=/,'').to_sym
        left_property_type = OBJECT_STRUCTURES[left_object_type][left_property]
        right = node.children[2]
        if right.children[0].type == :lvar && self.lvar_objects[ right.children[0].children[0] ]
          right_variable_name = right.children[0].children[0]
          right_object_type = self.lvar_objects[ right_variable_name ]
          right_property = node.children[1].to_s.gsub(/=/,'').to_sym
          return [[ :"set_lvar_#{left_property_type}" , [ emit_value(left) , emit_value(right) ] ]]
        elsif right.type == :gvar && self.lvar_objects[ right.children[0].children[0] ]
          debugger
        end
      else
        debugger
        raise "dunno???"
      end
    end
    left_type ||= left.type
    right_type ||= right.type


    prefix,middle = *ASSIGNMENT_OPERATORS[ operator ]

    opcode_name = "#{prefix}_"

    if right_type == :int || right_type == :float
      opcode_name << "val"
      right_value = emit_value(right)
    elsif right_type == :lvar
      right_var_type = self.lvar_names_to_types[ right.children[0] ]
      if operator == :"="
        opcode_name << "lvar_#{right_var_type}"
      else
        opcode_name << "#{right_var_type}_lvar"
      end
      right_value = lvar(right.children[0],right_var_type)
    elsif right_type == :gvar
      right_var_type = self.gvar_names_to_types[ right.children[0] ]
      debugger
      if operator == :"="
        opcode_name << "var_#{right_var_type}"
      else
        opcode_name << "#{right_var_type}_var"
      end
      right_value = gvar(right.children[0],right_var_type)
    elsif right_type == :const
      opcode_name << "val"
      right_var_type = self.constants_to_types[ right.children[1] ]
      right_type = right_var_type
      right_value = self.constants_to_values[ right.children[1] ]
    elsif node.children[2].andand.type == :send && node.children[2].children[0].andand.type == :lvar && self.lvar_objects[ node.children[2].children[0].children[0] ]
      variable_name = node.children[2].children[0].children[0]
      object_type = self.lvar_objects[ variable_name ]
      property = node.children[2].children[1]
      property_type = OBJECT_STRUCTURES[object_type][property]

      left_value = lvar(node.children[0].children[0], property_type)
      left_var_type = property_type

      right_value = lvar(:"#{variable_name}_#{property}", property_type)
      right_var_type = property_type
      opcode_name << "#{right_var_type}_lvar"
    else
      debugger
      raise "unknown right type #{node.inspect}"
    end

    opcode_name << "_#{middle}_"

    if left_type == :lvasgn
      if operator == :"="
        left_value = lvar(left.children[0],right_var_type)
      else
        left_value = lvar(left.children[0])
      end
      left_var_type = self.lvar_names_to_types[ left.children[0] ]

      if !left_var_type
        left_var_type = right.type
      end

      if operator == :"=" && right_type != :float && right_type != :int
        left_var_type = self.lvar_names_to_types[ right.children[0] ]
        opcode_name << "lvar_#{left_var_type}"
      else
        opcode_name << "#{left_var_type}_lvar"
      end

      if !left_var_type
        debugger
        raise "no type for #{right.children[0]}"
      end

      if left_var_type && ![:lvar,:send].include?(right_type) && left_var_type != right_type
        debugger
        raise "variable type mismatch (already declared as #{left_var_type}, assigning as #{right_type})"
      end
    elsif left_type == :gvasgn
      # debugger
      node

      if operator == :"="
        left_value = gvar(left.children[0],right_var_type)
      else
        left_value = gvar(left.children[0])
      end
      # left_var_type = self.lvar_names_to_types[ left.children[0] ]

      if !left_var_type
        left_var_type = right.type
      end

      if operator == :"="
        if node.children[1].type == :lvar
          left_var_type = self.lvar_names_to_types[ right.children[0] ]
        else
          left_var_type = self.gvar_names_to_types[ right.children[0] ]          
        end
        # debugger
        opcode_name << "var_#{left_var_type}"
      else
        opcode_name << "#{left_var_type}_var"
      end
    elsif node.children[0].type == :send && node.children[0].children[0].type == :lvar
      variable_name = node.children[0].children[0].children[0]
      property = node.children[0].children[1]
      if object_type = self.lvar_objects[ variable_name ]
        left_type = OBJECT_STRUCTURES[object_type][property]
        opcode_name << "#{left_type}_lvar"
        var = Parser::AST::Node.new(:lvar,[:"#{variable_name}_#{property}"])
        left_value = emit_value(var)
      else
        raise "no object for lvar"
      end
    else
      debugger
      raise "can only handle lvasgn left hands8"
    end

    # HORRIBLE HACK:
    # when assigning cross-scope (ie. setting global var to local var)
    # the opcode names are all fucked-up
    # so use regexes to fix it (???!!!)
    # debugger
    if operator == :"*" || operator == :"/"
      # debugger
      opcode_name.gsub!(/([a-z]+)_(val)_([a-z]+)_((int|float)_l?var)/,"\\1_\\4_\\3_\\2")
    # elsif operator == :"="
    #   debugger;
    #   'sdf'
    else
      opcode_name.gsub!(/([a-z]+)_(l?var_(int|float))_([a-z]+)_(l?var_(int|float))/,"\\1_\\5_\\4_\\2")
    end

    # debugger
    return [[ opcode_name.to_sym , [left_value,right_value] ]]

  end

  def assign_temp_var(var_node)
    $ruby_to_scm_compiler_temp_var_slot ||= 0
    $ruby_to_scm_compiler_temp_var_slot  +=  1

    original_var_name = var_node.children[0]

    gvar_name = :"_temp_#{original_var_name}_#{$ruby_to_scm_compiler_temp_var_slot.to_s.rjust(4,"0")}"
    self.temp_var_assignments[original_var_name] = [:var,gvar_name]

    gvar_node = Parser::AST::Node.new(:gvasgn,[gvar_name,var_node.children[1]])
    transform_node(gvar_node)
  end

  attr_accessor :emit_opcode_call_callback
  def emit_opcode_call(node,force_not = false)
    if node.children[1] == :!
      force_not = true
      node = node.children[0]
    end

    opcode_name = node.children[1]

    if method_label = self.local_method_names_to_labels["#{opcode_name}"]
      [[:gosub,[[self.label_type,method_label]]]]
    elsif function_params = self.function_definitions["#{opcode_name}"]
      debugger

    elsif node.type == :send && node.children[1] == :temp
      # temp foo = 1
      [assign_temp_var(node.children[2]).andand[0]]
    else
      opcode_def = self.scm.opcodes[ opcode_name.to_s.upcase ]

      if node.children[1] == :[]=
        debugger
        args = [ emit_value(node) ]
        opcode_name = node.children[3].children[1]
        opcode_def = self.scm.opcodes[ opcode_name.to_s.upcase ]
      else
        # args = node.children[2..-1]
        args = []
        o_args = node.children[2..-1] || []
        o_args.each {|a|
          variable_name = a.children[0]
          if a.type == :lvar && self.lvar_objects[ variable_name ]
            OBJECT_STRUCTURES[ self.lvar_objects[variable_name] ].map do |property,type|
              var = Parser::AST::Node.new(:lvar,[:"#{variable_name}_#{property}"])
              args << emit_value(var)
            end
          else
            args << emit_value(a)
          end
        }
      end

      # if args.nil? || opcode_def.arguments.nil?
      #   debugger
      # end

      if self.emit_opcode_call_callback
        self.emit_opcode_call_callback.call(opcode_def,opcode_name,args)
      end

      if !opcode_def
        debugger
        raise UnknownOpcodeError.new(node,name: opcode_name)
      end

      if opcode_name == :start_new_script || opcode_name == :start_new_streamed_script
        args << [:end_var_args]
      else

        if args.size != opcode_def.arguments.size
          raise IncorrectArgumentCount, "opcode #{opcode_name} expects #{opcode_def.arguments.size} args, got #{args.size}"
        end

      end

      if force_not
        opcode_name = :"not_#{opcode_name}"
      end

      args = nil if args.size == 0
      [[opcode_name,args].compact]
    end
  end

  def emit_cast_opcode_call(node)
    opcode_name = "cset_"

    case node.children[1].children[1]
    when :to_i
      left_type = :int
      right_type = :float
    when :to_f
      left_type = :float
      right_type = :int
    else
      raise "unknown cast!"
    end
    
    if node.type == :lvasgn
      left_value = lvar(node.children[0],left_type)
      opcode_name << "lvar_#{left_type}_"
    else
      raise "can only handle lvasng"
    end

    opcode_name << "to_"

    if node.children[1].children[0].type == :lvar
      right_value = lvar(node.children[1].children[0].children[0])
      opcode_name << "lvar_#{right_type}"

    else
      raise "can only handle lvars"
    end

    [opcode_name.to_sym,[left_value,right_value]]
  end

  def emit_assignment_opcode_call(opcode_call_node,variable_node,assign_type = nil)
    opcode_name = opcode_call_node.children[1]
    opcode_def = self.scm.opcodes[ opcode_name.to_s.upcase ]

    if opcode_call_node.children[0].is_a?(Parser::AST::Node) && [:gvar,:lvar].include?(opcode_call_node.children[0].type) && [:to_i,:to_f].include?(opcode_call_node.children[1])
      return emit_cast_opcode_call(variable_node)
    end

    # debugger

    # multi assign
    if variable_node.is_a?(Parser::AST::Node) && variable_node.type == :mlhs
      args = opcode_call_node.children[2..-1] || []
      args.map! {|a| emit_value(a)}

      variable_node.children.each_with_index do |arg,i|
        arg_def = opcode_def.arguments[i]
        if arg.type == :lvasgn
          # args << lvar( arg.children[0] , arg_def[:type] )
          args << lvar( arg.children[0] , nil )
        elsif arg.type == :gvasgn
          # args << gvar( arg.children[0] , arg_def[:type] )
          args << gvar( arg.children[0] , nil )
        else
          raise "can only handle lvar assigns #{variable_node.inspect}"
        end
      end
    else
      # global assign
      if variable_node.is_a?(Symbol) && variable_node.to_s[0] == "$"
        # UNTESTED
        args = []
        args << gvar(variable_node.to_s.gsub('$',''))
        args << emit_value(opcode_call_node)
      else
        args = []
        o_args = opcode_call_node.children[2..-1] || []
        o_args.each {|a|
          variable_name = a.children[0]
          if a.type == :lvar && self.lvar_objects[ variable_name ]
            OBJECT_STRUCTURES[ self.lvar_objects[variable_name] ].map do |property,type|
              var = Parser::AST::Node.new(:lvar,[:"#{variable_name}_#{property}"])
              args << emit_value(var)
            end
          else
            args << emit_value(a)
          end
        }

        # expand lvar objects
        if variable_node.type == :lvasgn && self.lvar_objects[ variable_node.children[0] ]
          variable_name = variable_node.children[0]
          OBJECT_STRUCTURES[ self.lvar_objects[variable_name] ].map do |property,type|
            var = Parser::AST::Node.new(:lvar,[:"#{variable_name}_#{property}"])
            args << emit_value(var)
          end
        # single assign from object property
        elsif variable_node.type == :lvasgn && variable_node.children[1].type == :send && variable_node.children[1].children[0].andand.type == :lvar && self.lvar_objects[ variable_node.children[1].children[0].children[0] ]
          variable_name = variable_node.children[1].children[0].children[0]
          object_type = self.lvar_objects[ variable_name ]
          property = variable_node.children[1].children[1]
          property_type = OBJECT_STRUCTURES[object_type][property]

          opcode_name = "set_"

          left_type = property_type
          args << lvar(variable_node.children[0],left_type)
          opcode_name << "lvar_#{left_type}"

          opcode_name << "_to_"

          opcode_name << "lvar_#{left_type}"
          args << lvar(:"#{variable_name}_#{property}",left_type)

        # array assign
        elsif variable_node.children[1] == :[]=

          if variable_node.children[0].type == :gvar
            args << emit_value(variable_node)
          else
            args << emit_value(variable_node)
          end

        elsif variable_node.children[1].type == :send && variable_node.children[1].children[1] == :[]

          array_name = variable_node.children[1].children[0].children[0]

          if array_def = self.lvar_arrays[array_name]
            array_type = array_def[3] == :int32 ? :int : :float32
            opcode_name = :"set_lvar_#{array_type}"
            opcode_def = self.scm.opcodes[ opcode_name.to_s.upcase ]
            args << emit_value( variable_node.children[1] )
          elsif array_def = self.var_arrays[array_name]
            array_type = array_def[3] == :int32 ? :int : :float32
            opcode_name = :"set_var_#{array_type}"
            opcode_def = self.scm.opcodes[ opcode_name.to_s.upcase ]
            args << emit_value( variable_node.children[1] )
          end

        else

          if assign_type == :gvasgn
            args << gvar(variable_node.to_s.gsub('$',''))
          else
            if !variable_node.children or !opcode_def.andand.arguments.andand.last
              debugger
              "ff"
            end
            args << lvar( variable_node.children[0] , opcode_def.arguments.last[:type] )
          end

        end
      end
    end

    opcode_def = self.scm.opcodes[ opcode_name.to_s.upcase ]
    if !opcode_def
      debugger
    end

    if args.size != opcode_def.arguments.size
      raise IncorrectArgumentCount, "opcode #{opcode_name} expects #{opcode_def.arguments.size} args, got #{args.size}"
    end

    if args.size == 0
      return [ opcode_name.to_sym ]
    else
      return [ opcode_name.to_sym, args ].compact
    end
  end

  COMPARISON_OPERATORS = {
    :"==" => [nil,"equal_to"],
    :"!=" => ["not_","equal_to"],
    :>=  => [nil,"greater_or_equal_to"],
    :>  => [nil,"greater_than"],
    :<=  => ["not_","greater_than"],
    :<  => ["not_","greater_or_equal_to"]
  }
  def emit_conditional_opcode_call(node)
    if node.children.size == 3
      if COMPARISON_OPERATORS[ node.children[1] ]
        left_type = node.children[0].type
        left_value = nil
        right_type = node.children[2].type
        right_value = nil

        not_operator,sign_operator = *COMPARISON_OPERATORS[ node.children[1] ]

        opcode_name = "#{not_operator}is_"

        if node.type == :send && node.children[0].type == :send && node.children[0].children[1] == :[]
          if node.children[0].children[0].type == :gvar
            # gvar array compare
            array_name = node.children[0].children[0].children[0]
            array_def = self.var_arrays[ array_name ]
            raise "no lvar array #{array_name}" if !array_def
            array_type = array_def[3]
            left_type = :gvar
            left_value = emit_value(node.children[0])
            left_var_type = array_type == :int32 ? :int : :float
          else
            # lvar array compare
            array_name = node.children[0].children[0].children[0]
            array_def = self.lvar_arrays[ array_name ]
            raise "no lvar array #{array_name}" if !array_def
            array_type = array_def[3]
            left_type = :lvar
            left_value = emit_value(node.children[0])
            left_var_type = array_type == :int32 ? :int : :float
          end
        end

        if node.children[0].type == :const && node.children[0].children[1] == :TIMER_A
          left_value = [:lvar, 32, :timer_a]
          left_var_type = :int
          left_type = :lvar
          opcode_name << "#{left_var_type}_lvar"
        elsif node.children[0].type == :const && node.children[0].children[1] == :TIMER_B
          left_value = [:lvar, 33, :timer_b]
          left_var_type = :int
          left_type = :lvar
          opcode_name << "#{left_var_type}_lvar"
        elsif left_type == :lvar
          left_value ||= lvar(node.children[0].children[0])
          left_var_type ||= self.lvar_names_to_types[ node.children[0].children[0] ]
          raise "can't find type for #{node.children[0].children[0]}" if !left_var_type
          opcode_name << "#{left_var_type}_lvar"
        elsif left_type == :gvar
          left_value ||= gvar(node.children[0].children[0])
          # left_var_type = self.gvar_names_to_types[ node.children[0].children[0] ]
          # raise "can't find type for #{node.children[0].children[0]}" if !left_var_type
          left_var_type ||= :int
          opcode_name << "#{left_var_type}_var"          
        else
          debugger
          raise "can only handle lvars on left side #{node.inspect}"
        end

        opcode_name << "_#{sign_operator}_"

        if node.children[1] == :> && node.children[0].children[0] == :angle
          # debugger
          node
        end

        if right_type == :true || right_type == :false || right_type == :nil
          right_type = :int
        end

        if right_type == :int || right_type == :float
          opcode_name << "number"
          right_value = emit_value(node.children[2])
        elsif right_type == :lvar
          right_var_type = self.lvar_names_to_types[ node.children[2].children[0] ]
          opcode_name << "#{right_var_type}_lvar"
          right_value = lvar(node.children[2].children[0])
        elsif right_type == :gvar
          right_var_type = :int # FIXME: look up correct type
          opcode_name << "#{right_var_type}_var"
          right_value = gvar(node.children[2].children[0])
        elsif right_type == :const
          opcode_name << "number"
          right_var_type = self.constants_to_types[ node.children[2].children[1] ]
          right_value = self.constants_to_values[ node.children[2].children[1] ]
        else
          raise "unknown right type #{node.inspect}"
        end

        return [[opcode_name.to_sym,[left_value,right_value]]]
      elsif node.children[1].is_a?(Symbol)
        return emit_opcode_call(node)
      end
    elsif node.children.size == 2
      if node.type == :send
        return emit_opcode_call(node)
      elsif label = self.local_method_names_to_labels["#{node.children[1]}"]
        return [[:gosub,[[self.label_type,label]]]]
      elsif node.children[0] && node.children[0].type == :send
        # negated opcode call
        return emit_opcode_call(node.children[0],node.children[1] == :!)
      # elsif node.children[1].is_a?(Symbol)
      #   return emit_opcode_call(node)
      else
        debugger
        raise "??? #{node.inspect}"
      end
    elsif node.children.size >= 4 && node.children[1].is_a?(Symbol)
      return emit_opcode_call(node)
    else
      debugger
      node
    end

  end

  # BREAKPOINT_PC = 56531
  def emit_breakpoint(node)
    label = generate_label!
    
    context_lines = 5
    start_line = node.loc.line - context_lines
    end_line = node.loc.line + context_lines
    source_context = node.loc.expression.source_buffer.source.lines[ (start_line)...(end_line) ]

    [
      # [:set_var_int,[[:dmavar,4492],[:label,label]]],
      [:Metadata,[ :source_context, source_context], [:start_line, start_line+1], [:filename, self.metadata[:filename] ]],
      [:gosub,[[:label, :debug_breakpoint_entry]]],
      [:labeldef,label]
    ]
  end

  def emit_raw(node)
    args = []
    args << node.children[2].children[0]
    args << node.children[3].children.map{|n| n.children[0]}
    [args]
  end

  def emit_if(node)

    andor_id, conditions = *emit_if_conditions( node.children[0] )

    andor = self.andor_instruction(andor_id)

    # TODO: handle bool check of variable `if var` (node.children[0].type == :lvar)

    if [:send,:and,:or].include?(node.children[0].type) && [:begin,:send,:if,:op_asgn,:lvasgn,:gvasgn,:break,:masgn].include?(node.children[1].type) && node.children[2].nil? # if/end
      false_label = generate_label!
      [
        *andor,
        *conditions,
        [:goto_if_false,[[self.label_type, false_label]]],
        *transform_node(node.children[1]),
        [:labeldef, false_label]
      ]
    elsif node.children.size == 3 && node.children[2].nil?
      debugger;
      node
    elsif node.children.size == 3 # if/else/end
      # true_label = generate_label!
      false_label = generate_label!
      end_label = generate_label!
      [
        *andor,
        *conditions,
        [:goto_if_false,[[self.label_type, false_label]]],
        *transform_node(node.children[1]),
        [:goto,[[self.label_type,end_label]]],
        [:labeldef, false_label],
        *transform_node(node.children[2]),
        [:labeldef, end_label]
      ]

    end
  end

  def emit_value(node)
    debugger if node.is_a?(Symbol)
    case node.type
    when :float
      [:float32,node.children[0]]
    when :int
      int = node.children[0]
      if int >= -128 && int <= 127
        [:int8,int]
      elsif int >= -32768 && int <= 32767
        [:int16,int]
      else
        [:int32,int]
      end
    when :str
      if node.children[0].size <= 7
        [:string8,node.children[0]]
      # TEST: does this work? probs not??
      elsif node.children[0].size <= 15
        [:string16,node.children[0]]
      end
      # [:vlstring,node.children[0].size,node.children[0]]
    when :lvar
      if temp_var = self.temp_var_assignments[ node.children[0] ]
        temp_var
      else
        lvar(node.children[0])
      end
    when :gvar
      name = node.children[0].to_s.gsub(%r(^\$),'')
      if matches = name.match(%r(^_(\d+)_?(.*)?))
        [:dmavar, matches[1].to_i, matches[2].present? ? matches[2].to_sym : nil ].compact
      elsif matches = name.match(%r(^str_(\d+)))
        [:var_string8, matches[1].to_i]
      elsif matches = name.match(%r(^str8_(\d+)))
        [:var_string8, matches[1].to_i]
      # TEST: does this work?
      elsif matches = name.match(%r(^str16_(\d+)))
        [:var_string16, matches[1].to_i]
      else
        gvar(name)
      end
    when :const
      self.constants_to_values[ node.children[1] ]
    when :send
      if node.children[1] == :[] || node.children[1] == :[]=
        array_type = node.children[0].type == :gvar ? :var_array : :lvar_array
        array_var = node.children[0]
        index_type = node.children[2].type == :gvar ? :var : :lvar
        index_var = node.children[2]
        # debugger
        if array_type == :var_array && (array_def = self.var_arrays[ node.children[0].children[0] ])
          [ :var_array , emit_value(array_var)[1] , emit_value(index_var)[1] , array_def[2] , [ array_def[3] , index_type] ]
        elsif array_var.type == :send && array_var.children[1] == :_0
          [ :lvar_array , 0 , emit_value(index_var)[1] , 0 , [ :int32 , index_type] ]
        elsif array_var.type == :gvar && array_var.children[0] == :$_0
          [ :var_array , 0 , emit_value(index_var)[1] , 0 , [ :int32 , index_type] ]
        elsif array_type == :lvar_array && (array_def = self.lvar_arrays[ node.children[0].children[0] ])
          # debugger
          [ :lvar_array , emit_value(array_var)[1] , emit_value(index_var)[1] , array_def[2] , [ array_def[3] , index_type] ]
        else
          debugger
          raise "undefined array #{node.inspect}"
        end
      # property access
      elsif node.children[0].andand.type == :lvar && node.children[1].is_a?(Symbol)
        variable_name = :"#{node.children[0].children[0]}_#{node.children[1].to_s.gsub(/=/,'')}"
        lvar(variable_name)
      # property access
      elsif node.children[0].andand.type == :gvar && node.children[1].is_a?(Symbol)
        variable_name = :"#{node.children[0].children[0]}_#{node.children[1].to_s.gsub(/=/,'')}"
        gvar(variable_name)
      else
        debugger
        raise "emit_value ??? #{node.inspect}"
      end
    when :true
      [:int8, 1]
    when :false
      [:int8, 0]
    when :nil
      [:int8, -1]
    else
      debugger
      raise "emit_value ??? #{node.inspect}"
    end
  end

  def emit_if_conditions(node,parent_condition_type = nil)
    case node.type
    when :and, :or
      if parent_condition_type
        if node.type != parent_condition_type
          raise InvalidConditionalLogicalOperatorUse, "cannot mix AND/OR in one IF statement"
        end
      else
        andor_id = node.type == :and ? 0 : 20
      end

      conditions = node.children.map do |condition_node|
        case condition_node.type
        when :and, :or
          emit_if_conditions(condition_node,node.type)
        when :send
          emit_conditional_opcode_call(condition_node)[0]
        else
          debugger
          raise "dunno what sort of condition node is"
        end
      end

      if conditions[0].is_a?(Array) && !conditions[0][0].is_a?(Symbol)
        conditions = [*conditions[0],conditions[1]]
      end

      if parent_condition_type
        conditions
      else
        andor_id += (conditions.size - 1)
        [andor_id,conditions]
      end
    when :send
      [ 0, emit_conditional_opcode_call(node) ]
    end
  end

  attr_accessor :generate_label_counter
  def generate_label!(name = nil)
    if name
      return name
    else
      self.generate_label_counter ||= 0
      self.generate_label_counter += 1
      :"#{self.label_prefix}#{self.generate_label_counter}"
    end
  end

  attr_accessor :lvar_names_to_types
  attr_accessor :lvar_names_to_ids
  attr_accessor :generate_lvar_counter
  def lvar(name,type = nil)
    self.lvar_names_to_types ||= {}
    self.lvar_names_to_ids ||= {}
    self.generate_lvar_counter ||= -1

    if name.is_a?(Parser::AST::Node)
      name = name.children[0]
    end

    # if name.to_sym == :coords
    #   debugger
    # end

    id = if self.lvar_names_to_ids[name]
      if type && self.lvar_names_to_types[name] && type != self.lvar_names_to_types[name]
        debugger
        raise "mismatched type for #{name} (already defined as #{self.lvar_names_to_types[name]}, used as #{type}}"
      end
      self.lvar_names_to_ids[name]
    else
      self.generate_lvar_counter += 1

      if type == :string
        # skip one extra var for string8 (2 vars worth)
        self.generate_lvar_counter += 1
      end

      if self.generate_lvar_counter >= 32
        raise "Out of local vars (tried to allocate `#{name}` to lvar #{self.generate_lvar_counter})"
      end

      self.lvar_names_to_ids[name] = self.generate_lvar_counter

      # reserve space for array vars
      # if array_def = self.lvar_arrays[name]
      #   self.generate_lvar_counter += array_def[2] - 1
      # end

      if type
        self.lvar_names_to_types[name] = type
      end

      self.lvar_names_to_ids[name]
    end

    type ||= self.lvar_names_to_types[name]

    # debugger
    if type == :string
      [:lvar_string8, id, name]
    else
      [:lvar, id, name]
    end
  end

  def lvar_array( array_node, index_node )
    
  end

  attr_accessor :gvar_names_to_ids
  attr_accessor :gvar_names_to_types
  attr_accessor :generate_gvar_counter
  def gvar(name,type = nil)
    self.gvar_names_to_ids ||= {}
    self.gvar_names_to_types ||= {}
    self.generate_gvar_counter ||= 4

    name = name.to_s.gsub(/\A\$/,'').to_sym

    # debugger
    if matches = name.to_s.match(/\A_(\d+)_?(.*)?/)
      return [:dmavar, matches[1].to_i, matches[2].present? ? matches[2].to_sym : nil ].compact
    end

    id = if self.gvar_names_to_ids[name]
      self.gvar_names_to_ids[name]
    else
      self.generate_gvar_counter += 4

      self.gvar_names_to_ids[name] = self.generate_gvar_counter
      self.gvar_names_to_types[name] = type

      if type == :string
        self.generate_gvar_counter += 4
      end

      self.gvar_names_to_ids[name]
    end

    type ||= self.gvar_names_to_types[name]

    if type == :string
      [:var_string8, name]
    else
      [:var, name]
    end
  end

  def gvar_array( array_node, index_node )

    array_name = array_node.children[0]
    array_name = array_name.to_s.gsub(/\A\$/,'').to_sym

    index_name = index_node.children[0]
    index_name = index_name.to_s.gsub(/\A\$/,'').to_sym

    # if self.var_arrays[array_name]

  end

  def andor_instruction(andor_id)
    # if id == 0, we can omit the andor opcode
    if andor_id == 0
      []
    else
      [ [:andor,[[:int8, andor_id]]] ]
    end
  end


  # ERRORS
  class InputError < ::ArgumentError;
    def initialize(message,original_exception,metadata = nil)
      super(message)
      @message = message
      @original_exception = original_exception
      @metadata = metadata || {}
    end

    def message
      case @original_exception
      when Parser::SyntaxError
        "Parser::SyntaxError - #{@original_exception.message}\n#{self.blame_lines.join("\n")}"
      when GtaScm::RubyToScmCompiler::NodeError
        "#{self.blame_lines.join("\n")}"
      else
        @message
      end
    end

    def blame_lines
      lines = case @original_exception
      when Parser::SyntaxError
        @original_exception.diagnostic.render
      when GtaScm::RubyToScmCompiler::NodeError
        @original_exception.blame_lines
      end
      lines.map{|l| self.replace_filename(l)}
    end

    def replace_filename(str)
      str.gsub(/^(\(string\))\:/m,"#{@metadata[:filename]}:")
    end
  end

  class NodeError < ::ArgumentError;
    def initialize(node,metadata)
      @node = node
      @metadata = metadata
    end

    def blame_lines
      line = @node.loc.line
      column = @node.loc.column
      prefix = "(string):#{line}"

      [
        prefix + ":#{column}: #{self.class.name.gsub(/^GtaScm::RubyToScmCompiler::/,'').gsub(/Error$/,'').gsub(/([a-z])([A-Z])/,'\\1 \\2')}" + (@metadata.size > 0 ? " - "+@metadata.map{|k,v| "#{k}: #{v}"}.join(", ") : ""),
        prefix + @node.loc.expression.source_buffer.source.lines[line-1].chomp,
        prefix + "".ljust(column," ") + "^"
      ]
    end
  end

  class UnhandledNodeError < NodeError; end
  class UnknownOpcodeError < NodeError; end

  class InvalidConditionalLogicalOperatorUse < ::ArgumentError; end
  class IncorrectArgumentCount < ::ArgumentError; end
end
