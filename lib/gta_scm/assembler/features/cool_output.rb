
module GtaScm::Assembler::Feature::CoolOutput
  def on_feature_init
    super

    class << self
      attr_accessor :cool_logger
      attr_accessor :cool_logger_options
      attr_accessor :cool_logger_state
    end

    logger.warn "Disabling further logging for ~CoolOutput~"
    logger.level = :none

    self.cool_logger = GtaScm::Logger.new(:info)
    self.cool_logger.decorations = []
    self.cool_logger.info "~CoolOutput~ logger taking over"

    self.cool_logger_options ||= {}
    self.cool_logger_options.reverse_merge!(
      console_width: 80,
    )
    self.cool_logger_state = {
      current_column: 99999,
    }
  end

  def on_node_emit(f,node,bin)
    # debugger
    print "\e[4m"

    node.hex_array.flatten.each_with_index do |hex,idx|
      # debugger
      if self.cool_logger_state[:current_column] >= self.cool_logger_options[:console_width]
        self.cool_logger_state[:current_column] = 0
        print "\r\n"
        addr = f.pos + idx
        addr_str = " #{addr.to_s.rjust(7,"0")} | "
        print "\e[24m\e[39m"
        print addr_str
        print "\e[4m"
        self.cool_logger_state[:current_column] += addr_str.size
      else
        if idx == 0
          print "\e[24m"
        end
        print " "
        if idx == 0
          print "\e[4m"
        end
        self.cool_logger_state[:current_column] += 1
      end

      esc_code = "\e[39m"
      if idx == 0 or idx == 1
        esc_code = "\e[95m"
      end
      print "#{esc_code}"

      print "#{hex[0]}"
      sleep 0.01
      print "#{hex[1]}"
      sleep 0.01

      if idx == 1
        print "\e[39m"
      end

      self.cool_logger_state[:current_column] += 2

    end
  end

end
