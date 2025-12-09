require "test_helper"

# High-level tests that verify QR code output correctness across various scenarios
# These tests focus on structural integrity and consistency rather than internal implementation
class OutputVerificationTest < Minitest::Test
  def test_module_count_matches_version_formula
    # QR Code size formula: version * 4 + 17
    # Version 1 = 21x21, Version 10 = 57x57, etc.
    [1, 2, 5, 10, 20, 30, 40].each do |version|
      qr = RQRCodeCore::QRCode.new("test", size: version)
      expected_size = version * 4 + 17
      assert_equal expected_size, qr.module_count, "Version #{version} should have module_count of #{expected_size}"
      assert_equal expected_size, qr.modules.size, "Version #{version} should have #{expected_size} rows"
      qr.modules.each_with_index do |row, i|
        assert_equal expected_size, row.size, "Version #{version}, row #{i} should have #{expected_size} columns"
      end
    end
  end

  def test_modules_contain_only_boolean_values
    qr = RQRCodeCore::QRCode.new("test data", size: 5)
    qr.modules.each_with_index do |row, r|
      row.each_with_index do |col, c|
        assert [true, false].include?(col), "Module at [#{r}][#{c}] should be boolean, got #{col.inspect}"
      end
    end
  end

  def test_checked_method_returns_boolean
    qr = RQRCodeCore::QRCode.new("hello")
    (0...qr.module_count).each do |row|
      (0...qr.module_count).each do |col|
        result = qr.checked?(row, col)
        assert [true, false].include?(result), "checked?(#{row}, #{col}) should return boolean"
      end
    end
  end

  def test_to_s_output_dimensions
    qr = RQRCodeCore::QRCode.new("test", size: 3)
    output = qr.to_s
    lines = output.split("\n")

    assert_equal qr.module_count, lines.size, "to_s should produce module_count lines"
    lines.each_with_index do |line, i|
      assert_equal qr.module_count, line.length, "Line #{i} should have module_count characters"
    end
  end

  def test_to_s_with_quiet_zone
    qr = RQRCodeCore::QRCode.new("test", size: 2)

    [1, 2, 4].each do |zone_size|
      output = qr.to_s(quiet_zone_size: zone_size, dark: "x", light: " ")
      lines = output.split("\n")

      expected_line_count = qr.module_count + (zone_size * 2)

      # Top and bottom quiet zone rows should be added
      assert_equal expected_line_count, lines.size,
        "With quiet_zone_size=#{zone_size}, should have #{expected_line_count} lines"

      # Check that top quiet zone lines are all spaces (light)
      zone_size.times do |i|
        assert lines[i].strip.empty?, "Top quiet zone row #{i} should be all light characters"
      end

      # Check that bottom quiet zone lines are all spaces (light)
      zone_size.times do |i|
        row_idx = lines.size - zone_size + i
        assert lines[row_idx].strip.empty?, "Bottom quiet zone row #{row_idx} should be all light characters"
      end

      # Check that quiet zones are on sides of content rows
      content_start = zone_size
      content_end = lines.size - zone_size - 1
      (content_start..content_end).each do |row_idx|
        line = lines[row_idx]
        # Lines should start and end with quiet zone spaces
        assert line.start_with?(" " * zone_size), "Content row #{row_idx} should start with #{zone_size} spaces"
      end
    end
  end

  def test_to_s_with_custom_characters
    qr = RQRCodeCore::QRCode.new("test", size: 1)

    # Test with single character dark/light
    output1 = qr.to_s(dark: "#", light: ".")
    assert output1.include?("#"), "Output should contain dark character #"
    assert output1.include?("."), "Output should contain light character ."
    refute output1.include?("x"), "Output should not contain default dark character"

    # Test with multi-character dark/light
    output2 = qr.to_s(dark: "██", light: "  ")
    lines = output2.split("\n")
    lines.each do |line|
      assert_equal qr.module_count * 2, line.length, "Multi-char output should double the line length"
    end
  end

  def test_cross_version_consistency_for_same_data
    data = "https://github.com/whomwah/rqrcode_core"
    levels = %i[l m q h]

    levels.each do |level|
      qr = RQRCodeCore::QRCode.new(data, level: level)

      # Verify basic properties
      assert qr.version >= 1, "Version should be at least 1"
      assert qr.version <= 40, "Version should not exceed 40"
      assert_equal level, qr.error_correction_level, "Error correction level should match requested"

      # Verify module structure
      assert qr.modules.size > 0, "Should have modules"
      assert qr.module_count == qr.modules.size, "module_count should match modules array size"
    end
  end

  def test_version_attribute_matches_requested_size
    [1, 5, 10, 15, 25, 40].each do |size|
      qr = RQRCodeCore::QRCode.new("test", size: size)
      assert_equal size, qr.version, "version attribute should match requested size"
    end
  end

  def test_error_correction_level_attribute
    data = "test"

    {l: :l, m: :m, q: :q, h: :h}.each do |input, expected|
      qr = RQRCodeCore::QRCode.new(data, level: input)
      assert_equal expected, qr.error_correction_level, "Should return #{expected} for level #{input}"
    end
  end

  def test_same_input_produces_consistent_output
    data = "consistency test"

    qr1 = RQRCodeCore::QRCode.new(data, size: 3, level: :h)
    qr2 = RQRCodeCore::QRCode.new(data, size: 3, level: :h)

    assert_equal qr1.modules, qr2.modules, "Same input should produce identical modules"
    assert_equal qr1.to_s, qr2.to_s, "Same input should produce identical string output"
  end

  def test_different_levels_produce_different_outputs
    data = "test data"

    qr_l = RQRCodeCore::QRCode.new(data, size: 3, level: :l)
    qr_m = RQRCodeCore::QRCode.new(data, size: 3, level: :m)
    qr_q = RQRCodeCore::QRCode.new(data, size: 3, level: :q)
    qr_h = RQRCodeCore::QRCode.new(data, size: 3, level: :h)

    # Different error correction levels should produce different patterns
    refute_equal qr_l.modules, qr_m.modules
    refute_equal qr_l.modules, qr_q.modules
    refute_equal qr_l.modules, qr_h.modules
    refute_equal qr_m.modules, qr_q.modules
  end

  def test_inspect_output_format
    qr = RQRCodeCore::QRCode.new("test", size: 4, level: :h)
    inspect_str = qr.inspect

    assert inspect_str.include?("QRCodeCore"), "inspect should include class name"
    assert inspect_str.include?("@version=4"), "inspect should include version"
    assert inspect_str.include?("@module_count=33"), "inspect should include module_count (4*4+17=33)"
  end

  def test_position_patterns_are_present
    # QR codes have three position detection patterns (finder patterns) in corners
    # They should be present in all QR codes
    qr = RQRCodeCore::QRCode.new("test", size: 5)

    # Top-left corner should have pattern (7x7)
    assert qr.checked?(0, 0), "Top-left corner finder pattern should be dark"
    assert qr.checked?(6, 0), "Top-left corner finder pattern edge should be dark"
    assert qr.checked?(0, 6), "Top-left corner finder pattern edge should be dark"

    # Top-right corner (offset by module_count - 7)
    offset = qr.module_count - 7
    assert qr.checked?(0, offset), "Top-right corner finder pattern should be dark"

    # Bottom-left corner
    assert qr.checked?(offset, 0), "Bottom-left corner finder pattern should be dark"
  end

  def test_timing_patterns_are_present
    # QR codes have timing patterns (alternating dark/light) at row 6 and column 6
    qr = RQRCodeCore::QRCode.new("test", size: 5)

    # Check horizontal timing pattern (row 6)
    (8...qr.module_count - 8).each do |col|
      expected = col.even?
      assert_equal expected, qr.checked?(6, col), "Timing pattern at row 6, col #{col} should be #{expected}"
    end

    # Check vertical timing pattern (column 6)
    (8...qr.module_count - 8).each do |row|
      expected = row.even?
      assert_equal expected, qr.checked?(row, 6), "Timing pattern at row #{row}, col 6 should be #{expected}"
    end
  end

  def test_mode_attribute_returns_correct_symbol
    numeric_qr = RQRCodeCore::QRCode.new("12345")
    assert_equal :mode_number, numeric_qr.mode, "Numeric data should use mode_number"

    alpha_qr = RQRCodeCore::QRCode.new("ABC123")
    assert_equal :mode_alpha_numk, alpha_qr.mode, "Alphanumeric data should use mode_alpha_numk"

    byte_qr = RQRCodeCore::QRCode.new("hello world")
    assert_equal :mode_8bit_byte, byte_qr.mode, "Mixed case data should use mode_8bit_byte"
  end

  def test_multi_segment_mode_detection
    multi_qr = RQRCodeCore::QRCode.new([
      {data: "123", mode: :number},
      {data: "ABC", mode: :alphanumeric}
    ])

    assert multi_qr.multi_segment?, "Multi-segment QR should return true for multi_segment?"

    single_qr = RQRCodeCore::QRCode.new("test")
    refute single_qr.multi_segment?, "Single-segment QR should return false for multi_segment?"
  end

  def test_qr_code_with_whitespace
    qr_with_spaces = RQRCodeCore::QRCode.new("hello world with spaces")
    qr_with_newlines = RQRCodeCore::QRCode.new("line1\nline2\nline3")
    qr_with_tabs = RQRCodeCore::QRCode.new("tab\tseparated\tvalues")

    # Should not raise errors and should produce valid QR codes
    assert qr_with_spaces.modules.size > 0
    assert qr_with_newlines.modules.size > 0
    assert qr_with_tabs.modules.size > 0
  end

  def test_qr_code_with_special_characters
    special_chars = "!@#$%^&*()_+-=[]{}|;:',.<>?/~`"
    qr = RQRCodeCore::QRCode.new(special_chars)

    assert qr.modules.size > 0, "Should handle special characters"
    assert qr.module_count > 0, "Should have valid module count"
    assert_equal :mode_8bit_byte, qr.mode, "Special characters should use byte mode"
  end

  def test_version_increases_with_data_length
    # Longer data should require larger versions (at same error correction level)
    short_data = "x" * 10
    medium_data = "x" * 100
    long_data = "x" * 500

    qr_short = RQRCodeCore::QRCode.new(short_data, level: :h)
    qr_medium = RQRCodeCore::QRCode.new(medium_data, level: :h)
    qr_long = RQRCodeCore::QRCode.new(long_data, level: :h)

    assert qr_short.version < qr_medium.version, "Medium data should require larger version than short"
    assert qr_medium.version < qr_long.version, "Long data should require larger version than medium"
  end

  def test_higher_error_correction_requires_larger_version
    # Same data with higher error correction may require larger version
    data = "x" * 50

    qr_l = RQRCodeCore::QRCode.new(data, level: :l)
    qr_h = RQRCodeCore::QRCode.new(data, level: :h)

    # Higher error correction uses more space for redundancy
    assert qr_l.version <= qr_h.version, "Higher error correction should require same or larger version"
  end
end
