require 'ragweed'
require 'ragweed/debuggerosx'

class GtaScm::Process

  attr_accessor :pid
  attr_accessor :process
  # attr_accessor :symbols
  attr_accessor :thread_symbols
  attr_accessor :symbols_var_offsets
  attr_accessor :symbols_var_types
  attr_accessor :symbols_label_offsets
  attr_accessor :max_var_offset

  attr_accessor :regions

  def initialize()
     self.regions = {}
     self.thread_symbols = {}
  end

  def detect_pid!
    self.pid = `ps -A | grep -m1 'San Andreas.app' | awk '{print $1}'`.to_i
  end

  def attach!
    begin
      self.process = Ragweed::Debuggerosx.new(self.pid)
    rescue Ragweed::Wraposx::KernelCallError
      nil
    end
  end

  def attached?
    begin
      return false if !self.pid
      return false if !self.process
      self.read(self.scm_offset,1)
      return true
    rescue Ragweed::Wraposx::KernelCallError
      self.pid = nil
      false
    rescue Ragweed::Wraposx::KErrno::INVALID_ARGUMENT
      self.pid = nil
      false
    end
  end

  def detect_pid_and_attach!
    detect_pid! if !self.pid
    attach!
  end

  def load_symbols!(path = "./symbols.gta-scm-symbols")
    symbols = JSON.parse( File.read(path).strip )

    self.symbols_var_offsets = {}
    self.symbols_var_types = {}
    symbols["variables"].each_pair do |offset,(name,type)|
      self.symbols_var_offsets[name] = offset.to_i
      self.symbols_var_types[offset.to_i] = type
    end
    self.max_var_offset = self.symbols_var_offsets.values.max

    self.symbols_label_offsets = symbols["labels"]

    symbols["ranges"].each_pair do |name,(start_offset,end_offset)|
      self.regions[ Range.new(start_offset,end_offset) ] = name
    end

    # self.load_rpc_region!
  end

  def load_thread_symbols!(thread_name,path)
    self.thread_symbols[thread_name] = JSON.parse( File.read(path) )
  end

  # def load_rpc_region!
  #   start_offset = self.symbols_label_offsets["rpc_header_prologue"]
  #   end_offset   = self.symbols_label_offsets["rpc_header_epilogue"]
  #   self.regions[ Range.new(start_offset,end_offset) ] = "rpc"
  # end

  def scm_offset
    # SA steam version
    10664568
  end

  def thread_control_block_offset
    # SA steam version
    10933576
  end

  def thread_size
    224
  end

  def thread_max
    96
  end

  def read(offset,size)
    Ragweed::Wraposx::vm_read(self.process.task,offset,size)
  end

  def write(offset,value)
    Ragweed::Wraposx::Libc.vm_write(self.process.task, offset, value, value.size)
  end

  def threads
    threads = []
    start = self.thread_control_block_offset
    stop = start + (self.thread_size * self.thread_max)
    addr = start
    while addr < stop
      bytes = Ragweed::Wraposx::vm_read(process.task,addr,self.thread_size)
      bytes = GtaScm::FileWalker.new( StringIO.new(bytes) )
      thread = GtaScm::ThreadSa.new
      thread.scm_offset = self.scm_offset
      thread.thread_id = threads.size
      thread.offset = addr
      thread.eat!( bytes )
      threads << thread
      addr += self.thread_size
    end
    threads
  end

  def thread(thread_id)
    
  end

  def write_thread(thread_id,thread)
    
  end

  def scm
    
  end

  def rpc(syscall_id,*rpc_args)

    syscall_args = parse_rpc_args(rpc_args)

    if self.read_scm_var( :var_debug_rpc_syscall , :int32 ) != 0
      raise "rpc id is already set (execution in progress?)"
    end

    puts "performing rpc id #{syscall_id} with args #{syscall_args.inspect}"
    syscall_args.each_with_index do |arg,idx|
      self.write_scm_var( :"var_debug_rpc_int_arg_#{idx}" , arg , nil )
    end
    self.write_scm_var( :"var_debug_rpc_syscall" , syscall_id , :int32 )

    # puts "waiting for result"
    until self.read_scm_var( :"var_debug_rpc_syscall" , :int32 ) == 0
      sleep 1.0 / 30
    end

    result = self.read_scm_var( :"var_debug_rpc_syscall_result" , :int32 )
    # puts "result: #{result.inspect}"
    result
  end

  def parse_rpc_args(args)
    syscall_args = []
    args.map(&:to_s).each do |arg|
      case arg
      when /label:(\w+)/
        value = self.scm_label_offset_for($1)
        value = GtaScm::Types.value2bin(value,:int32)
        syscall_args << value
      when/[a-z_]/i
        value = GtaScm::Types.value2bin(arg,:istring8)
        syscall_args << value
      when /\./
        value = GtaScm::Types.value2bin(arg.to_f,:float32)
        syscall_args << value
      else
        value = GtaScm::Types.value2bin(arg.to_i,:int32)
        syscall_args << value
      end
    end
    syscall_args
  end

  # TODO: bulk-read with vm_read for performance?
  def read_scm_var(scm_var_offset,type = nil,size = nil)
    scm_var_offset = scm_var_offset_for(scm_var_offset) if !scm_var_offset.is_a?(Numeric)

    offset = self.scm_offset + scm_var_offset

    type = :float32 if type == :float
    type = :int32 if type == :int

    size ||= GtaScm::Types.bytes4type(type)

    # bytes = Ragweed::Wraposx::vm_read(process.task,offset,size)
    bytes = self.read(offset,size)

    value = if type
      GtaScm::Types.bin2value(bytes,type)
    else
      bytes
    end

    # logger.info "read_variable #{scm_var_offset}, #{type} = #{hex(bytes)} #{"#{type} #{value.inspect})" if type}"
    value
  end

  def write_scm_var(scm_var_offset,value,type = nil)
    scm_var_offset = scm_var_offset_for(scm_var_offset) if !scm_var_offset.is_a?(Numeric)

    offset = self.scm_offset + scm_var_offset

    value = GtaScm::Types.value2bin(value,type) if !type.nil?

    # logger.info "write_variable #{scm_var_offset}, #{value} #{"(#{type} #{value.inspect}" if type}"
    # Ragweed::Wraposx::Libc.vm_write(self.process.task, offset, value, value.size)
    self.write(offset,value)
  end

  def scm_var_offset_for(variable_name)
    variable_name = variable_name.to_s
    self.symbols_var_offsets[variable_name] || raise("no scm_var_offset_for #{variable_name.inspect}")
  end

  def scm_label_offset_for(label_name)
    label_name = label_name.to_s
    self.symbols_label_offsets[label_name] || raise("no scm_label_offset_for #{label_name.inspect}")
  end



  def osascript(script)
    system 'osascript', *script.split(/\n/).map { |line| ['-e', line] }.flatten
  end

  def launch!
    # system "/Users/barry/Library/Application Support/Steam/steamapps/common/grand theft auto - san andreas/Grand Theft Auto - San Andreas.app/Contents/MacOS/cider -psn"
    system "sudo -s -u barry -- open steam://run/12250"
  end

  def kill!
    `kill -TERM #{self.pid}`
  end

  def launch_and_ready!
    puts "launching process"
    self.launch!
    loop do
      self.detect_pid!
      # puts process.pid.inspect
      mem_kb = `ps -o rss= -p #{self.pid}`.strip.to_i
      if mem_kb > 100_000
        break
      end
      sleep 0.1
    end
    sleep 1.0
    puts "self.skip_cutscenes!"
    self.skip_cutscenes!
    sleep 6.0
    puts "self.toggle_fullscreen!"
    self.toggle_fullscreen!
    sleep 5.0
    puts "self.move_window_to_corner!"
    self.move_window_to_corner!
  end

  def skip_cutscenes!
    self.osascript <<-TEXT
      tell application "Grand Theft Auto San Andreas"
        activate
        delay 0.2
        tell application "System Events"
          delay 0.25
          key code 36
          delay 0.25
          key code 36
        end
      end
    TEXT
  end

  def toggle_fullscreen!
    self.osascript <<-TEXT
      tell application "Grand Theft Auto San Andreas"
        activate
        delay 0.2
        tell application "System Events"
          key code 36 using command down
        end
      end
    TEXT
  end

  def move_window_to_corner!
    self.osascript <<-TEXT
    tell application "System Events"
        tell application "Grand Theft Auto San Andreas" to activate
        delay 0.5
        set position of window "Grand Theft Auto San Andreas" of application process "Grand Theft Auto San Andreas" to {320, 20}
      end
    TEXT
  end


end
