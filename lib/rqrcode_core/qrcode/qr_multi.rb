module RQRCodeCore
  class QRMulti
    def initialize(data)
      @data = data
    end

    def write(buffer)
      @data.each do |seg|
        writer = QRUtil.writer_for_mode(seg[:mode], seg[:data])
        writer.write(buffer)
      end
    end
  end
end
