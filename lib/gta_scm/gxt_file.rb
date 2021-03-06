class GtaScm::GxtFile < GtaScm::FileWalker

  attr_accessor :encoding

  attr_accessor :tabl
  attr_accessor :tkey

  attr_accessor :reverse_crc32

  attr_accessor :strings
  attr_accessor :strings_order
  attr_accessor :rebuilt

  # ===================

  def initialize(file)
    super(file,0,nil)

    self.tabl = {}
    self.tkey = Hash.new { |hash, key| hash[key] = {} }

    self.strings = Hash.new { |hash, key| hash[key] = {} }
    # self.strings = Hash.new
    self.strings_order = []
  end



  TABL_BYTES = 12
  def read_tabl!
    _tabl = self.read(4).map(&:chr).join
    raise "Magic number 'TABL' not found (got #{hex(_tabl)})" if _tabl != 'TABL'

    tabl_size = GtaScm::Types.bin2value( self.read(4) , :int32 )
    # logger.info "tabl_size: #{tabl_size}"

    (tabl_size / TABL_BYTES).times do |idx|
      name = self.read(8).map(&:chr).join.strip
      offset = GtaScm::Types.bin2value( self.read(4) , :int32 )
      self.tabl[name] = offset
      # logger.info "#{name.inspect} #{offset}"
    end
  end

  def read_tabl_sa!
    encoding = self.read(4).map(&:chr).join
    # raise "Magic number 'TABL' not found (got #{hex(_tabl)})" if _tabl != 'TABL'
    case encoding
    when
      "\x04\x00\x08\x00"
      self.encoding = :ascii
    else
      raise "unknown encoding #{_tabl.inspect} (#{hex(_table)})"
    end
    _tabl = self.read(4).map(&:chr).join

    puts _tabl

    tabl_size = GtaScm::Types.bin2value( self.read(4) , :int32 )

    puts tabl_size

    (tabl_size / TABL_BYTES).times do |idx|
      name = self.read(8).map(&:chr).join.strip
      offset = GtaScm::Types.bin2value( self.read(4) , :int32 )
      self.tabl[name] = offset
      # logger.info "#{name.inspect} #{offset}"
    end
  end

  TKEY_BYTES = 12
  def read_tkey!
    self.tabl.each_pair do |tabl_name,offset|
      # logger.info "reading tkey for #{tabl_name} at #{offset}"
      self.seek(offset)

      if tabl_name == "MAIN"
        name = ""
      else
        name = self.read(8).map(&:chr).join.strip
      end
      _tkey = self.read(4).map(&:chr).join.strip
      size = GtaScm::Types.bin2value( self.read(4) , :int32 )

      # logger.info "  got #{name.inspect} #{_tkey} #{size}"

      (size / TKEY_BYTES).times do |idx|
        tdat_offset = GtaScm::Types.bin2value( self.read(4) , :int32 )
        tdat_name = self.read(8).map(&:chr).join.strip
        self.tkey[tabl_name][tdat_name] = [tdat_offset,size]
        # logger.info "    tdat #{tdat_name} #{tdat_offset}"
      end
    end
  end

  def read_tkey_sa!
    self.tabl.each_pair do |tabl_name,offset|
      # logger.info "reading tkey for #{tabl_name} at #{offset}"
      self.seek(offset)

      if tabl_name == "MAIN"
        name = ""
      else
        name = self.read(8).map(&:chr).join.strip
      end
      _tkey = self.read(4).map(&:chr).join.strip
      size = GtaScm::Types.bin2value( self.read(4) , :int32 )

      (size / 8).times do |i|
        entry_offset = GtaScm::Types.bin2value( self.read(4) , :int32 )
        # entry_crc32 = GtaScm::Types.bin2value( self.read(4) , :int32 )
        # entry_crc32 = self.read(4)
        entry_crc32_b = self.read(4)
        entry_crc32 = GtaScm::Types.bin2value( entry_crc32_b , :uint32 )
        # puts "crc32 #{hex(entry_crc32_b)} = #{entry_offset}"
        self.tkey[tabl_name][entry_crc32] = entry_offset
      end

      # logger.info "  got #{name.inspect} #{_tkey} #{size}"

      _tdat = self.read(4).map(&:chr).join.strip
      # puts _tdat
      tdat_size = GtaScm::Types.bin2value( self.read(4) , :int32 )
      # puts tdat_size

      string_block_start = self.offset

      self.tkey[tabl_name].each_pair do |entry_crc32,entry_offset|
        self.seek( string_block_start + entry_offset )
        str = ""
        loop do
          char = self.read(1)[0]
          if char == 0
            break
            # if self.read_no_advance(1)[0] != 0
            #   puts "breaking at #{self.offset}"
            #   break
            # else
            #   puts "multiple nulls found in #{self.offset} #{str.inspect} "
            # end
          end
          str << char.chr
        end
        self.strings[tabl_name][entry_crc32] = str.force_encoding("Windows-1252").encode("UTF-8")
      end
    end
  end

  def read_reverse_crc32!
    self.reverse_crc32 = {}
    path = "./games/san-andreas/Text/american.text-dump.text"
    return if !File.exists?(path)
    File.open(path,"r") do |f|
      f.lines.each do |line|
        key = line[0..8].strip
        crc32 = gxt_crc32(key)
        # entry_crc32 = GtaScm::Types.value2bin( crc32 , :uint32 )
        self.reverse_crc32[crc32] = key
      end
    end
  end

  def gxt_crc32(str)
    table = [
      0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA,
      0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
      0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988,
      0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
      0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE,
      0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
      0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC,
      0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
      0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172,
      0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
      0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940,
      0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
      0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116,
      0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
      0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924,
      0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,
      0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A,
      0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
      0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818,
      0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
      0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
      0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
      0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C,
      0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
      0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2,
      0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
      0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0,
      0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
      0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086,
      0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
      0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4,
      0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,
      0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A,
      0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
      0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8,
      0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
      0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE,
      0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
      0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC,
      0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
      0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252,
      0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
      0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60,
      0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
      0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236,
      0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
      0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04,
      0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
      0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A,
      0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
      0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38,
      0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
      0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E,
      0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
      0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C,
      0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
      0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2,
      0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
      0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0,
      0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
      0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6,
      0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
      0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94,
      0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D
    ]

    reg = 0xFFFFFFFF

    str.bytes.each do |byte|
      break if byte == 0
      reg = (reg >> 8) ^ table[ byte ^ (reg & 0xFF) ]
    end

    return reg
  end

  def read_tdat!
    self.tkey.each_pair do |tabl_name,tdats|
      tdats.keys.each do |tdat_name|
        tdat = tdats[tdat_name]
        tdat_offset = tdat[0]
        tkey_size = tdat[1]
        tkey_offset = self.tabl[tabl_name]
        offset = tkey_offset + tkey_size
        if tabl_name == "MAIN"
          offset += 8
        else
          offset += 16
        end
        _tdat = self.read(4).map(&:chr).join
        offset = offset + 8 + tdat_offset
        self.seek(offset)
        self.strings[tabl_name][tdat_name] = read_string
      end
    end
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
    # logger.info "tdat #{_tdat} #{size}"
  end

  attr_accessor :tkey_counter
  def add_entry(key1,key2,value)
    self.tkey_counter ||= 0
    self.tkey_counter += 1
    self.tkey[key1][ gxt_crc32(key2) ] = 999_999_999 + tkey_counter
    # need to add to self.tkey too ?
    self.strings[key1][ gxt_crc32(key2) ] = value
  end


  def rebuild!
    # files = Dir.new(DIR).entries - [".",".."]
    # files = ["000-MAIN.txt"]

    # files = files.sort
    out_head = ""
    out_str = ""

    out_head = ""
    out_head << "\x04\x00\x08\x00" # ascii encoding flag
    out_head << "TABL"
    out_head << GtaScm::Types.value2bin(self.tkey.size * 12,:int32)
    out_head_dup = out_head.dup

    out_head_tabl = (" " * 12) * self.tkey.size
    self.tkey.each_pair do |name,tkey_entry|

      # puts "reading #{filename}"
      # name = filename.gsub(/^\d+-/,"").gsub(/\.txt$/,"")

      block_offset = out_head_dup.bytesize + out_head_tabl.bytesize + out_str.bytesize
      out_head << name[0..8].ljust(8,"\0")
      out_head << GtaScm::Types.value2bin(block_offset,:int32)

      strings = {}
      lines_to_strings = []


      tkey_entry.invert.to_a.sort_by(&:first).each do |(offset,crc32)|
        text = self.strings[name][crc32]
        strings[crc32] = text
        lines_to_strings << [crc32,text]
      end

      header_size = 0
      header_size += 8 if name != "MAIN"
      header_size += 4
      header_size += 4
      header_size += strings.size * 8
      header_size += 4
      header_size += 4

      # sort strings by crc32 ascending

      # output all strings, store crc32 => string offset in hash

      crcs_to_offsets = {}
      text_block = "".encode("Windows-1252")

      lines_to_strings.each do |(crc32,string)|
        crcs_to_offsets[crc32] = text_block.bytes.size
        text_block << string.encode("Windows-1252") << "\0"
      end

      text_block_size = text_block.bytesize
      if text_block.bytesize % 4 != 0
        case text_block.size % 4
        when 1
          text_block << "\0\0\0"
        when 2
          text_block << "\0\0"
        when 3
          text_block << "\0"
        end
      end



      # puts "building"

      tkey_header = ""
      if name != "MAIN"
        tkey_header << "#{name.ljust(8,"\0")}"
      end
      tkey_header << "TKEY"
      tkey_header << GtaScm::Types.value2bin(crcs_to_offsets.size * 8,:int32)
      crcs_to_offsets.keys.sort.each do |crc32|
        tkey_header << GtaScm::Types.value2bin(crcs_to_offsets[crc32],:int32)
        tkey_header << GtaScm::Types.value2bin(crc32,:int32)
      end
      tkey_header << "TDAT"
      tkey_header << GtaScm::Types.value2bin(text_block_size,:int32)

      out_str << tkey_header
      out_str << text_block.force_encoding("ASCII-8BIT")


      # GXT File structure
      # encoding - 4 bytes
      # TABL - 4 bytes
      # table count, divided by 12
      # table list
      #   name - 8 bytes
      #   block offset - 4 bytes

      # Multiple GXT Blocks follow, as described below:

      # GXT Block structure
      # MAIN - filename, 8 bytes
      # TKEY - 4 bytes
      # number of entries, divided by 8 - 4 bytes
      # entries list
      #   entry offset - 4 bytes
      #   entry crc32  - 4 bytes
      # raw strings follow

    end

    # puts "writing"

    # File.open(PATH,"wb") do |f|
    #   f << out_head
    #   f << out_str
    # end
    return out_head + out_str
  end


end

