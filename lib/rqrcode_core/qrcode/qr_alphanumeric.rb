# frozen_string_literal: true

module RQRCodeCore
  ALPHANUMERIC = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I",
    "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", " ", "$",
    "%", "*", "+", "-", ".", "/", ":"
  ].freeze

  class QRAlphanumeric
    def initialize(data)
      raise QRCodeArgumentError, "Not a alpha numeric uppercase string `#{data}`" unless QRAlphanumeric.valid_data?(data)

      @data = data
    end

    def self.valid_data? data
      data.each_char do |s|
        return false if ALPHANUMERIC.index(s).nil?
      end
      true
    end

    def write(buffer)
      buffer.alphanumeric_encoding_start(@data.size)

      @data.size.times do |i|
        if i % 2 == 0
          if i == (@data.size - 1)
            value = ALPHANUMERIC.index(@data[i])
            buffer.put(value, 6)
          else
            value = (ALPHANUMERIC.index(@data[i]) * 45) + ALPHANUMERIC.index(@data[i + 1])
            buffer.put(value, 11)
          end
        end
      end
    end
  end
end
