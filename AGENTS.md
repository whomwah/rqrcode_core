# Agent Guidelines for rqrcode_core

## Commands
- Run all tests: `rake test` or `rake`
- Run single test: `ruby -Ilib:test test/rqrcode_core/rqrcode_test.rb -n test_H_`
- Lint check: `rake standard`
- Lint fix: `rake standard:fix`
- Console: `./bin/console`
- Benchmarks:
  - Quick benchmark: `rake benchmark` or `rake benchmark:simple`
  - Detailed performance: `rake benchmark:performance`
  - Memory profiling: `rake benchmark:memory`
  - All benchmarks: `rake benchmark:all`

## Code Style
- Follow [Standard Ruby](https://github.com/testdouble/standard) style guide (enforced via `rake standard`)
- Use `frozen_string_literal: true` at top of all Ruby files
- Ruby version: >= 3.0.0
- Test framework: Minitest (`require "minitest/autorun"`)
- No external runtime dependencies (Ruby stdlib only)

## Structure & Conventions
- Module namespace: `RQRCodeCore`
- Custom errors: `QRCodeArgumentError` (ArgumentError), `QRCodeRunTimeError` (RuntimeError)
- Constants: Use SCREAMING_SNAKE_CASE with `.freeze` for immutability (e.g., `QRMODE.freeze`)
- Use symbols for modes (`:number`, `:alphanumeric`, `:byte_8bit`) and levels (`:l`, `:m`, `:q`, `:h`)
- Prefer array/hash operations over loops where idiomatic
- Private methods use `private` keyword, protected use `protected`
