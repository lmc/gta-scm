require 'timeout'

# implement non-blocking reads
class RuTui::Input
  class << self
    alias getc_orig getc
  end

  def self.getc
    begin
      # Timeout.timeout(0.3) do
        getc_orig
      # end
    rescue Timeout::Error
      nil
    end
  end
end

class RuTui::Table
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
end

class RuTui::Screen
  def self.size
    rr = IO.console.winsize
    rr[0] -= 1
    rr
  end
end

