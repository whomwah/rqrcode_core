require "test_helper"

# Tests for multi-segment encoding with various combinations and edge cases
class MultiSegmentEncodingTest < Minitest::Test
  # Happy path: basic multi-segment functionality
  def test_creates_valid_qr_code_with_multiple_segments
    segments = [
      {data: "123456789", mode: :number},
      {data: "HELLO-WORLD", mode: :alphanumeric},
      {data: "lower case text", mode: :byte_8bit}
    ]
    qr = RQRCodeCore::QRCode.new(segments)

    assert qr.multi_segment?, "Should be recognized as multi-segment"
    assert qr.modules.size > 0, "Should produce valid QR code"
  end

  # Core value proposition: multi-segment is more efficient than forcing all data to byte mode
  def test_multi_segment_more_efficient_than_single_byte_mode
    numeric_data = "1" * 100
    alpha_data = "A" * 100

    # Single mode (forced to byte)
    single = numeric_data + alpha_data
    qr_single = RQRCodeCore::QRCode.new(single, level: :l)

    # Multi-segment (optimized modes)
    segments = [
      {data: numeric_data, mode: :number},
      {data: alpha_data, mode: :alphanumeric}
    ]
    qr_multi = RQRCodeCore::QRCode.new(segments, level: :l)

    assert qr_multi.version <= qr_single.version, "Multi-segment should be at least as efficient"
  end

  # Determinism: same input produces same output
  def test_same_segments_produce_identical_output
    segments = [
      {data: "123", mode: :number},
      {data: "ABC", mode: :alphanumeric},
      {data: "xyz", mode: :byte_8bit}
    ]

    qr1 = RQRCodeCore::QRCode.new(segments, size: 5, level: :m)
    qr2 = RQRCodeCore::QRCode.new(segments, size: 5, level: :m)

    assert_equal qr1.modules, qr2.modules, "Same segments should produce identical output"
  end

  # Order matters: QR code content depends on segment order
  def test_segment_order_affects_output
    segments1 = [
      {data: "123", mode: :number},
      {data: "ABC", mode: :alphanumeric}
    ]

    segments2 = [
      {data: "ABC", mode: :alphanumeric},
      {data: "123", mode: :number}
    ]

    qr1 = RQRCodeCore::QRCode.new(segments1, size: 3, level: :m)
    qr2 = RQRCodeCore::QRCode.new(segments2, size: 3, level: :m)

    refute_equal qr1.modules, qr2.modules, "Different segment order should produce different output"
  end

  # Error correction levels work with multi-segment
  def test_supports_all_error_correction_levels
    segments = [
      {data: "12345", mode: :number},
      {data: "ABCDE", mode: :alphanumeric}
    ]

    %i[l m q h].each do |level|
      qr = RQRCodeCore::QRCode.new(segments, level: level)
      assert_equal level, qr.error_correction_level, "Should use specified error correction level #{level}"
    end
  end

  # Respects version constraints
  def test_respects_forced_version
    segments = [
      {data: "123", mode: :number},
      {data: "ABC", mode: :alphanumeric}
    ]

    qr = RQRCodeCore::QRCode.new(segments, size: 10)
    assert_equal 10, qr.version, "Should respect forced version"
  end

  def test_respects_max_size_constraint
    segments = [
      {data: "1" * 100, mode: :number},
      {data: "A" * 100, mode: :alphanumeric}
    ]

    qr = RQRCodeCore::QRCode.new(segments, level: :l, max_size: 20)
    assert qr.version <= 20, "Should respect max_size"
  end

  # Handles large data
  def test_handles_large_multi_segment_data
    segments = [
      {data: "1" * 200, mode: :number},
      {data: "A" * 150, mode: :alphanumeric},
      {data: "x" * 100, mode: :byte_8bit}
    ]
    qr = RQRCodeCore::QRCode.new(segments, level: :l)

    assert qr.version <= 40, "Should fit within maximum version"
  end

  def test_larger_segments_require_larger_version
    small_segments = [
      {data: "123", mode: :number},
      {data: "ABC", mode: :alphanumeric}
    ]

    large_segments = [
      {data: "1" * 300, mode: :number},
      {data: "A" * 200, mode: :alphanumeric}
    ]

    qr_small = RQRCodeCore::QRCode.new(small_segments, level: :h)
    qr_large = RQRCodeCore::QRCode.new(large_segments, level: :h)

    assert qr_small.version < qr_large.version, "Larger segments should require larger version"
  end

  # Edge cases
  def test_handles_empty_segments
    segments = [
      {data: "", mode: :byte_8bit},
      {data: "HELLO", mode: :alphanumeric},
      {data: "", mode: :number}
    ]
    qr = RQRCodeCore::QRCode.new(segments)

    assert qr.multi_segment?, "Should handle empty segments"
  end

  def test_handles_many_small_segments
    segments = 10.times.map do |i|
      {data: "SEG#{i}", mode: :alphanumeric}
    end
    qr = RQRCodeCore::QRCode.new(segments)

    assert qr.multi_segment?, "Should handle many segments"
  end

  def test_single_segment_in_array_is_still_multi_segment
    segments = [{data: "test", mode: :byte_8bit}]
    qr = RQRCodeCore::QRCode.new(segments)

    assert qr.multi_segment?, "Single segment in array should be recognized as multi-segment"
  end

  # UTF-8 and special characters
  def test_handles_utf8_characters
    segments = [
      {data: "Hello", mode: :byte_8bit},
      {data: "世界", mode: :byte_8bit}
    ]
    qr = RQRCodeCore::QRCode.new(segments)

    assert qr.modules.size > 0, "Should handle UTF-8 in segments"
  end

  def test_handles_emoji
    segments = [
      {data: "Hello", mode: :byte_8bit},
      {data: "👋🌍", mode: :byte_8bit},
      {data: "123", mode: :number}
    ]

    qr = RQRCodeCore::QRCode.new(segments)
    assert qr.modules.size > 0, "Should handle emoji in segments"
  end

  # Failure modes: invalid mode for data
  def test_raises_error_for_invalid_mode
    segments = [
      {data: "hello", mode: :alphanumeric} # lowercase not valid for alphanumeric
    ]

    assert_raises(RQRCodeCore::QRCodeArgumentError) do
      RQRCodeCore::QRCode.new(segments)
    end
  end

  def test_raises_error_when_data_too_large_for_max_size
    segments = [
      {data: "1" * 1000, mode: :number},
      {data: "A" * 1000, mode: :alphanumeric}
    ]

    assert_raises(RQRCodeCore::QRCodeRunTimeError) do
      RQRCodeCore::QRCode.new(segments, level: :h, max_size: 10)
    end
  end

  # Failure modes: invalid input structure
  def test_raises_error_for_missing_mode_key
    invalid_segment = [{data: "test"}] # missing :mode

    assert_raises(RQRCodeCore::QRCodeArgumentError) do
      RQRCodeCore::QRCode.new(invalid_segment)
    end
  end

  def test_raises_error_for_non_hash_in_array
    invalid = ["not a hash", {data: "test", mode: :byte_8bit}]

    assert_raises(RQRCodeCore::QRCodeArgumentError) do
      RQRCodeCore::QRCode.new(invalid)
    end
  end

  # Real-world use cases
  def test_url_broken_into_optimized_segments
    segments = [
      {data: "HTTPS://", mode: :alphanumeric},
      {data: "example.com", mode: :byte_8bit},
      {data: "/PATH", mode: :alphanumeric}
    ]

    qr = RQRCodeCore::QRCode.new(segments)
    assert qr.modules.size > 0, "Should handle URL as segments"
  end

  def test_structured_data_like_wifi_config
    segments = [
      {data: "WIFI:", mode: :alphanumeric},
      {data: "T:WPA;S:", mode: :byte_8bit},
      {data: "MyNetwork", mode: :byte_8bit},
      {data: ";P:", mode: :byte_8bit},
      {data: "password123", mode: :byte_8bit},
      {data: ";;", mode: :byte_8bit}
    ]

    qr = RQRCodeCore::QRCode.new(segments)
    assert qr.modules.size > 0, "Should handle structured data segments"
  end
end
