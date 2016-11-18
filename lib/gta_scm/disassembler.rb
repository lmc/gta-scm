module GtaScm::Disassembler
end

class GtaScm::Disassembler::Base
  attr_accessor :scm
  attr_accessor :files
  attr_accessor :options

  attr_accessor :output

  def initialize(scm, options = {})
    self.scm = scm
    self.options = options.reverse_merge(
      # emit_bytecode_comments: false
      emit_bytecode_comments: true,
      emit_multiline_headers: true,
      use_enum_arguments: false
    )
  end

  def disassemble(destination_path)
    `mkdir -p #{destination_path}`
    self.files = OutputDir.new(destination_path,self.extension)

    # debugger
    
    self.scm.nodes.each_pair do |offset,node|
      emit_node(offset,node)
      update_progress(offset)
    end

    # debugger

    if self.scm.img_scms
      # debugger
      self.scm.img_scms.each_with_index do |img_scm,i|
        name = self.scm.img_file.entries[i][:name].gsub(/\.scm/,'')
        header_entry = self.scm.externals_header[1][3].detect{|h| h[0].map(&:chr).join.strip.downcase == name}
        header_idx = 99
        if header_entry
          header_idx = self.scm.externals_header[1][3].index(header_entry)
        end
        scm_img_name = "external_#{header_idx.to_s.rjust(2,"0")}_#{name}"
        # debugger
        # puts "disassembling #{scm_img_name}"
        # TODO: note these as externals so mission_labels get detected properly
        img_scm.nodes.each_pair do |offset,node|
          # debugger
          emit_node(offset,node,scm_img_name)
        end
      end
    end

    self.files.close_all

    if $dmavar_uses
      dmavar_uses = $dmavar_uses.to_a.sort
      puts dmavar_uses
    end
  end

  attr_accessor :progress_callback
  def update_progress(offset)
    if self.progress_callback
      @progress_calls ||= 0
      @progress_calls += 1
      self.progress_callback.call(offset,nil,@progress_calls)
    end
  end

  def emit_node(offset,node)
    raise "abstract"
  end

  def extension;
    raise "abstract"
  end

  # TODO: handle externals as mission labels
  def label_for_offset(offset,source_offset = nil)
    if offset < 0
      if mission = self.scm.mission_for_offset(source_offset)
        mission_id,mission_offset = mission[0],mission[1]
      else
        mission_offset = 0
      end
      abs_offset = mission_offset + offset.abs
      :"label_#{abs_offset}"
    else
      :"label_#{offset}"
    end
  end

  attr_accessor :current_mission_id
  attr_accessor :next_mission_offset
  def file_for_offset(offset,scm_img_name = nil)
    begin
    if self.output
      self.output
    elsif scm_img_name
      self.files[scm_img_name]
    # elsif mission = self.scm.mission_for_offset(offset)
    #   self.files["mission_#{mission[0]}"]
    else

      if offset == 194046
        # $debug = true
      end

      if $debug
        debugger
        $debug
      end

      if !self.current_mission_id && scm.missions_header && scm.missions_header.mission_offsets.size > 0
        self.current_mission_id = -1
        self.next_mission_offset = self.scm.missions_header.mission_offsets.first
      end
      if offset == self.next_mission_offset
        # debugger
        self.current_mission_id += 1
        self.next_mission_offset = self.scm.missions_header.mission_offsets[self.current_mission_id + 1] || self.scm.size
      end
      if self.current_mission_id >= 0
        self.files["mission_#{current_mission_id.to_s.rjust(3,"0")}"]
      else
        self.files["main"]
      end
    end
    rescue => ex
      debugger
      ex
    end
  end

  class OutputDir
    attr_accessor :dir
    attr_accessor :hash
    attr_accessor :extension

    def initialize(dir,extension)
      self.dir = dir
      self.extension = extension
      self.hash = {}
    end

    def [](key)
      self.hash.fetch(key) do
        self.hash[key] = File.open(File.join(self.dir,"#{key}#{self.extension}"),"w")
      end
    end

    def close_all
      self.hash.values.each(&:close)
    end
  end
end

class GtaScm::Disassembler::Sexp < GtaScm::Disassembler::Base

  def emit_node(offset,node,file = nil)
    output = self.file_for_offset(offset,file)
    if node.label?
      label = sexp( [:labeldef,self.label_for_offset(node.offset)] )
      output.puts()
      output.puts(label)
    end
    line = sexp( node.to_ir(self.scm,self) )
    if node.is_a?(GtaScm::Node::Instruction)
      @largest_line ||= 0
      @largest_line = node.hex.size if node.hex.size > @largest_line
    end
    if self.options[:emit_bytecode_comments]
      mission_offset = self.mission_offset_comment(offset)
      output.puts("% #{offset.to_s.rjust(8,"0")}#{mission_offset} - #{node.hex}")
    end
    output.puts(line)
  end

  def mission_offset_comment(offset)
    if mission = self.scm.mission_for_offset(offset)
      " (#{offset - mission[1]})"
    else
      ""
    end
  end

  def extension
    ".sexp.erl"
  end

  def sexp(exp)
    Elparser::encode(exp)
  end

  # def sexp(exp)
  #   inner = exp.map do |el|
  #     if el.is_a?(Array)
  #       sexp(el)
  #     else
  #       el.to_s
  #     end
  #   end.join(" ")
  #   "(#{inner})"
  # end

end