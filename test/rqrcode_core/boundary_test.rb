require "test_helper"

# Tests for boundary conditions, edge cases, and maximum capacity scenarios
class BoundaryTest < Minitest::Test
  def test_empty_string
    # Empty string should work at all error correction levels
    %i[l m q h].each do |level|
      qr = RQRCodeCore::QRCode.new("", level: level)
      assert qr.version >= 1, "Empty string should produce valid QR code at level #{level}"
      assert qr.modules.size > 0, "Empty string should have modules at level #{level}"
    end
  end

  def test_single_character
    # Single characters in each mode
    numeric_qr = RQRCodeCore::QRCode.new("0")
    alpha_qr = RQRCodeCore::QRCode.new("A")
    byte_qr = RQRCodeCore::QRCode.new("a")

    assert_equal 1, numeric_qr.version, "Single digit should fit in version 1"
    assert_equal 1, alpha_qr.version, "Single alpha should fit in version 1"
    assert_equal 1, byte_qr.version, "Single byte should fit in version 1"
  end

  def test_all_numeric_digits
    qr = RQRCodeCore::QRCode.new("0123456789")
    assert_equal :mode_number, qr.mode, "All digits should use numeric mode"
    assert qr.modules.size > 0, "Should produce valid QR code"
  end

  def test_all_alphanumeric_characters
    # Valid alphanumeric characters: 0-9, A-Z, space, and $%*+-./:
    alpha_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
    qr = RQRCodeCore::QRCode.new(alpha_chars)
    assert_equal :mode_alpha_numk, qr.mode, "Valid alphanumeric chars should use alphanumeric mode"
  end

  def test_boundary_between_numeric_and_alphanumeric
    # Just digits: should be numeric
    assert_equal :mode_number, RQRCodeCore::QRCode.new("123456").mode

    # Digits with uppercase letter: should be alphanumeric
    assert_equal :mode_alpha_numk, RQRCodeCore::QRCode.new("123456A").mode

    # Digits with space (valid alphanumeric): should be alphanumeric
    assert_equal :mode_alpha_numk, RQRCodeCore::QRCode.new("123 456").mode
  end

  def test_boundary_between_alphanumeric_and_byte
    # Uppercase only: should be alphanumeric
    assert_equal :mode_alpha_numk, RQRCodeCore::QRCode.new("HELLO").mode

    # With lowercase: should be byte
    assert_equal :mode_8bit_byte, RQRCodeCore::QRCode.new("Hello").mode

    # With valid alphanumeric punctuation: should be alphanumeric
    assert_equal :mode_alpha_numk, RQRCodeCore::QRCode.new("HELLO-WORLD").mode

    # With invalid alphanumeric punctuation: should be byte
    assert_equal :mode_8bit_byte, RQRCodeCore::QRCode.new("HELLO_WORLD").mode
  end

  def test_maximum_version_40
    # Version 40 is the maximum QR code version
    qr = RQRCodeCore::QRCode.new("test", size: 40)
    assert_equal 40, qr.version, "Should support version 40"
    assert_equal 177, qr.module_count, "Version 40 should be 177x177 (40*4+17)"
  end

  def test_version_boundary_transitions
    # Test data lengths that sit near version boundaries
    # These lengths are chosen to be near capacity limits for version 1

    # Version 1 numeric capacity at level H: 17 digits
    assert_equal 1, RQRCodeCore::QRCode.new("1" * 17, level: :h).version
    # One more should bump to version 2
    assert_equal 2, RQRCodeCore::QRCode.new("1" * 18, level: :h).version

    # Version 1 alphanumeric capacity at level H: 10 characters
    assert_equal 1, RQRCodeCore::QRCode.new("A" * 10, level: :h).version
    # One more should bump to version 2
    assert_equal 2, RQRCodeCore::QRCode.new("A" * 11, level: :h).version

    # Version 1 byte capacity at level H: 7 bytes
    assert_equal 1, RQRCodeCore::QRCode.new("a" * 7, level: :h).version
    # One more should bump to version 2
    assert_equal 2, RQRCodeCore::QRCode.new("a" * 8, level: :h).version
  end

  def test_exact_capacity_for_version_1_all_levels
    # Test exact maximum capacity for version 1 at each error correction level

    # Level L: 25 alphanumeric characters
    assert_equal 1, RQRCodeCore::QRCode.new("A" * 25, level: :l).version

    # Level M: 20 alphanumeric characters
    assert_equal 1, RQRCodeCore::QRCode.new("A" * 20, level: :m).version

    # Level Q: 16 alphanumeric characters
    assert_equal 1, RQRCodeCore::QRCode.new("A" * 16, level: :q).version

    # Level H: 10 alphanumeric characters
    assert_equal 1, RQRCodeCore::QRCode.new("A" * 10, level: :h).version
  end

  def test_long_numeric_string
    # Test very long numeric strings (tests numeric mode efficiency)
    long_numeric = "1" * 500
    qr = RQRCodeCore::QRCode.new(long_numeric, level: :l)

    assert_equal :mode_number, qr.mode, "Long numeric string should use numeric mode"
    assert qr.version < 15, "500 digits should fit in a reasonably small version"
  end

  def test_long_alphanumeric_string
    # Test very long alphanumeric strings
    long_alpha = "A" * 300
    qr = RQRCodeCore::QRCode.new(long_alpha, level: :l)

    assert_equal :mode_alpha_numk, qr.mode, "Long alphanumeric string should use alphanumeric mode"
    assert qr.version < 20, "300 alphanumeric chars should fit in a reasonably small version"
  end

  def test_long_byte_string
    # Test very long byte strings
    long_byte = "a" * 200
    qr = RQRCodeCore::QRCode.new(long_byte, level: :l)

    assert_equal :mode_8bit_byte, qr.mode, "Long byte string should use byte mode"
    assert qr.version < 15, "200 bytes should fit in a reasonably small version"
  end

  def test_very_long_string_automatically_selects_version
    # Don't specify size, let it auto-select
    very_long = "x" * 1000
    qr = RQRCodeCore::QRCode.new(very_long, level: :l)

    assert qr.version > 1, "Very long string should require version > 1"
    assert qr.version <= 40, "Should not exceed maximum version 40"
  end

  def test_minimum_version_parameter
    # When size is not specified, should use minimum version needed
    short_data = "hi"
    qr = RQRCodeCore::QRCode.new(short_data)

    assert_equal 1, qr.version, "Short data should default to version 1"
  end

  def test_forced_larger_version
    # Should be able to force a larger version than needed
    short_data = "hi"
    qr = RQRCodeCore::QRCode.new(short_data, size: 10)

    assert_equal 10, qr.version, "Should respect forced larger version"
    assert_equal 57, qr.module_count, "Version 10 should be 57x57"
  end

  def test_max_size_parameter
    # max_size should limit the version selection
    long_data = "x" * 1000

    # Without limit, should work
    qr_unlimited = RQRCodeCore::QRCode.new(long_data, level: :l)
    assert qr_unlimited.version > 10, "Long data should need large version"

    # With reasonable max_size, should work
    qr_limited = RQRCodeCore::QRCode.new(long_data, level: :l, max_size: 30)
    assert qr_limited.version <= 30, "Should respect max_size limit"
  end

  def test_data_too_long_for_max_size_raises_error
    # Data that's too long for the max_size should raise error
    very_long_data = "x" * 2000

    assert_raises(RQRCodeCore::QRCodeRunTimeError) do
      RQRCodeCore::QRCode.new(very_long_data, level: :h, max_size: 10)
    end
  end

  def test_zero_digit
    qr = RQRCodeCore::QRCode.new("0")
    assert_equal :mode_number, qr.mode, "Single zero should use numeric mode"
    assert qr.modules.size > 0, "Zero should produce valid QR code"
  end

  def test_large_numbers
    # Test very large numeric values
    large_num = "9" * 100
    qr = RQRCodeCore::QRCode.new(large_num)

    assert_equal :mode_number, qr.mode, "Large numeric string should use numeric mode"
    assert qr.modules.size > 0, "Should produce valid QR code"
  end

  def test_numeric_with_leading_zeros
    qr = RQRCodeCore::QRCode.new("00012345")
    assert_equal :mode_number, qr.mode, "Numbers with leading zeros should use numeric mode"
  end

  def test_all_zeros
    qr = RQRCodeCore::QRCode.new("00000000")
    assert_equal :mode_number, qr.mode, "All zeros should use numeric mode"
    assert qr.modules.size > 0, "Should produce valid QR code"
  end

  def test_repeated_characters
    # Test strings with repeated characters (good for compression testing)
    repeated = "A" * 100
    qr = RQRCodeCore::QRCode.new(repeated)

    assert qr.modules.size > 0, "Repeated characters should produce valid QR code"
    assert qr.version <= 40, "Should not exceed maximum version"
  end

  def test_alternating_characters
    # Test strings that don't compress well
    alternating = ("AB" * 50)
    qr = RQRCodeCore::QRCode.new(alternating)

    assert qr.modules.size > 0, "Alternating characters should produce valid QR code"
  end

  def test_checked_with_boundary_coordinates
    qr = RQRCodeCore::QRCode.new("test", size: 5)
    max = qr.module_count - 1

    # Should work with valid boundary coordinates
    qr.checked?(0, 0)      # Top-left corner should be valid
    qr.checked?(0, max)    # Top-right corner should be valid
    qr.checked?(max, 0)    # Bottom-left corner should be valid
    qr.checked?(max, max)  # Bottom-right corner should be valid

    # Should raise error with out-of-bounds coordinates
    assert_raises(RQRCodeCore::QRCodeRunTimeError) { qr.checked?(-1, 0) }
    assert_raises(RQRCodeCore::QRCodeRunTimeError) { qr.checked?(0, -1) }
    assert_raises(RQRCodeCore::QRCodeRunTimeError) { qr.checked?(qr.module_count, 0) }
    assert_raises(RQRCodeCore::QRCodeRunTimeError) { qr.checked?(0, qr.module_count) }
  end

  def test_url_maximum_length
    # URLs are common QR code content, test reasonable max lengths
    base_url = "https://example.com/path"

    # Short URL should work
    qr_short = RQRCodeCore::QRCode.new(base_url)
    assert qr_short.modules.size > 0

    # Long URL with query params should work
    long_url = base_url + "?" + ("param=value&" * 50)
    qr_long = RQRCodeCore::QRCode.new(long_url, level: :l)
    assert qr_long.modules.size > 0
    assert qr_long.version <= 40
  end

  def test_mode_specification_overrides_auto_detection
    # Numeric string forced to alphanumeric mode
    qr = RQRCodeCore::QRCode.new("12345", mode: :alphanumeric)
    assert_equal :mode_alpha_numk, qr.mode, "Should respect forced mode"

    # Alphanumeric string forced to byte mode
    qr2 = RQRCodeCore::QRCode.new("HELLO", mode: :byte_8bit)
    assert_equal :mode_8bit_byte, qr2.mode, "Should respect forced byte mode"
  end

  def test_invalid_mode_for_data_raises_error
    # Lowercase cannot be encoded in alphanumeric mode
    assert_raises(RQRCodeCore::QRCodeArgumentError) do
      RQRCodeCore::QRCode.new("hello", mode: :alphanumeric)
    end
  end

  def test_numeric_mode_with_non_digits_raises_error
    # Non-digits cannot be encoded in numeric mode
    assert_raises(RQRCodeCore::QRCodeArgumentError) do
      RQRCodeCore::QRCode.new("123abc", mode: :number)
    end
  end
end
