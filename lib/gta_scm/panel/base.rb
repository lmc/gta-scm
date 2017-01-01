class GtaScm::Panel::Base
  attr_accessor :x
  attr_accessor :y
  attr_accessor :width
  attr_accessor :height
  attr_accessor :elements
  attr_accessor :settings
  attr_accessor :controller

  def initialize(x,y,width,height)
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
end
