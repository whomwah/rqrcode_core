begin
  require "rake/testtask"
  require "standard/rake"

  Rake::TestTask.new(:test) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/**/*_test.rb"]
  end

  task default: [:test, "standard:fix"]

  desc "Run a simple benchmark (x10)"
  task :benchmark do
    ruby "test/benchmark_simple.rb"
  end

  namespace :benchmark do
    desc "Run simple comparison benchmark"
    task :simple do
      ruby "test/benchmark_simple.rb"
    end

    desc "Run detailed performance benchmark (benchmark-ips)"
    task :performance do
      ruby "test/benchmark_performance.rb"
    end

    desc "Run memory profiling benchmark"
    task :memory do
      ruby "test/benchmark_memory.rb"
    end

    desc "Run all benchmarks"
    task all: [:simple, :performance, :memory]
  end
rescue LoadError
  # no standard/rspec available
end
