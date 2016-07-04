module GtaScm::Assembler
end

# /Users/barry/Library/Application Support/Steam/SteamApps/common/grand theft auto - vice city/Grand Theft Auto - Vice City.app/Contents/Resources/transgaming/c_drive/Program Files/Rockstar Games/Grand Theft Auto Vice City

class GtaScm::Assembler::Base
  attr_accessor :input_dir

  attr_accessor :parser
  attr_accessor :nodes

  attr_accessor :touchup_defines
  attr_accessor :touchup_uses

  def initialize(input_dir)
    self.input_dir = input_dir
    self.nodes = GtaScm::UnbuiltNodeSet.new

    self.touchup_defines = {}
    self.touchup_uses = Hash.new { |h,k| h[k] = [] }
  end

  def assemble(scm,out_path)
    
  end

end

class GtaScm::Assembler::Sexp < GtaScm::Assembler::Base
  def assemble(scm,out_path)
    parser = Elparser::Parser.new
    File.read("#{self.input_dir}/main.sexp.erl").each_line.each_with_index do |line,idx|
      if line.present? and line[0] == "("# and idx < 30
        offset = nodes.next_offset
        tokens = parser.parse1(line).to_ruby
        logger.notice tokens.inspect
        # TODO: we can calculate offset + lengths here as we go
        node = case tokens[0]
          when :HeaderVariables
            GtaScm::Node::Header::Variables.new.tap do |node|
              node.offset = offset

              node[0] = self.assemble_instruction(scm,offset,[:goto,[[:label,:label__post_header_variables]]])
              self.use_touchup(node.offset,[0,1,0,1],:label__post_header_variables)

              node[1][0] = GtaScm::Node::Raw.new([tokens[1][1]])
              node[1][1] = GtaScm::Node::Raw.new([0] * tokens[2][1])

              self.define_touchup(:label__post_header_variables,nodes.next_offset(node))
            end
          when :HeaderModels
            GtaScm::Node::Header::Models.new.tap do |node|
              node.offset = offset

              node[0] = self.assemble_instruction(scm,offset,[:goto,[[:label,:label__post_header_models]]])
              self.use_touchup(node.offset,[0,1,0,1],:label__post_header_models)

              node[1][0] = GtaScm::Node::Raw.new([tokens[1][1]])

              # model_count = tokens[3].size
              model_count = tokens[2][1]
              node[1][1] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin(model_count,:int32).bytes )

              node[1][2] = GtaScm::ByteArray.new
              tokens[3].each do |model|
                node[1][2] = GtaScm::Node::Raw.new( (model[1][1].ljust(23,"\000")+"\000")[0..24].bytes )
              end

              self.define_touchup(:label__post_header_models,nodes.next_offset(node))
            end
          when :HeaderMissions
            GtaScm::Node::Header::Missions.new.tap do |node|
              node.offset = offset

              node[0] = self.assemble_instruction(scm,offset,[:goto,[[:label,:label__post_header_missions]]])
              self.use_touchup(node.offset,[0,1,0,1],:label__post_header_missions)

              # padding
              node[1][0] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( tokens[1][1] , :int8 ).bytes )

              # main size
              node[1][1] = GtaScm::Node::Raw.new( [0xBB,0xBB,0xBB,0xBB] )
              self.use_touchup(offset,[1,1],:_main_size)

              # largest mission size
              node[1][2] = GtaScm::Node::Raw.new( [0xBB,0xBB,0xBB,0xBB] )
              self.use_touchup(offset,[1,2],:_largest_mission_size)

              # total missions
              mission_count = tokens[4][1]
              node[1][3] = GtaScm::Node::Raw.new( GtaScm::Types.value2bin( mission_count , :int16 ).bytes )
              # self.use_touchup(offset,[1,3],:_total_mission_count)

              # exclusive missions
              node[1][4] = GtaScm::Node::Raw.new( [0xBB,0xBB] )
              self.use_touchup(offset,[1,4],:_exclusive_mission_count)

              node[1][5] = GtaScm::ByteArray.new
              (tokens[6] || []).each do |mission|
                node[1][5] << GtaScm::Node::Raw.new( GtaScm::Types.value2bin( mission[1][1] , :int32 ).bytes )
              end

              self.define_touchup(:label__post_header_missions,nodes.next_offset(node))
            end
          when :labeldef
            # debugger
            self.define_touchup(tokens[1],nodes.next_offset)
            next
          else
            self.assemble_instruction(scm,offset,tokens)
        end
        # debugger
        node.offset = offset
        nodes << node

        logger.notice "size: #{nodes.last.size}"
        logger.notice nodes.last.hex_inspect
        logger.notice ""
      end
    end

    logger.error "touchup_defines: #{touchup_defines.inspect}"
    logger.error "touchup_uses #{touchup_uses.inspect}"

    self.define_touchup(:_main_size,331)
    self.define_touchup(:_largest_mission_size,0)
    self.define_touchup(:_exclusive_mission_count,0)

    self.touchup_uses.each_pair do |touchup_name,uses|
      uses.each do |(offset,array_keys)|
        
        # logger.error "#{touchup_name} - #{offset} #{array_keys.inspect}"
        node = nodes.detect{|node| node.offset == offset}
        # logger.error "node: #{node.inspect}"


        case touchup_name
          # when :_main_size
          # when :_largest_mission_size
          # when :_exclusive_mission_count
          when :_version
          else
            arr = node
            array_keys.each do |array_key|
              # logger.error " arr: #{array_key} #{arr.inspect}"
              arr = arr[array_key]
            end

            touchup_value = self.touchup_defines[touchup_name]
            # logger.error "value: #{touchup_value}"
            case arr.size
            when 4
              touchup_value = GtaScm::Types.value2bin( touchup_value , :int32 ).bytes
            when 2
              touchup_value = GtaScm::Types.value2bin( touchup_value , :int16 ).bytes
            else
              raise "dunno how to replace value of size #{arr.size}"
            end
            touchup_value = touchup_value[0...arr.size]

            # logger.error "replacing :#{arr.inspect} with #{touchup_value}"
            arr.replace(touchup_value)
        end

        # logger.error ""
      end
    end

    File.open("#{out_path}","w") do |f|
      self.nodes.each do |node|
        f << node.to_binary
      end
    end
  end

  def define_touchup(touchup_name,value)
    self.touchup_defines[touchup_name] = value
  end

  def use_touchup(node_offset,array_keys,touchup_name)
    self.touchup_uses[touchup_name] << [node_offset,array_keys]
  end

  def assemble_instruction(scm,offset,tokens)
    name = tokens[0].to_s.upcase
    negated = name.gsub!(/^NOT_/,'')

    if opcode = scm.opcodes.names2opcodes[name]
      opcode_def = scm.opcodes[opcode]
      # puts "#{tokens.inspect}"
      return GtaScm::Node::Instruction.new.tap do |node|
        node.offset = offset
        node.opcode = GtaScm::ByteArray.new(opcode)
        node.negate! if negated

        if opcode_def.var_args?
          arg_idx = 0
          loop do
            self.assemble_argument(node,nil,arg_idx,tokens)
            arg_idx += 1
            break if node.arguments.last.end_var_args?
          end
        else
          opcode_def.arguments.each_with_index do |arg_def,arg_idx|
            self.assemble_argument(node,arg_def,arg_idx,tokens)
          end
        end
        # puts "  #{node.hex_inspect}"
      end
    else
      raise "unknown opcode #{tokens[0]}"
    end
  end

  def assemble_argument(node,arg_def,arg_idx,tokens)
    node.arguments[arg_idx] = GtaScm::Node::Argument.new.tap do |arg|
      arg_tokens = tokens[1][arg_idx]
      case arg_tokens[0]
      # when :objscm
      #   puts "objscm #{}"
      # when :pickup_type
      #   arg.set( :int , arg_tokens[1] )
      when :label
        # puts "label : #{arg_tokens.inspect}"
        # TODO:
        # def register_touchup(node_offset,path_to_value,touchup_name,expected_placeholder)
        # self.register_touchup(node.offset,[1,arg_idx,1],"label_#{arg_tokens[1]}",[0xAA,0xAA,0xAA,0xAA])

        # HACK: don't auto-gen label touchups for _prefixed label names (internal use)
        if arg_tokens[1].to_s.match(/label__/)

        else
          # debugger
          self.use_touchup(node.offset,[1,arg_idx,1],arg_tokens[1])
        end

        arg.set( :int32, 0xAAAAAAAA )
      else
        arg.set( arg_tokens[0] , arg_tokens[1] )
        # puts "#{arg.arg_type_sym} - #{arg_tokens[1].inspect}"
      end
    end
  end
end
