require 'timeout'

# implement non-blocking reads
# class RuTui::Input
#   class << self
#     alias getc_orig getc
#   end

#   def self.getc
#     begin
#       # Timeout.timeout(0.3) do
#         getc_orig
#       # end
#     rescue Timeout::Error
#       nil
#     end
#   end
# end

class RuTui::Table
  def initialize_with_highlight_fg(options)
    initialize_without_highlight_fg(options)
    @hover_fg = options[:hover_fg]
  end
  alias initialize_without_highlight_fg initialize
  alias initialize initialize_with_highlight_fg

  # make highlight method actually work like the developer intended (arg absent = get, arg present = set)
  def highlight(line_id = nil)
    return @highlight if line_id.nil?
    line_id = 0 if line_id <= 0
    line_id = (row_count - 1) if line_id >= row_count
    @highlight = line_id
    @reverse = false
    create
  end

  def clear_highlight!
    @highlight = nil
  end

  def row_count
    @table.size
  end

  def create
    obj = []
    if @header
      obj << ascii_table_line if @ascii
      _obj = []
      _obj << RuTui::Pixel.new(@pixel.fg,@bg,"|") if @ascii
      @cols.each_with_index do |col, index|
        _obj << nil
        fg = @pixel.fg
        fg = @cols[index][:title_color] if !@cols[index].nil? and !@cols[index][:title_color].nil?
        chars = "".to_s.split("")
        chars = "#{ col[:title] }".to_s.split("") if !col.nil? and !col[:title].nil?
        chars.each_with_index do |e, char_count|
          _obj << RuTui::Pixel.new(fg,@bg,e)
        end
        (@meta[:max_widths][index]-chars.size+0).times do |i|
          _obj << nil
        end
        _obj << nil
        _obj << RuTui::Pixel.new(@pixel.fg,@bg,"|") if @ascii
      end
      obj << _obj
    end
    obj << ascii_table_line if @ascii
    @table.each_with_index do |line, lindex|
      # CHANGED: fg color highlight too
      fg = @pixel.fg
      bg = @bg
      fg = @hover_fg if lindex == @highlight and @highlight_direction == :horizontal
      bg = @hover if lindex == @highlight and @highlight_direction == :horizontal
      _obj = []
      _obj << RuTui::Pixel.new(@pixel.fg,@pixel.bg,"|") if @ascii
      line.each_with_index do |col, index|
        # fg = @fg
        fg = @cols[index][:color] if !@cols[index].nil? and !@cols[index][:color].nil?
        fg = @highlight_lines.include?(lindex) ? @highlight_line_color : fg if @highlight_lines
        fg = @highlight_line_colours[lindex] if @highlight_line_colours.andand[lindex] && @highlight_lines

        if @highlight_direction == :vertical
          if index == @highlight
            bg = @hover
          else
            bg = @bg
          end
        end


        chars = col.to_s.split("")
        _obj << nil
        max_chars = nil
        max_chars = @cols[index][:max_length]+1 if !@cols[index].nil? and !@cols[index][:max_length].nil?
        max_chars = @cols[index][:length]+1 if !@cols[index].nil? and !@cols[index][:length].nil?
        chars.each_with_index do |e, char_count|
          break if !max_chars.nil? and char_count >= max_chars
          _obj << RuTui::Pixel.new(fg,bg,e)
        end
        (@meta[:max_widths][index]-chars.size+1).times do |i|
          _obj << nil
        end

        bg = @bg if @highlight_direction == :vertical
        _obj << RuTui::Pixel.new(@pixel.fg,@pixel.bg,"|") if @ascii
      end
      obj << _obj
    end
    obj << ascii_table_line if @ascii
    @obj = obj
  end

  def set_highlight_line_color(highlight_line_color)
    @highlight_line_color = highlight_line_color
  end

  def clear_highlight_lines!
    @highlight_lines = []
    @highlight_line_colours = {}
  end

  def add_highlight_line(index,colour = nil)
    @highlight_lines << index
    @highlight_line_colours[index] = colour if colour
  end

end

class RuTui::Screen
  def self.size
    rr = IO.console.winsize
    rr[0] -= 1
    # rr[1] -= 2
    rr
  end

  # patch to use << instead of +=
  def draw
    lastpixel = RuTui::Pixel.new(rand(255), rand(255), ".")
    @map = Marshal.load( Marshal.dump( @smap )) # Deep copy

    # get all the objects
    @objects.each do |o|
      next if o.x.nil? or o.y.nil?
      o.each do |ri,ci,pixel|
        if !pixel.nil? and o.y+ri >= 0 and o.x+ci >= 0 and o.y+ri < @map.size and o.x+ci < @map[0].size
          # -1 enables a "transparent" effect
          if pixel.bg == -1
            pixel.bg = @map[o.y + ri][o.x + ci].bg if !@map[o.y + ri][o.x + ci].nil?
            pixel.bg = RuTui::Theme.get(:background).bg if pixel.bg == -1
          end
          if pixel.fg == -1
            pixel.fg = @map[o.y + ri][o.x + ci].fg if !@map[o.y + ri][o.x + ci].nil?
            pixel.fg = RuTui::Theme.get(:background).fg if pixel.fg == -1
          end

          @map[o.y + ri][o.x + ci] = pixel
        end
      end
    end

    out = "" # Color.go_home
    # and DRAW!
    @map.each do |line|
      line.each do |pixel|
        if lastpixel != pixel
          # out += RuTui::Ansi.clear_color if lastpixel != 0
          out << RuTui::Ansi.clear_color if lastpixel != 0
          if pixel.nil?
            # out += "#{RuTui::Ansi.bg(@default.bg)}#{RuTui::Ansi.fg(@default.fg)}#{@default.symbol}"
            out << "#{RuTui::Ansi.bg(@default.bg)}#{RuTui::Ansi.fg(@default.fg)}#{@default.symbol}"
          else
            # out += "#{RuTui::Ansi.bg(pixel.bg)}#{RuTui::Ansi.fg(pixel.fg)}#{pixel.symbol}"
            out << "#{RuTui::Ansi.bg(pixel.bg)}#{RuTui::Ansi.fg(pixel.fg)}#{pixel.symbol}"
          end
          lastpixel = pixel
        else
          if pixel.nil?
            # out += @default.symbol
            out << @default.symbol
          else
            # out += pixel.symbol
            out << pixel.symbol
          end
        end
      end
    end

    # draw out
    print out.chomp
    $stdout.flush
  end
end

