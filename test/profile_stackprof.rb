# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rqrcode_core"
require "stackprof"
require "fileutils"

puts "=" * 80
puts "RQRCode Core - StackProf Performance Profiling"
puts "=" * 80
puts "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})"
puts "ARCH_BITS: #{RQRCodeCore::QRUtil::ARCH_BITS}"
puts "=" * 80
puts

# Create output directory for profiles
output_dir = File.expand_path("../tmp/stackprof", __dir__)
FileUtils.mkdir_p(output_dir)

# Helper to run profile and save results
def profile_scenario(name, output_dir, mode: :cpu, &)
  puts "\nProfiling: #{name}..."

  # Run the profiling
  profile = StackProf.run(mode: mode, raw: true, &)

  # Save raw profile data
  filename = name.downcase.gsub(/[^a-z0-9]+/, "_")
  raw_file = File.join(output_dir, "#{filename}_#{mode}.dump")
  File.write(raw_file, Marshal.dump(profile))
  puts "  Saved raw profile: #{raw_file}"

  # Generate text report
  report_file = File.join(output_dir, "#{filename}_#{mode}_report.txt")
  File.open(report_file, "w") do |f|
    f.puts "=" * 80
    f.puts "StackProf Report: #{name} (#{mode} mode)"
    f.puts "=" * 80
    f.puts
    f.puts StackProf::Report.new(profile).print_text
  end
  puts "  Saved text report: #{report_file}"

  # Generate callgrind format (optional, useful for visualization tools)
  callgrind_file = File.join(output_dir, "#{filename}_#{mode}.callgrind")
  File.open(callgrind_file, "w") do |f|
    f.puts StackProf::Report.new(profile).print_callgrind
  end
  puts "  Saved callgrind format: #{callgrind_file}"

  puts "  Done!"
  profile
end

# Configuration
PROFILE_ITERATIONS = 100

puts "\nRunning profiling scenarios (#{PROFILE_ITERATIONS} iterations each)...\n"

# Profile 1: Small QR Code (v1) - Baseline
profile_scenario("Small QR Code (v1)", output_dir) do
  PROFILE_ITERATIONS.times do
    RQRCodeCore::QRCode.new("hello")
  end
end

# Profile 2: Medium QR Code (v5) - URL
profile_scenario("Medium QR Code (v5)", output_dir) do
  PROFILE_ITERATIONS.times do
    RQRCodeCore::QRCode.new("https://github.com/whomwah/rqrcode_core")
  end
end

# Profile 3: Large QR Code (v10)
profile_scenario("Large QR Code (v10)", output_dir) do
  PROFILE_ITERATIONS.times do
    RQRCodeCore::QRCode.new("a" * 150)
  end
end

# Profile 4: Very Large QR Code (v20) - Where performance degrades significantly
profile_scenario("Very Large QR Code (v20)", output_dir) do
  20.times do # Fewer iterations for large codes
    RQRCodeCore::QRCode.new("a" * 500)
  end
end

# Profile 5: Version 40 - Maximum size (fewer iterations)
profile_scenario("Maximum QR Code (v40)", output_dir) do
  5.times do # Very few iterations for maximum size
    RQRCodeCore::QRCode.new("a" * 1500)
  end
end

# Profile 6: Focus on mask pattern calculation (known hot spot)
profile_scenario("Mask Pattern Calculation", output_dir) do
  50.times do
    RQRCodeCore::QRCode.new("a" * 300) # v15 - large enough to be expensive
  end
end

# Profile 7: Multi-segment encoding
profile_scenario("Multi-segment Encoding", output_dir) do
  PROFILE_ITERATIONS.times do
    RQRCodeCore::QRCode.new([
      {data: "hello world", mode: :byte_8bit},
      {data: "HELLO123", mode: :alphanumeric},
      {data: "123456789", mode: :number}
    ])
  end
end

puts "\n" + "=" * 80
puts "Profiling complete!"
puts "=" * 80
puts
puts "Profile data saved to: #{output_dir}"
puts
puts "To view flamegraphs (requires stackprof-webnav gem):"
puts "  gem install stackprof-webnav"
puts "  stackprof-webnav #{output_dir}/*.dump"
puts
puts "To view specific profile interactively:"
puts "  stackprof #{output_dir}/small_qr_code_v1_cpu.dump"
puts
puts "To generate flamegraph SVG (requires flamegraph.pl):"
puts "  stackprof --flamegraph #{output_dir}/small_qr_code_v1_cpu.dump > flamegraph.svg"
puts
puts "=" * 80
