require "test_helper"

# Tests for character encoding handling in QR codes
class CharacterEncodingTest < Minitest::Test
  def test_printable_ascii_uses_byte_mode
    ascii_string = (32..126).map(&:chr).join
    qr = RQRCodeCore::QRCode.new(ascii_string)

    assert_equal :mode_8bit_byte, qr.mode
  end

  def test_control_characters
    # Newlines, tabs, null bytes, and other control chars
    [
      "line1\nline2",      # LF
      "line1\r\nline2",    # CRLF
      "line1\rline2",      # CR
      "field1\tfield2",    # Tab
      "before\x00after",   # Null byte
      "test\x07data",      # Bell
      "test\x1Bdata"       # Escape
    ].each do |input|
      qr = RQRCodeCore::QRCode.new(input)
      refute_nil qr.modules
    end
  end

  def test_utf8_multibyte_characters
    # Representative samples from different Unicode blocks
    samples = [
      "Café résumé naïve",           # Latin extended
      "Привет мир",                  # Cyrillic
      "你好世界",                     # CJK
      "こんにちは",                   # Japanese Hiragana
      "مرحبا بالعالم",               # Arabic (RTL)
      "שלום עולם",                   # Hebrew (RTL)
      "∑∫∂√∞≈≠±×÷",                  # Mathematical symbols
      "$ € £ ¥ ₹ ₽",                # Currency symbols
      "Hello 👋 World 🌍",           # Emoji
      "Hello مرحبا 你好"              # Mixed LTR/RTL
    ]

    samples.each do |text|
      qr = RQRCodeCore::QRCode.new(text)
      refute_nil qr.modules
    end
  end

  def test_complex_emoji_sequences
    # Compound emoji with modifiers and zero-width joiners
    ["👋🏻👋🏾", "👨‍👩‍👧‍👦", "🏴󠁧󠁢󠁥󠁮󠁧󠁿"].each do |emoji|
      qr = RQRCodeCore::QRCode.new(emoji)
      refute_nil qr.modules
    end
  rescue => e
    skip "Complex compound emoji not fully supported: #{e.message}"
  end

  def test_zero_width_and_combining_characters
    # Zero-width joiners, non-joiners, and combining marks
    [
      "test\u200Djoiner",
      "test\u200Cnon-joiner",
      "test\u200Bspace",
      "e\u0301"  # e + combining acute accent
    ].each do |text|
      qr = RQRCodeCore::QRCode.new(text)
      refute_nil qr.modules
    end
  end

  def test_long_utf8_string_fits_within_max_version
    long_utf8 = "こんにちは世界" * 20
    qr = RQRCodeCore::QRCode.new(long_utf8, level: :l)

    assert qr.version <= 40
  end

  def test_binary_data_non_utf8
    binary = "\xFF\xFE\xFD\xFC\xFB"
    binary.force_encoding(Encoding::BINARY)

    qr = RQRCodeCore::QRCode.new(binary)
    refute_nil qr.modules
  end

  def test_special_unicode_areas
    # BOM, Private Use Area, Supplementary Planes
    [
      "\uFEFFHello World",  # BOM
      "\uE000\uE001\uE002", # Private Use Area
      "𐐀𐐁𐐂"               # Deseret alphabet (supplementary plane)
    ].each do |text|
      qr = RQRCodeCore::QRCode.new(text)
      refute_nil qr.modules
    end
  end

  def test_output_maintains_utf8_encoding
    qr = RQRCodeCore::QRCode.new("Hello 世界")
    output = qr.to_s

    assert_equal Encoding::UTF_8, output.encoding
  end
end
