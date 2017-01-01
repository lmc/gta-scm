class GtaScm::Panel::Gvars < GtaScm::Panel::Base
  def initialize(*)
    super
    self.elements[:header] = RuTui::Text.new(x: dx(0), y: dy(0), text: "")
    set_text
    self.elements[:table] = RuTui::Table.new({
      x: self.dx(0),
      y: self.dy(1),
      table: [["","",""]],
      cols: [
        { title: "", length: 5 },
        { title: "", length: (self.width.to_f * 0.6).to_i - 7 },
        { title: "", length: (self.width.to_f * 0.4).to_i - 7 },
      ],
      header: false,
      hover: RuTui::Theme.get(:highlight),
      hover_fg: RuTui::Theme.get(:highlight_fg),
    })
    self.settings[:gvars] = []
    self.settings[:types] = []
    self.settings[:names] = []

    # [
      # [172  ,:int ,"interior"],
      # [100  ,:int ,"stat"],
      # [160  ,:int ,"day of week"],
      # [616  ,:int ,"language"],
      # [1636,:int ,"mission_flag"],
      # [21136,:int ,"game timer"],

      # [7084,:int ,"watchdog timer"],
      # [7088,:int ,"extscript 78 count"],
      # [4484,:int ,"watchdog check"],
      # [4488,:int ,"watchdog timer"],
      # [4492,:int ,"extscript 78 count"],
      # [4496,:int ,"code state"],
      # [3428,:int ,"code version"],
      # [3432,:int ,"save version"],
      # [7088,:int ,"debug enabled"],
      # [7084,:int ,"debug feedback enabled"],
    #   [7120,:int ,"array item"],
    #   [7124,:int ,"array index"],
    #   [7128,:int ,"array 0"],
    #   [7132,:int ,"array 1"],
    #   [7136,:int ,"array 2"],
    #   [7140,:int ,"array 3"],
    #   [7144,:int ,"array 4"],
    #   [7148,:int ,"array 5"],
    #   [7152,:int ,"array 6"],
    #   [7156,:int ,"array 7"],
    #   [21828,:int ,"unused ?"],
    #   [21832,:int ,"unused ?"],
    #   [21836,:int ,"unused ?"],
    #   [21840,:int ,"unused ?"],
    #   [21844,:int ,"unused ?"],
    #   [40848,:int ,"unused ?"],
    # ]



    # .each do |(gvar,type,name)|
    #   self.settings[:gvars] << gvar
    #   self.settings[:types] << type
    #   self.settings[:names] << name
    # end
    self.settings[:gvars_inited] = false
    self.settings[:selected_gvar] = 0
  end

  def set_text(process = nil)
    str = "Global Variables - r/f: prev/next"
    str = str.center(self.width)
    self.elements[:header].bg = 7
    self.elements[:header].fg = 0
    self.elements[:header].set_text(str)
  end

  def update(process,is_attached,focused = false)
    if !is_attached
      return
    end

    if !self.settings[:gvars_inited]
      gvars = process.symbols_var_offsets.each_pair.map do |name,offset|
        type = process.symbols_var_types[offset]
        if name || offset == 21744
          type ||= :int
          type == :int32 if type == :int
          type == :float32 if type == :float
          [offset.to_i,name,type]
        end
      end.compact
      gvars.sort_by!(&:first)
      gvars.each do |(offset,name,type)|
        self.settings[:gvars] << offset
        self.settings[:types] << type.to_sym
        self.settings[:names] << name
      end
      self.settings[:gvars_inited] = true
    end

    data = self.settings[:gvars].map.each_with_index do |gvar,idx|
      label = self.settings[:names][idx] || "gvar #{gvar}"
      value = process.read_scm_var(gvar,self.settings[:types][idx]).to_s
      ["#{gvar}",label,value]
    end.compact

    data = self.panel_list(data,self.height - 3,[["","",""]])

    self.elements[:table].set_table(data)
  end
end
