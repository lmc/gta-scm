class GtaScm::Panel::Base
  attr_accessor :manager
  attr_accessor :x
  attr_accessor :y
  attr_accessor :width
  attr_accessor :height
  attr_accessor :elements
  attr_accessor :settings
  attr_accessor :controller
  attr_accessor :special_elements
  attr_accessor :theme_prefix


  def initialize(manager = nil,x = 0,y = 0,width = 0,height = 0)
    self.manager = manager
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.elements = Hash.new
    self.settings = Hash.new
    self.special_elements = Hash.new
    self.theme_prefix = nil
  end

  def add_elements_to_screen(screen)
    self.elements.each_pair do |key,element|
      screen.add(element)
    end
  end

  def update(process,is_attached,focused = false)
    
  end

  def input(key,is_attached,process)
    
  end
  def focused_input(key,is_attached,process)
    
  end

  def mouse_click(x,y,is_attached,process)
    
  end
  def abs_mouse_click(x,y,is_attached,process)
    
  end

  def mouse_move(x,y,is_attached,process)
    
  end
  def abs_mouse_move(x,y,is_attached,process)
    
  end

  def mouse_scroll(x,y,dir,is_attached,process)
    
  end

  def has_textfield
    false
  end

  def textfield_input(key,is_attached,process)

  end


  def dx(xo)
    self.x + xo
  end
  def dy(yo)
    self.y + yo
  end

  def panel_list(data,rows,empty_row)
    list_height = rows - 1
    data = data[0..list_height]
    while data.size < list_height - 2
      data << empty_row
    end
    data
  end


  def on_focus
    self.theme_prefix = :focus
    special_set_colors
    # self.elements.each_pair do |name,element|
    #   if name.to_s.match(/header/)
    #     # element.fg = RuTui::Theme.get(:textcolor)
    #   else
    #     element.fg = RuTui::Theme.get(:textcolor)
    #   end
    # end
  end

  def on_blur
    self.theme_prefix = nil
    special_set_colors
    # self.elements.each_pair do |name,element|
    #   if name.to_s.match(/header/)

    #   else
    #     element.fg = RuTui::Theme.get(:unfocused)
    #   end
    # end
  end

  def var_value(type,binary)
    # case self.settings[:types][ii]
    case type
    when :int
      GtaScm::Types.bin2value(binary,:int32).to_s
    when :float
      GtaScm::Types.bin2value(binary,:float32).to_f.round(3).to_s
    when :bin
      GtaScm::Types.bin2value(binary,:int32).to_s(2).rjust(32,"0").chars.in_groups_of(8).map{|g| g.join}.join("-")
    when :str
      binary.to_s.inspect
    else
      nil
    end
  end

  def theme_get(symbol)
    if self.theme_prefix
      RuTui::Theme.get(:"#{self.theme_prefix}_#{symbol}") || RuTui::Theme.get(symbol)
    else
      RuTui::Theme.get(symbol)
    end
  end


=begin
  
  table(:main,{
    x: 0,
    y: 0,
    width: 32,
    height: 10,
    columns: {
      id:    { width: 2 },
      key:   { width: 8, header: "Key" },
      value: { width: 12 }
    },
    scrollable: true,
    scroll_bar: true,
    selectable: true,
  })

  table_set([all_rows/cols])
  table_set(0,[cols])
  table_set(0,1,cell)

  table_style do |row,col,char_idx,char,col_value,highlight_row|
    
    [fg,bg,char]
  end
