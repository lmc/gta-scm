class GtaScm::Panel::Gvars2 < GtaScm::Panel::Base
  def initialize(*)
    super
    
    header(:header,{
      x: dx(0),
      y: dy(0),
      width: self.width,
      text: "Global Variables - ctrl+y: type",
    })

    table(:table,{
      x: self.dx(0),
      y: self.dy(1),
      width: self.width,
      height: self.height - 2,
      columns: {
        offset:   { width: 5, header: "GVar" },
        type:     { width: 3, header: "Typ" },
        name:     { width: 1.0 },
        value:    { width: 12, align: :right }
      },
      header: false,
      scrollable: true,
      scroll_bar: :left,
      selectable: true,
    })

    self.settings[:gvars] = []
    self.settings[:types] = []
    self.settings[:names] = []
    self.settings[:gvars_inited] = false
  end

  def update(process,is_attached,focused = false)
    return if !is_attached

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

    range = self.settings[:gvars]
    data = range.map.each_with_index do |gvar,idx|
      label = self.settings[:names][idx] || "gvar #{gvar}"
      size = self.settings[:types][idx] == :str ? 8 : 4
      type = self.settings[:types][idx]
      value = process.read_scm_var(gvar,nil,size)
      value = self.var_value(type,value)
      ["#{gvar}","#{type}",label,value]
    end.compact

    table_style(:table) do |row,col,char_idx,char,col_value,is_highlighted_row|
      if is_highlighted_row
        [theme_get(:highlight_fg),theme_get(:highlight_bg),char]
      else
        [theme_get(:text_fg),theme_get(:text_bg),char]
      end
    end

    table_set(:table,data)
  end

  def input(key,is_attached,process)
    case key
    when :ctrl_y
      type = self.settings[:types][ self.settings[:"table_select_offset"] ]
      new_type = case type
      when :int
        :float
      when :float
        :str
      when :str
        :bin
      when :bin
        :int
      end
      self.settings[:types][ self.settings[:"table_select_offset"] ] = new_type
    end
  end

  def focused_input(key,is_attached,process)
    case key
    when :up
      table_scroll_selected_row(:table,-1)
    when :down
      table_scroll_selected_row(:table,+1)
    end
  end

  def mouse_click(x,y,is_attached,process)
    first_row = 2 # header bar + top of table
    first_row += 2 if self.special_elements[:table][:header]

    if y >= 2 && y < self.height - 1
      clicked_row = y - first_row
      table_select_row(:table, self.settings[:"table_scroll_offset"] + clicked_row)
    end
  end

end
