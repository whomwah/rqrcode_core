# frozen_string_literal: true

module RQRCodeCore
  class QR8bitByte
    attr_reader :mode

    def initialize( data )
      @mode = QRMODE[:mode_8bit_byte]
      @data = data;
    end


    def get_length
      @data.bytesize
    end


    def write( buffer)
      buffer.byte_encoding_start(get_length)
      @data.each_byte do |b|
        buffer.put(b, 8)
      end
    end
  end
end
