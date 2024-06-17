# frozen_string_literal: true

require_relative 'visit_blocks'

module RQRCodeCore
  class QRUtil
    PATTERN_POSITION_TABLE = [
      [],
      [6, 18],
      [6, 22],
      [6, 26],
      [6, 30],
      [6, 34],
      [6, 22, 38],
      [6, 24, 42],
      [6, 26, 46],
      [6, 28, 50],
      [6, 30, 54],
      [6, 32, 58],
      [6, 34, 62],
      [6, 26, 46, 66],
      [6, 26, 48, 70],
      [6, 26, 50, 74],
      [6, 30, 54, 78],
      [6, 30, 56, 82],
      [6, 30, 58, 86],
      [6, 34, 62, 90],
      [6, 28, 50, 72, 94],
      [6, 26, 50, 74, 98],
      [6, 30, 54, 78, 102],
      [6, 28, 54, 80, 106],
      [6, 32, 58, 84, 110],
      [6, 30, 58, 86, 114],
      [6, 34, 62, 90, 118],
      [6, 26, 50, 74, 98, 122],
      [6, 30, 54, 78, 102, 126],
      [6, 26, 52, 78, 104, 130],
      [6, 30, 56, 82, 108, 134],
      [6, 34, 60, 86, 112, 138],
      [6, 30, 58, 86, 114, 142],
      [6, 34, 62, 90, 118, 146],
      [6, 30, 54, 78, 102, 126, 150],
      [6, 24, 50, 76, 102, 128, 154],
      [6, 28, 54, 80, 106, 132, 158],
      [6, 32, 58, 84, 110, 136, 162],
      [6, 26, 54, 82, 110, 138, 166],
      [6, 30, 58, 86, 114, 142, 170]
    ].freeze

    G15 = (1 << 10) | (1 << 8) | (1 << 5) | (1 << 4) | (1 << 2) | (1 << 1) | (1 << 0)
    G18 = (1 << 12) | (1 << 11) | (1 << 10) | (1 << 9) | (1 << 8) | (1 << 5) | (1 << 2) | (1 << 0)
    G15_MASK = (1 << 14) | (1 << 12) | (1 << 10) | (1 << 4) | (1 << 1)

    DEMERIT_POINTS_1 = 3
    DEMERIT_POINTS_2 = 3
    DEMERIT_POINTS_3 = 40
    DEMERIT_POINTS_4 = 10

    DEMERIT_POINTS_1_THRESHOLD = 5

    BITS_FOR_MODE = {
      QRMODE[:mode_number] => [10, 12, 14],
      QRMODE[:mode_alpha_numk] => [9, 11, 13],
      QRMODE[:mode_8bit_byte] => [8, 16, 16],
      QRMODE[:mode_kanji] => [8, 10, 12]
    }.freeze

    # This value is used during the right shift zero fill step. It is
    # auto set to 32 or 64 depending on the arch of your system running.
    # 64 consumes a LOT more memory. In tests it's shown changing it to 32
    # on 64 bit systems greatly reduces the memory footprint. You can use
    # RQRCODE_CORE_ARCH_BITS to make this change but beware it may also
    # have unintended consequences so use at your own risk.
    ARCH_BITS = ENV.fetch('RQRCODE_CORE_ARCH_BITS', nil)&.to_i || (1.size * 8)

    def self.max_size
      PATTERN_POSITION_TABLE.count
    end

    def self.get_bch_format_info(data)
      d = data << 10
      while QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G15) >= 0
        d ^= (G15 << (QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G15)))
      end
      ((data << 10) | d) ^ G15_MASK
    end

    def self.rszf(num, count)
      # right shift zero fill
      (num >> count) & ((1 << (ARCH_BITS - count)) - 1)
    end

    def self.get_bch_version(data)
      d = data << 12
      while QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G18) >= 0
        d ^= (G18 << (QRUtil.get_bch_digit(d) - QRUtil.get_bch_digit(G18)))
      end
      (data << 12) | d
    end

    def self.get_bch_digit(data)
      digit = 0

      while data != 0
        digit += 1
        data = QRUtil.rszf(data, 1)
      end

      digit
    end

    def self.get_pattern_positions(version)
      PATTERN_POSITION_TABLE[version - 1]
    end

    def self.get_mask(mask_pattern, i, j)
      if mask_pattern > QRMASKCOMPUTATIONS.size
        raise QRCodeRunTimeError, "bad mask_pattern: #{mask_pattern}"
      end

      QRMASKCOMPUTATIONS[mask_pattern].call(i, j)
    end

    def self.get_error_correct_polynomial(error_correct_length)
      a = QRPolynomial.new([1], 0)

      (0...error_correct_length).each do |i|
        a = a.multiply(QRPolynomial.new([1, QRMath.gexp(i)], 0))
      end

      a
    end

    def self.get_length_in_bits(mode, version)
      if !QRMODE.value?(mode)
        raise QRCodeRunTimeError, "Unknown mode: #{mode}"
      end

      if version > 40
        raise QRCodeRunTimeError, "Unknown version: #{version}"
      end

      if version.between?(1, 9)
        # 1 - 9
        macro_version = 0
      elsif version <= 26
        # 10 - 26
        macro_version = 1
      elsif version <= 40
        # 27 - 40
        macro_version = 2
      end

      BITS_FOR_MODE[mode][macro_version]
    end

    def self.get_lost_points(modules)
      demerit_points = 0

      if modules.size >= 3
        VisitBlocks.new(modules).visit do |*args|
          demerit_points += QRUtil.demerit_points_1_same_color(*args)
          demerit_points += QRUtil.demerit_points_2_full_blocks(*args)
        end
      end

      demerit_points += QRUtil.demerit_points_3_dangerous_patterns(modules)
      demerit_points += QRUtil.demerit_points_4_dark_ratio(modules)
      demerit_points
    end

    def self.demerit_points_1_same_color(tl, t, tr, l, c, r, bl, b, br)
      same_count = [tl, t, tr, l, r, bl, b, br].select { _1 == c }.count
      return 0 unless same_count > DEMERIT_POINTS_1_THRESHOLD

      DEMERIT_POINTS_1 + same_count - DEMERIT_POINTS_1_THRESHOLD
    end

    def self.demerit_points_2_full_blocks(_tl, _t, _tr, _l, c, r, _bl, b, br)
      return DEMERIT_POINTS_2 if c == r && c == b && c == br

      0
    end

    def self.demerit_points_3_dangerous_patterns(modules)
      demerit_points = 0

      # level 3
      modules.each do |row|
        row.each_cons(7) do |cells|
          demerit_points += DEMERIT_POINTS_3 if dangerous_pattern?(cells)
        end
      end

      modules.transpose.each do |col|
        col.each_cons(7) do |cells|
          demerit_points += DEMERIT_POINTS_3 if dangerous_pattern?(cells)
        end
      end

      demerit_points
    end

    def self.dangerous_pattern?(cells)
      cells[0] && !cells[1] && cells[2] && cells[3] && cells[4] && !cells[5] && cells[6]
    end

    def self.demerit_points_4_dark_ratio(modules)
      # level 4
      dark_count = modules.reduce(0) do |sum, col|
        sum + col.count(true)
      end

      ratio = dark_count / (modules.size * modules.size)
      ratio_delta = (100 * ratio - 50).abs / 5

      ratio_delta * DEMERIT_POINTS_4
    end
  end
end
