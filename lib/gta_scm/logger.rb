class GtaScm::Logger
  LEVELS = [
    :debug,
    :info,
    :notice,
    :warn,
    :error,
    :none,
  ]

  attr_accessor :level
  attr_accessor :start_time
  attr_accessor :decorations

  def initialize(level = :info)
    self.start_time = Time.now
    self.level = level
    self.decorations = [:runtime,:level_char]
  end

  def log(str,level = :info)
    if self.level <= GtaScm::Logger.level_int(level)
      puts "#{prefix(level)}#{str}"
    end
  end

  def prefix(level)
    return "" if self.decorations.empty?
    str = self.decorations.map{ |sym| self.send(sym,level) }
    "#{str.join(' ')} - "
  end

  def level=(value)
    @level = GtaScm::Logger.level_int(value)
  end

  def runtime(level)
    time = (Time.now-start_time).to_f
    ('%.6f' % time).rjust(12," ")
  end

  def level_char(level)
    level[0].upcase
  end

  def debug(str)
    log(str,:debug)
  end

  def info(str)
    log(str,:info)
  end

  def notice(str)
    log(str,:notice)
  end

  def warn(str)
    log(str,:warn)
  end

  def error(str)
    log(str,:error)
  end

  def self.level_int(level)
    if level.is_a?(Symbol)
      level = LEVELS.index(level)
    end
    level
  end
  
end
