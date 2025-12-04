# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rqrcode_core"
require "benchmark"

puts "=" * 80
puts "RQRCode Core - Simple Benchmark"
puts "=" * 80
puts "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})"
puts "ARCH_BITS: #{RQRCodeCore::QRUtil::ARCH_BITS}"
puts "=" * 80
puts

# Quick benchmark with few iterations for development
# For detailed analysis, use benchmark_performance.rb
ITERATIONS = 10

Benchmark.bm(35) do |x|
  x.report("Small (v1):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("hello")
    end
  end

  x.report("Small (v1) with rendering:") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("hello").to_s
    end
  end

  x.report("URL (v5):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("https://github.com/whomwah/rqrcode_core")
    end
  end

  x.report("URL (v5) with rendering:") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("https://github.com/whomwah/rqrcode_core").to_s
    end
  end

  x.report("Large text (v24):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("a" * 500)
    end
  end

  x.report("Large text (v24) with rendering:") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("a" * 500).to_s
    end
  end

  x.report("Numeric mode (v1):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("1234567890", mode: :number)
    end
  end

  x.report("Alphanumeric mode (v1):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("HELLO WORLD", mode: :alphanumeric)
    end
  end

  x.report("Byte mode (v1):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("hello world", mode: :byte_8bit)
    end
  end

  x.report("Error correction :l (v1):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("hello", level: :l)
    end
  end

  x.report("Error correction :m (v1):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("hello", level: :m)
    end
  end

  x.report("Error correction :q (v1):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("hello", level: :q)
    end
  end

  x.report("Error correction :h (v1):") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new("hello", level: :h)
    end
  end

  x.report("Multi-segment encoding:") do
    ITERATIONS.times do
      RQRCodeCore::QRCode.new([
        {data: "hello", mode: :byte_8bit},
        {data: "WORLD123", mode: :alphanumeric},
        {data: "9876543210", mode: :number}
      ])
    end
  end
end

puts
puts "=" * 80
puts "Benchmark complete! (#{ITERATIONS} iterations per test)"
puts "=" * 80
