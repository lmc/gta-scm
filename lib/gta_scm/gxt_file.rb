class GtaScm::GxtFile < GtaScm::FileWalker

  attr_accessor :tabl
  attr_accessor :tkey

  attr_accessor :strings
  attr_accessor :rebuilt

  # ===================

  def initialize(file)
    super(file,0,nil)

    self.tabl = {}
    self.tkey = Hash.new { |hash, key| hash[key] = {} }

    self.strings = Hash.new { |hash, key| hash[key] = {} }
  end



  TABL_BYTES = 12
  def read_tabl!
    _tabl = self.read(4).map(&:chr).join
    raise "Magic number 'TABL' not found" if _tabl != 'TABL'

    tabl_size = GtaScm::Types.bin2value( self.read(4) , :int32 )
    logger.info "tabl_size: #{tabl_size}"

    (tabl_size / TABL_BYTES).times do |idx|
      name = self.read(8).map(&:chr).join.strip
      offset = GtaScm::Types.bin2value( self.read(4) , :int32 )
      self.tabl[name] = offset
      logger.info "#{name.inspect} #{offset}"
    end
  end

  TKEY_BYTES = 12
  def read_tkey!
    self.tabl.each_pair do |tabl_name,offset|
      logger.info "reading tkey for #{tabl_name} at #{offset}"
        self.seek(offset)

      if tabl_name == "MAIN"
        name = ""
      else
        name = self.read(8).map(&:chr).join.strip
      end
      _tkey = self.read(4).map(&:chr).join.strip
      size = GtaScm::Types.bin2value( self.read(4) , :int32 )

      logger.info "  got #{name.inspect} #{_tkey} #{size}"

      (size / TKEY_BYTES).times do |idx|
        tdat_offset = GtaScm::Types.bin2value( self.read(4) , :int32 )
        tdat_name = self.read(8).map(&:chr).join.strip
        self.tkey[tabl_name][tdat_name] = [tdat_offset,size]
        logger.info "    tdat #{tdat_name} #{tdat_offset}"
      end
    end

    def read_tdat!
      self.tkey.each_pair do |tabl_name,tdats|
        # debugger
        tdats.keys.each do |tdat_name|
          tdat = tdats[tdat_name]
          tdat_offset = tdat[0]
          tkey_size = tdat[1]
          tkey_offset = self.tabl[tabl_name]
          # debugger
          offset = tkey_offset + tkey_size
          if tabl_name == "MAIN"
            offset += 8
          else
            offset += 16
          end
          # debugger
          _tdat = self.read(4).map(&:chr).join
          # tdat_size = GtaScm::Types.bin2value( self.read(4) , :int32 )
          # logger.info "tdat: #{_tdat.inspect} #{tdat_size}"

          offset = offset + 8 + tdat_offset
          self.seek(offset)

          self.strings[tabl_name][tdat_name] = read_string

          # debugger
          'dd'
            # logger.info "#{tabl_name} #{tdat_name} #{str}"

        end
        # return
      end

      # require 'pp'
      # pp self.strings
    end

    def read_string()
      str = ""
      loop do
        chr = self.read(2)
        break(1) if chr == [0x00,0x00]
        # HACK: convert to asci grossly
        str << chr[0].chr
        # str << chr.map(&:chr).join
      end
      str
    end

    def read_tdat(offset)
      self.seek(offset)
      _tdat = self.read(4).map(&:chr).join
      size = GtaScm::Types.bin2value( self.read(4) , :int32 )
      logger.info "tdat #{_tdat} #{size}"
    end
  end


  def rebuild!
    self.rebuilt = "".force_encoding("BINARY")
    self.rebuilt << "TABL"
    self.rebuilt << [0,0,0,0].map(&:chr).join
    self.strings.keys.each do |tabl_name|
      self.rebuilt << "#{tabl_name}".ljust(8,0.chr)[0..7]
      self.rebuilt << [0,0,0,0].map(&:chr).join
      # self.strings[tabl_name].keys.each do |tkey_name|
      #   self.rebuilt << "#{tkey_name}".ljust(8,0.chr)[0..7]
      #   self.rebuilt << [0,0,0,0].map(&:chr).join
      # end
    end
    debugger
    self.rebuilt
  end


end

