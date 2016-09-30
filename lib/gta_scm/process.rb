class GtaScm::Process

  attr_accessor :pid

  def initialize(pid)
    self.pid = pid || detect_pid!
  end

  def detect_pid!
    `ps -A | grep -m1 'San Andreas.app' | awk '{print $1}'`.to_i
  end

  def threads
    
  end

  def thread(thread_id)
    
  end

  def write_thread(thread_id,thread)
    
  end

  def scm
    
  end

  def read_variable(varible_offset,type)
    
  end

  def write_variable(variable_offset,type,value)
    
  end

end
