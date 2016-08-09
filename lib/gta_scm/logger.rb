class GtaScm::Logger
  LEVELS = [
    :debug,
    :info,
    :notice,
    :warn,
    :error
  ]

  attr_accessor :level
  attr_accessor :start_time

  def initialize(level = :debug)
    self.start_time = Time.now
    self.level = GtaScm::Logger.level_int(level)
  end

  def log(str,level = :info)
    puts "#{runtime} #{level[0].upcase} - #{str}"
  end

  def runtime
    time = (Time.now-start_time).to_f
    ('%.6f' % time).rjust(12," ")
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
