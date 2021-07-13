# frozen_string_literal: true

module RQRCodeCore
  class MultiUtil
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable1-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable2-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable3-e.html
    # http://web.archive.org/web/20110710094955/http://www.denso-wave.com/qrcode/vertable4-e.html
    # Each array contains levels max bits from level 1 to level 40
    QRMAXBITS = {
      l: [152, 272, 440, 640, 864, 1088, 1248, 1552, 1856, 2192, 2592, 2960, 3424, 3688, 4184,
        4712, 5176, 5768, 6360, 6888, 7456, 8048, 8752, 9392, 10_208, 10_960, 11_744, 12_248,
        13_048, 13_880, 14_744, 15_640, 16_568, 17_528, 18_448, 19_472, 20_528, 21_616, 22_496, 23_648],
      m: [128, 224, 352, 512, 688, 864, 992, 1232, 1456, 1728, 2032, 2320, 2672, 2920, 3320, 3624,
        4056, 4504, 5016, 5352, 5712, 6256, 6880, 7312, 8000, 8496, 9024, 9544, 10_136, 10_984,
        11_640, 12_328, 13_048, 13_800, 14_496, 15_312, 15_936, 16_816, 17_728, 18_672],
      h: [72, 128, 208, 288, 368, 480, 528, 688, 800, 976, 1120, 1264, 1440, 1576, 1784,
        2024, 2264, 2504, 2728, 3080, 3248, 3536, 3712, 4112, 4304, 4768, 5024, 5288, 5608, 5960,
        6344, 6760, 7208, 7688, 7888, 8432, 8768, 9136, 9776, 10_208]
    }.freeze

    def self.smallest_size_for_multi(data, level, max_version = 40, min_version = 1)
      raise QRCodeArgumentError, "Data too long for QR Code" if min_version > max_version

      # Manually calculate max size
      # rs_blocks = QRRSBlock.get_rs_blocks(min_version, QRERRORCORRECTLEVEL[level])
      # max_size_bits = QRCode.count_max_data_bits(rs_blocks)

      # Max size table
      max_size_bits = QRMAXBITS[level][min_version - 1]

      size_bits = data.reduce(0) do |total, segment|
        mode = QRMODE[QRMODE_NAME[segment[:mode]]]
        head_len = QRUtil.get_length_in_bits(mode, min_version)

        data_len = segment_data_size(segment)
        total + 4 + head_len + data_len
      end

      return min_version if size_bits < max_size_bits

      smallest_size_for_multi(data, level, max_version, min_version + 1)
    end

    def self.segment_data_size(segment)
      length = segment[:data].length

      case segment[:mode]
      when :number
        size = (length / 3) * QRNumeric::NUMBER_LENGTH[3]
        size += QRNumeric::NUMBER_LENGTH[length % 3] if length % 3 != 0
        size
      when :alphanumeric
        size = (length / 2) * 11
        size += 6 if length.odd?
        size
      when :byte_8bit
        length * 8
      end
    end
  end
end
