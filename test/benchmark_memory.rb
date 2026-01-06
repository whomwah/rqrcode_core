# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rqrcode_core"
require "memory_profiler"

puts "=" * 80
puts "RQRCode Core - Memory Profiling Benchmark"
puts "=" * 80
puts "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})"
puts "ARCH_BITS: #{RQRCodeCore::QRUtil::ARCH_BITS}"
puts "=" * 80
puts

def format_mb(bytes)
  format("%.2f MB", bytes / 1024.0 / 1024.0)
end

def profile_scenario(name, &)
  puts "\n--- #{name} ---"
  report = MemoryProfiler.report(&)

  puts "Total allocated: #{format_mb(report.total_allocated_memsize)}"
  puts "Total retained:  #{format_mb(report.total_retained_memsize)}"
  puts "Objects allocated: #{report.total_allocated}"
  puts "Objects retained:  #{report.total_retained}"

  puts "\nTop 3 allocations by class:"
  report.allocated_memory_by_class.first(3).each do |stat|
    puts "  #{stat[:data]}: #{format_mb(stat[:count])}"
  end

  report
end

# Single QR code - different sizes
profile_scenario("Single small QR (v1)") do
  RQRCodeCore::QRCode.new("hello")
end

profile_scenario("Single medium QR (v5)") do
  RQRCodeCore::QRCode.new("https://github.com/whomwah/rqrcode_core")
end

profile_scenario("Single large QR (v24)") do
  RQRCodeCore::QRCode.new("a" * 500)
end

# Batch generation
profile_scenario("Batch: 100 small QR codes") do
  100.times { RQRCodeCore::QRCode.new("hello") }
end

profile_scenario("Batch: 10 large QR codes") do
  10.times { RQRCodeCore::QRCode.new("a" * 500) }
end

# Creation vs rendering
profile_scenario("Create only") do
  100.times { RQRCodeCore::QRCode.new("hello") }
end

profile_scenario("Create + render") do
  100.times { RQRCodeCore::QRCode.new("hello").to_s }
end

# Different encoding modes
profile_scenario("Numeric mode") do
  100.times { RQRCodeCore::QRCode.new("1234567890", mode: :number) }
end

profile_scenario("Alphanumeric mode") do
  100.times { RQRCodeCore::QRCode.new("HELLO WORLD", mode: :alphanumeric) }
end

profile_scenario("Byte mode") do
  100.times { RQRCodeCore::QRCode.new("hello world", mode: :byte_8bit) }
end

# Multi-segment
profile_scenario("Multi-segment encoding") do
  100.times do
    RQRCodeCore::QRCode.new([
      {data: "hello", mode: :byte_8bit},
      {data: "WORLD", mode: :alphanumeric},
      {data: "123", mode: :number}
    ])
  end
end

puts "\n" + "=" * 80
puts "Memory profiling complete!"
puts "\nNote: To test ARCH_BITS=32 impact, run:"
puts "  RQRCODE_CORE_ARCH_BITS=32 ruby #{__FILE__}"
puts "=" * 80
