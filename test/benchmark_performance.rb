# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rqrcode_core"
require "benchmark/ips"

puts "=" * 80
puts "RQRCode Core - Detailed Performance Benchmark (benchmark-ips)"
puts "=" * 80
puts "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})"
puts "ARCH_BITS: #{RQRCodeCore::QRUtil::ARCH_BITS}"
puts "=" * 80
puts

# Fast configuration for development - increase for production baselines
Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  puts "\n--- By Data Size ---"
  x.report("Small (v1)") { RQRCodeCore::QRCode.new("hello") }
  x.report("Medium URL (v5)") { RQRCodeCore::QRCode.new("https://github.com/whomwah/rqrcode_core") }
  x.report("Large (v24)") { RQRCodeCore::QRCode.new("a" * 500) }

  x.compare!
end

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  puts "\n--- By Encoding Mode ---"
  x.report("Numeric") { RQRCodeCore::QRCode.new("1234567890", mode: :number) }
  x.report("Alphanumeric") { RQRCodeCore::QRCode.new("HELLO WORLD", mode: :alphanumeric) }
  x.report("Byte") { RQRCodeCore::QRCode.new("hello world", mode: :byte_8bit) }

  x.compare!
end

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  puts "\n--- By QR Version (same data) ---"
  x.report("Version 1") { RQRCodeCore::QRCode.new("hi", size: 1) }
  x.report("Version 5") { RQRCodeCore::QRCode.new("hi", size: 5) }
  x.report("Version 10") { RQRCodeCore::QRCode.new("hi", size: 10) }
  x.report("Version 20") { RQRCodeCore::QRCode.new("hi", size: 20) }
  x.report("Version 40") { RQRCodeCore::QRCode.new("hi", size: 40) }

  x.compare!
end

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  puts "\n--- By Error Correction Level ---"
  x.report("Level :l (7%)") { RQRCodeCore::QRCode.new("hello", level: :l) }
  x.report("Level :m (15%)") { RQRCodeCore::QRCode.new("hello", level: :m) }
  x.report("Level :q (25%)") { RQRCodeCore::QRCode.new("hello", level: :q) }
  x.report("Level :h (30%)") { RQRCodeCore::QRCode.new("hello", level: :h) }

  x.compare!
end

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  puts "\n--- Creation vs Rendering ---"
  x.report("Create only") { RQRCodeCore::QRCode.new("hello") }
  x.report("Create + render") { RQRCodeCore::QRCode.new("hello").to_s }
  x.report("Render only") do
    qr = RQRCodeCore::QRCode.new("hello")
    qr.to_s
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  puts "\n--- Multi-segment Encoding ---"
  x.report("Single segment") { RQRCodeCore::QRCode.new("hello world 123") }
  x.report("Multi-segment") do
    RQRCodeCore::QRCode.new([
      {data: "hello", mode: :byte_8bit},
      {data: "WORLD", mode: :alphanumeric},
      {data: "123", mode: :number}
    ])
  end

  x.compare!
end

puts "\n" + "=" * 80
puts "Performance benchmark complete!"
puts "=" * 80
