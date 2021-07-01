$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rqrcode_core"
require "benchmark"

Benchmark.bm do |benchmark|
  benchmark.report("RQRCode") do
    1000.times do
      RQRCodeCore::QRCode.new("https://kyan.com").to_s
    end
  end
end