=end

  def header(name,options = {})
    options.reverse_merge!({
      type: :header,
      x: nil,
      y: nil,
      width: nil,
      text: "Header",
      fg: theme_get(:header_fg),
      bg: theme_get(:header_bg),
    })
    self.elements[:"#{name}"] = RuTui::Text.new({
      x: options[:x],
      y: options[:y],
      text: options[:text],
      foreground: options[:fg],
      background: options[:bg],
      bold: true
    })
    self.special_elements[name] = options
    header_set(name,options[:text])
  end

  def header_set(name,text)
    self.elements[name].fg = self.special_elements[name][:fg]
    self.elements[name].bg = self.special_elements[name][:bg]
    self.elements[name].set_text(text.center(self.special_elements[name][:width]))
  end

  def special_set_colors
    self.special_elements.each_pair do |name,special|
      case special[:type]
      when :header
        self.elements[name].fg = theme_get(:header_fg)
        self.elements[name].bg = theme_get(:header_bg)
      when :table
        self.elements[name].fg = theme_get(:table_fg)
        self.elements[name].bg = theme_get(:table_bg)
        self.elements[name].pixel = RuTui::Pixel.new( theme_get(:table_fg), theme_get(:table_bg), " " )
        if self.special_elements[name][:scroll_bar]
          self.elements[:"#{name}_scroll_bar"].onpixel_fg = theme_get(:scroll_bar_on_fg)
          self.elements[:"#{name}_scroll_bar"].onpixel_bg = theme_get(:scroll_bar_on_bg)
          self.elements[:"#{name}_scroll_bar"].offpixel_fg = theme_get(:scroll_bar_off_fg)
          self.elements[:"#{name}_scroll_bar"].offpixel_bg = theme_get(:scroll_bar_off_bg)
        end
      end
    end
  end

  def table(name,options = {})
    options.reverse_merge!({
      type: :table,
      x: nil,
      y: nil,
      width: nil,
      height: nil,
      columns: {
      },
      header: false,
      scrollable: false,
      scroll_bar: false,
      selectable: false,
    })
    options[:rows] = options[:height] - 2
    options[:rows] -= 2 if options[:header]

    xo,wo = 0,0
    if options[:scroll_bar] == :left
      xo,wo = 1, 1
      self.elements[:"#{name}_scroll_bar"] = RuTui::CustomLine.new({
        x: options[:x],
        y: options[:y]+1,
        length: options[:height]-2,
        onpixel: RuTui::Pixel.new(0,7," "),
        offpixel: RuTui::Pixel.new(7,0,"|"),
      })
    elsif options[:scroll_bar] == :right
      xo,wo = 0, 1
    end

    options[:var_width] = options[:width] - wo - 1 - options[:columns].map{|_,c| c[:width].is_a?(Float) ? 0 : c[:width]}.inject(:+) - (options[:columns].size * 3)



    self.elements[name] = RuTui::Table.new({
      x: options[:x]+xo,
      y: options[:y],
      table: [[""]*options[:columns].size],
      cols: options[:columns].map {|col_name,col|
        width = col[:width].is_a?(Float) ? (options[:var_width] * col[:width]).round : col[:width]
        {title: "#{col[:header] || col_name}", length: width, align: col[:align] }
      },
      header: options[:header],
      pixel: RuTui::Pixel.new(theme_get(:table_fg),theme_get(:table_bg)," "),
      bg: theme_get(:table_bg)
    })
    self.elements[name].cell_style_block = self.default_table_style

    self.special_elements[name] = options
    self.special_elements[name][:max_rows] = 0

    self.settings[:"#{name}_scroll_offset"] = 0
    self.settings[:"#{name}_select_offset"] = 0
  end

  def table_set(name,data1,data2 = nil,data3 = nil)
    if data1 && !data2 && !data3
      self.special_elements[name][:max_rows] = data1.size
      if self.special_elements[name][:scrollable]
        data1 = data1.slice( self.settings[:"#{name}_scroll_offset"] , self.special_elements[name][:rows] )
      end
      if self.special_elements[name][:scroll_bar]
        begin_percent = self.settings[:"#{name}_scroll_offset"].to_f
        begin_percent /= self.special_elements[name][:max_rows]
        end_percent = (self.settings[:"#{name}_scroll_offset"]+self.special_elements[name][:rows]).to_f
        end_percent /= self.special_elements[name][:max_rows]
        self.elements[:"#{name}_scroll_bar"].set_scroll(begin_percent,end_percent)
      end
      self.elements[name].set_table(data1)
    else
      raise ArgumentError
    end
  end

  def table_style(name,&block)
    self.elements[name].cell_style_block = block
  end

  def table_scroll_rows(name,rows = +1)
    self.settings[:"#{name}_scroll_offset"] += rows
    table_scroll_check(name)
  end

  def table_scroll_page(name,pages = +1)
    self.settings[:"#{name}_scroll_offset"] += (pages * self.special_elements[name][:rows])# + (pages == +1 ? +1 : -1)
    table_scroll_check(name)
  end

  def table_scroll_check(name)
    self.settings[:"#{name}_scroll_offset"] = 0 if self.settings[:"#{name}_scroll_offset"] < 0
    self.settings[:"#{name}_scroll_offset"] = self.special_elements[name][:max_rows] - self.special_elements[name][:rows] if self.settings[:"#{name}_scroll_offset"] > self.special_elements[name][:max_rows] - self.special_elements[name][:rows]
  end

  def table_scroll_selected_row(name,rows = +1)
    table_select_row(name,self.settings[:"#{name}_select_offset"] + rows)
    if self.special_elements[name][:scrollable]
      if self.settings[:"#{name}_select_offset"] >= self.settings[:"#{name}_scroll_offset"] + self.special_elements[name][:rows]
        table_scroll_page(name,+1)
      elsif self.settings[:"#{name}_select_offset"] < self.settings[:"#{name}_scroll_offset"]
        # table_scroll_page(name,-1)
        self.settings[:"#{name}_scroll_offset"] = self.settings[:"#{name}_select_offset"]
      end
      table_select_row(name,self.settings[:"#{name}_select_offset"])
    end
  end

  def table_select_row(name,index)
    self.settings[:"#{name}_select_offset"] = index
    self.elements[name].highlight(index - self.settings[:"#{name}_scroll_offset"])
    table_select_check(name)
  end

  def table_select_check(name)
    self.settings[:"#{name}_select_offset"] = 0 if self.settings[:"#{name}_select_offset"] < 0
    self.settings[:"#{name}_select_offset"] = self.special_elements[name][:max_rows] if self.settings[:"#{name}_select_offset"] > self.special_elements[name][:max_rows]
  end

  # TODO: handle elements not named `:table` and use positions/dimensions from element
  def table_click_index(name,x,y,top = 2)
    first_row = top # header bar + top of table
    first_row += 2 if self.special_elements[:table][:header]

    if y >= top && y < self.height - 1
      y - first_row
    else
      nil
    end
  end

  def default_table_style
    lambda do |row,col,char_idx,char,col_value,is_highlighted_row|
      if is_highlighted_row
        [theme_get(:highlight_fg),theme_get(:highlight_bg),char]
      else
        [theme_get(:text_fg),theme_get(:text_bg),char]
      end
    end
  end

end
