# frozen_string_literal: true

require "test_helper"

class RQRCodeCore::QRSegmentTest < Minitest::Test
  PAYLOAD = [{data: "byteencoded", mode: :byte_8bit}, {data: "A1" * 107, mode: :alphanumeric}, {data: "1" * 498, mode: :number}].map do |seg|
    RQRCodeCore::QRSegment.new(**seg)
  end

  def test_multi_payloads
    RQRCodeCore::QRCode.new(PAYLOAD, level: :l)
    RQRCodeCore::QRCode.new(PAYLOAD, level: :m)
    RQRCodeCore::QRCode.new(PAYLOAD, level: :q)
    RQRCodeCore::QRCode.new(PAYLOAD)
    RQRCodeCore::QRCode.new(PAYLOAD, level: :l, max_size: 22)
    # rescue => e
    #   flunk(e)
  end

  def test_invalid_code_configs
    assert_raises(RQRCodeCore::QRCodeArgumentError) {
      RQRCodeCore::QRCode.new(:not_a_string_or_array)
      RQRCodeCore::QRCode.new(PAYLOAD << :not_a_segment)
    }
  end
end
