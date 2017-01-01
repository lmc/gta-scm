class GtaScm::Panel::CodeInjector < GtaScm::Panel::Base
  TABLE_LINE_COUNT = 1
  STATUS_LINE_COUNT = 4

  def initialize(*)
    super

    tx,ty = 0,0

    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(ty), text: "")
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text("Code Injector - u: inject, j: kill".center(self.width))
    ty += 1

    self.elements[:status_box] = RuTui::Box.new(
      x: dx(0),
      y: dy(ty + TABLE_LINE_COUNT + 3),
      width: self.width,
      height: STATUS_LINE_COUNT + 2,
      corner: RuTui::Pixel.new(RuTui::Theme.get(:border).fg,RuTui::Theme.get(:background).bg,"+")
    )

    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(ty),
      table: [["","","",""]],
      cols: [
        { title: "Filename", length: 21 },
        { title: "Mode", length: 6 },
        { title: "LoadTime", length: 8 },
        { title: "Status", length: 14 },
      ],
      header: true,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
    ty += TABLE_LINE_COUNT + 4


    self.settings[:injectors] = [
      ["inject",198_000,"injectd",7092]
    ]


    (0...STATUS_LINE_COUNT).each do |line_idx|
      self.elements[:"status_line_#{line_idx}"] = RuTui::Text.new(x: dx(2), y: dy(ty), text: "line #{line_idx}")
      ty += 1
    end

  end

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    data = self.settings[:injectors].map do |injector|
      thread = process.threads.detect{|t| t.name == injector[2] }
      status = thread ? thread.status : "nothread"
      [injector[0],injector[1].to_s,injector[2],injector[3].to_s,"#{status}"]
    end
    data = [["","","",""]]
    self.elements[:table].set_table(data)

  end

  attr_accessor :allocation_count
  VM_ALLOCATE_SIZE = 1024
  def input(key,is_attached,process)
    self.allocation_count ||= 0

    if key == "u"
      print RuTui::Ansi.clear_color + RuTui::Ansi.clear
      dir = "scm-src/sa-experiments"
      filename = self.settings[:injectors][0][0]
      thread_name = self.settings[:injectors][0][2]

      # HORRIBLE HACK:
      # vm_allocate gives us back 64-bit pointers so we can't use it for VM memory allocation...
      # code_offset = Ragweed::Wraposx::vm_allocate(process.process.task,base_offset,VM_ALLOCATE_SIZE,true)
      
      # ...so lets just write into the top 1gb of user-process memory space
      code_offset = (2**30) + (VM_ALLOCATE_SIZE * self.allocation_count += 1)

      code_offset -= process.scm_offset

      scm = GtaScm::Scm.load_string("san-andreas","")
      scm.load_opcode_definitions!
      asm = GtaScm::Assembler::Sexp.new(dir)
      asm.code_offset = code_offset
      def asm.install_features!
        class << self
          include GtaScm::Assembler::Feature::VariableAllocator
          include GtaScm::Assembler::Feature::VariableHeaderAllocator
        end
        self.on_feature_init()
      end
      output = StringIO.new
      asm.assemble(scm,filename,output)
      output.rewind
      code = output.read

      process.write(process.scm_offset + code_offset, code)
      process.rpc(1,code_offset,thread_name || "xinject")
    end

    if key == "j"
      thread_name = self.settings[:injectors][0][2]
      process.rpc(2,"#{thread_name}")
    end
  end
end
