class ProgressBar
  def set!(count)
    self.count = count
    now = ::Time.now
    if (now - @last_write) > 0.2 || self.count >= max
      write
      @last_write = now
    end
  end

  def move_goalposts(new_total)
    @max = new_total
  end
end
