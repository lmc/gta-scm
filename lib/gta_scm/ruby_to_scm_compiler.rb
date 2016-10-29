
class GtaScm::RubyToScmCompiler

  attr_accessor :scm
  attr_accessor :label_prefix

  def initialize
    self.local_method_names_to_labels = {}
    self.label_prefix = "label_"
  end

  def transform_node(node)
    # debugger
    if !node.respond_to?(:type)
      debugger
      node
    end

    ttt = case node.type

    when :block

      if node.children[0].type == :send && node.children[0].children[1] == :loop
        emit_loop(node,node.children[2])
      else
        raise "unknown block type: #{node.inspect}"
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

      [ emit_assignment_opcode_call(node.children[1],node.children[0],:masgn) ]

    # global var assign
    when :gvasgn

      # [ emit_assignment_opcode_call(node.children[1],node.children[0],:gvasgn) ]
      emit_global_var_assign(node)

    # local var assign
    when :lvasgn

      emit_local_var_assign(node)

    when :casgn

      record_constant_assign(node)
      []

    when :op_asgn

      [ emit_operator_assign(node) ]

    when :if

      emit_if(node)

    when :send

      [ emit_opcode_call(node) ]

    when :break

      [ emit_break(node) ]

    else
      debugger
      raise "unknown node type #{node.type.inspect}"
    end

    puts "transform_node - #{ttt.inspect}"

    ttt
  end

  attr_accessor :loop_stack
  def emit_loop(loop_node,block_node)
    loop_start = generate_label!
    loop_exit = generate_label!

      self.loop_stack ||= []
    begin
      self.loop_stack << {start: loop_start, exit: loop_exit}
      [
        [:labeldef, loop_start],
        *transform_node(block_node),
        [:goto,[[:label,loop_start]]],
        [:labeldef, loop_exit]
      ]
    ensure
      self.loop_stack.pop
    end
  end

  def emit_break(node)
    loop_exit = self.loop_stack.last[:exit]
    return [:goto, [[:label, loop_exit]]]
  end

  def emit_block(node)
    sexps = []
    node.children.each do |c|
      cc = transform_node(c)
      sexps += cc
    end
    sexps
  end

  attr_accessor :local_method_names_to_labels
  def emit_method_def(node)
    # debugger
    method_name = node.children[0]
    # raise "can only handle :args" if node.children[1].type != :args
    method_body = case node.children[1].type
      when :send
      [ emit_opcode_call(node.children[1]) ]
      when :begin
        transform_node(node.children[1])
      when :block
        # debugger
        if node.children[1].children[0].type == :send && node.children[1].children[0].children[1] == :routine
          transform_node(node.children[1].children[2])
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

    [
      [:goto, [[:label, method_end_label]]],
      [:labeldef, method_label],
      *method_body,
      [:return],
      [:labeldef, method_end_label]
    ]
  end

  def emit_local_var_assign(node)
    self.emit_n_var_assign(node,:lvar)
  end

  def emit_global_var_assign(node)
    self.emit_n_var_assign(node,:var)
  end

  def emit_n_var_assign(node,var_type)
    left = node.children[0]
    right = node.children[1]
    right_val = nil

    if right.type == :send
      return [emit_assignment_opcode_call(right, node)]
    end

    type = right.type

    if type == :const
      right_val = self.constants_to_values[ right.children[1] ]
      type = self.constants_to_types[ right.children[1] ]
    end


    # debugger
    if type == :int
      right_val ||= [:int32,node.children[1].children[0]]
      left_var = case var_type
      when :var
        gvar(node.children[0],:int)
      when :lvar
        lvar(node.children[0],:int)
      else
        raise("???")
      end
      return [[:"set_#{var_type}_int" , [left_var , right_val ]]]
    end
    if type == :float
      right_val ||= [:float32,node.children[1].children[0]]
      var = case var_type
      when :var
        gvar(node.children[0],:float)
      when :lvar
        lvar(node.children[0],:float)
      else
        raise("???")
      end
      return [[:"set_#{var_type}_float" , [var , right_val ]]]
    end
    if type == :lvar
      return [emit_operator_assign(node)]
    end
    if type == :block
      nn = emit_method_def(node)
      # debugger
      return nn

    end
    debugger
    raise "unknown lvar assignment #{node.inspect}"
  end

  attr_accessor :constants_to_values
  attr_accessor :constants_to_types
  def record_constant_assign(node)
    self.constants_to_values ||= {}
    self.constants_to_values[ node.children[1] ] = emit_value( node.children[2] )
    self.constants_to_types ||= {}
    self.constants_to_types[ node.children[1] ] = node.children[2].type
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
  def emit_operator_assign(node,operator = nil)
    left,right = nil,nil
    operator ||= nil

    if node.children.size == 3 && ASSIGNMENT_OPERATORS[ node.children[1] ]
      left = node.children[0]
      left_type = left.type
      left_value = nil

      right = node.children[2]
      right_type = right.type
      right_value = nil

      operator = node.children[1]
    elsif node.children.size == 2
      left = node
      left_type = node.type
      right = node.children[1]
      right_type = right.type
      operator = :"="
    else
      raise "dunno???"
    end

    prefix,middle = *ASSIGNMENT_OPERATORS[ operator ]

    opcode_name = "#{prefix}_"

    if right_type == :int || right_type == :float
      opcode_name << "val"
      right_value = emit_value(node.children[2])
    elsif right_type == :lvar
      right_var_type = self.lvar_names_to_types[ right.children[0] ]
      if operator == :"="
        opcode_name << "lvar_#{right_var_type}"
      else
        opcode_name << "#{right_var_type}_lvar"
      end
      right_value = lvar(right.children[0],right_var_type)
    elsif right_type == :const
      opcode_name << "val"
      right_var_type = self.constants_to_types[ right.children[1] ]
      right_type = right_var_type
      right_value = self.constants_to_values[ right.children[1] ]
    else
      raise "unknown right type"
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

      if operator == :"="
        left_var_type = self.lvar_names_to_types[ right.children[0] ]
        opcode_name << "lvar_#{left_var_type}"
      else
        opcode_name << "#{left_var_type}_lvar"
      end

      if !left_var_type
        debugger
        raise "no type for #{right.children[0]}"
      end

      if left_var_type && right_type != :lvar && left_var_type != right_type
        debugger
        raise "variable type mismatch (already declared as #{left_var_type}, assigning as #{right_type})"
      end
    elsif left_type = :gvasgn
      # debugger
      node

      if operator == :"="
        left_value = gvar(left.children[0],right_var_type)
      else
        left_value = gvar(left.children[0])
      end
      # left_var_type = self.lvar_names_to_types[ left.children[0] ]

      # if !left_var_type
      #   left_var_type = right.type
      # end

      if operator == :"="
        left_var_type = self.lvar_names_to_types[ right.children[0] ]
        opcode_name << "var_#{left_var_type}"
      else
        opcode_name << "#{left_var_type}_var"
      end

      # HORRIBLE HACK:
      # when assigning cross-scope (ie. setting global var to local var)
      # the opcode names are all fucked-up
      # so use regexes to fix it (???!!!)
      opcode_name.gsub!(/([a-z]+)_(l?var_(int|float))_([a-z]+)_(l?var_(int|float))/,"\\1_\\5_\\4_\\2")
    else
      raise "can only handle lvasgn left hands8"
    end

    return [ opcode_name.to_sym , [left_value,right_value] ]

  end

  def emit_opcode_call(node,force_not = false)
    opcode_name = node.children[1]

    if method_label = self.local_method_names_to_labels["#{opcode_name}"]
      [:gosub,[[:label,method_label]]]
    else
      opcode_def = self.scm.opcodes[ opcode_name.to_s.upcase ]

      args = node.children[2..-1]
      args.map! {|a| emit_value(a)}

      # if args.nil? || opcode_def.arguments.nil?
      #   debugger
      # end

      if !opcode_def
        debugger
      end

      if args.size != opcode_def.arguments.size
        raise IncorrectArgumentCount, "opcode #{opcode_name} expects #{opcode_def.arguments.size} args, got #{args.size}"
      end

      if force_not
        opcode_name = :"not_#{opcode_name}"
      end

      args = nil if args.size == 0
      [opcode_name,args].compact
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
      args = opcode_call_node.children[2..-1]
      args.map! {|a| emit_value(a)}

      variable_node.children.each_with_index do |arg,i|
        arg_def = opcode_def.arguments[i]
        if arg.type == :lvasgn
          args << lvar( arg.children[0] , arg_def[:type] )
        else
          raise "can only handle lvar assigns"
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
        args = opcode_call_node.children[2..-1]
        args.map! {|a| emit_value(a)}
        if assign_type == :gvasgn
          args << gvar(variable_node.to_s.gsub('$',''))
        else
          args << lvar( variable_node.children[0] , opcode_def.arguments.last[:type] )
        end
      end
    end

    if args.size != opcode_def.arguments.size
      raise IncorrectArgumentCount, "opcode #{opcode_name} expects #{opcode_def.arguments.size} args, got #{args.size}"
    end

    if args.size == 0
      return [ opcode_name ]
    else
      return [ opcode_name, args ].compact
    end
  end

  COMPARISON_OPERATORS = {
    :"==" => [nil,"equal_to"],
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

        if left_type == :lvar
          left_value = lvar(node.children[0].children[0])
          left_var_type = self.lvar_names_to_types[ node.children[0].children[0] ]
          raise "can't find type for #{node.children[0].children[0]}" if !left_var_type
          opcode_name << "#{left_var_type}_lvar"
        else
          raise "can only handle lvars on left side"
        end

        opcode_name << "_#{sign_operator}_"

        if node.children[1] == :> && node.children[0].children[0] == :angle
          # debugger
          node
        end

        if right_type == :int || right_type == :float
          opcode_name << "number"
          right_value = emit_value(node.children[2])
        elsif right_type == :lvar
          right_var_type = self.lvar_names_to_types[ node.children[2].children[0] ]
          opcode_name << "#{right_var_type}_lvar"
          right_value = lvar(node.children[2].children[0])
        elsif right_type == :const
          opcode_name << "number"
          right_var_type = self.constants_to_types[ node.children[2].children[1] ]
          right_value = self.constants_to_values[ node.children[2].children[1] ]
        else
          raise "unknown right type"
        end

        return [opcode_name.to_sym,[left_value,right_value]]
      elsif node.children[1].is_a?(Symbol)
        return emit_opcode_call(node)
      end
    elsif node.children.size == 2
      if node.children[0].type == :send && node.children[1] == :!
        # negated opcode call
        return emit_opcode_call(node.children[0],true)
      # elsif node.children[1].is_a?(Symbol)
      #   return emit_opcode_call(node)
      else
        raise "???"
      end
    elsif node.children.size == 4 && node.children[1].is_a?(Symbol)
      return emit_opcode_call(node)
    else
      debugger
      node
    end

  end

  def emit_if(node)

    andor_id, conditions = *emit_if_conditions( node.children[0] )

    if node.children[0].type == :send && [:begin,:send,:if,:op_asgn,:lvasgn,:break].include?(node.children[1].type) && node.children[2].nil? # if/end
      false_label = generate_label!
      [
        [:andor,[[:int8, andor_id]]],
        *conditions,
        [:goto_if_false,[[:label, false_label]]],
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
        [:andor,[[:int8, andor_id]]],
        *conditions,
        [:goto_if_false,[[:label, false_label]]],
        *transform_node(node.children[1]),
        [:goto,[[:label,end_label]]],
        [:labeldef, false_label],
        *transform_node(node.children[2]),
        [:labeldef, end_label]
      ]

    end
  end

  def emit_value(node)
    case node.type
    when :int, :float
      type = {int: :int32, float: :float32}[node.type]
      [type,node.children[0]]
    when :lvar
      lvar(node.children[0])
    when :gvar
      name = node.children[0].to_s.gsub(%r(^\$),'')
      if matches = name.match(%r(^_(\d+)))
        [:dmavar, matches[1].to_i]
      else
        gvar(name)
      end
    else
      debugger
      raise "emit_value ??? #{node.inspect}"
    end
  end

  def emit_if_conditions(node)
    case node.type
    when :and, :or
      andor_id = node.type == :and ? 0 : 20

      conditions = node.children.map do |condition_node|
        case condition_node.type
        when :and, :or
          raise InvalidConditionalLogicalOperatorUse, "cannot mix AND/OR in one IF statement"
        when :send
          emit_conditional_opcode_call(condition_node)
        else
          debugger
          raise "dunno what sort of condition node is"
        end
      end

      andor_id += (conditions.size - 1)
      [andor_id,conditions]
    when :send
      [ 0, [emit_conditional_opcode_call(node)] ]
    end
  end

  attr_accessor :generate_label_counter
  def generate_label!
    self.generate_label_counter ||= 0
    self.generate_label_counter += 1
    :"#{self.label_prefix}#{self.generate_label_counter}"
  end

  attr_accessor :lvar_names_to_types
  attr_accessor :lvar_names_to_ids
  attr_accessor :generate_lvar_counter
  def lvar(name,type = nil)
    self.lvar_names_to_types ||= {}
    self.lvar_names_to_ids ||= {}
    self.generate_lvar_counter ||= -1

    id = if self.lvar_names_to_ids[name]
      if type && self.lvar_names_to_types[name] && type != self.lvar_names_to_types[name]
        debugger
        raise "mismatched type for #{name} (already defined as #{self.lvar_names_to_types[name]}, used as #{type}}"
      end
      self.lvar_names_to_ids[name]
    else
      self.generate_lvar_counter += 1
      self.lvar_names_to_ids[name] = self.generate_lvar_counter
      if type
        self.lvar_names_to_types[name] = type
      end
      self.lvar_names_to_ids[name]
    end
    [:lvar, id, name]
  end

  attr_accessor :gvar_names_to_ids
  attr_accessor :generate_gvar_counter
  def gvar(name,type = nil)
    self.gvar_names_to_ids ||= {}
    self.generate_gvar_counter ||= 4

    name = name.to_s.gsub(/\A\$/,'').to_sym
    id = if self.gvar_names_to_ids[name]
      self.gvar_names_to_ids[name]
    else
      self.generate_gvar_counter += 4
      self.gvar_names_to_ids[name] = self.generate_gvar_counter

      self.gvar_names_to_ids[name]
    end
    [:var, name]
  end


  # ERRORS

  class InvalidConditionalLogicalOperatorUse < ::ArgumentError; end
  class IncorrectArgumentCount < ::ArgumentError; end
end