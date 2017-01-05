class GtaScm::Panel::Base
  attr_accessor :manager
  attr_accessor :x
  attr_accessor :y
  attr_accessor :width
  attr_accessor :height
  attr_accessor :elements
  attr_accessor :settings
  attr_accessor :controller

  def initialize(manager = nil,x = 0,y = 0,width = 0,height = 0)
    self.manager = manager
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.elements = Hash.new
    self.settings = Hash.new
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
    self.elements.each_pair do |name,element|
      if name.to_s.match(/header/)
        # element.fg = RuTui::Theme.get(:textcolor)
      else
        element.fg = RuTui::Theme.get(:textcolor)
      end
    end
  end

  def on_blur
    self.elements.each_pair do |name,element|
      if name.to_s.match(/header/)

      else
        element.fg = RuTui::Theme.get(:unfocused)
      end
    end
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
end
