module RQRCodeCore
  class MultiUtil

    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable1-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable2-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable3-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable4-e.html
    # Each array contains levels max bits from level 1 to level 40
    QRMAXBITS = {
      l: [152, 272, 440, 640, 864, 1088, 1248, 1552, 1856, 2192, 2592, 2960, 3424, 3688, 4184,
          4712, 5176, 5768, 6360, 6888, 7456, 8048, 8752, 9392, 10208, 10960, 11744, 12248,
          13048, 13880, 14744, 15640, 16568, 17528, 18448, 19472, 20528, 21616, 22496, 23648],
      m: [128, 224, 352, 512, 688, 864, 992, 1232, 1456, 1728, 2032, 2320, 2672, 2920, 3320, 3624,
          4056, 4504, 5016, 5352, 5712, 6256, 6880, 7312, 8000, 8496, 9024, 9544, 10136, 10984,
          11640, 12328, 13048, 13800, 14496, 15312, 15936, 16816, 17728, 18672],
      h: [72, 128, 208, 288, 368, 480, 528, 688, 800, 976, 1120, 1264, 1440, 1576, 1784,
          2024, 2264, 2504, 2728, 3080, 3248, 3536, 3712, 4112, 4304, 4768, 5024, 5288, 5608, 5960,
        6344, 6760, 7208, 7688, 7888, 8432, 8768, 9136, 9776, 10208]
    }
  
    def self.smallest_size_for_multi(data, level, max_version=40, min_version=1)
      raise QRCodeArgumentError, 'Data too long for QR Code' if min_version > max_version

      # Manually calculate max size
      # rs_blocks = QRRSBlock.get_rs_blocks(min_version, QRERRORCORRECTLEVEL[level])
      # max_size_bits = QRCode.count_max_data_bits(rs_blocks)

      # Max size table
      max_size_bits = QRMAXBITS[level][min_version - 1]
      
      size_bits = data.reduce(0) do |total, segment|
        mode = QRMODE[QRMODE_NAME[segment[:mode]]]
        head_len = QRUtil.get_length_in_bits(mode, min_version) 
        data_len = segment[:data].bytesize * 8
        total += (4 + head_len + data_len)
      end

      return min_version if size_bits < max_size_bits

      smallest_size_for_multi(data, level, max_version, min_version+1)
    end

  end
end