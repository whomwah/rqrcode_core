# Benchmark Results and Analysis

This directory contains comprehensive benchmark data for the `RQRCODE_CORE_ARCH_BITS` performance analysis.

## Files

### Analysis Document
- **`ARCH_BITS_ANALYSIS.md`** - Complete analysis of 32-bit vs 64-bit performance, including recommendations

### Memory Benchmarks
- **`benchmark_memory_64bit.txt`** - Memory profiling results using default 64-bit mode
- **`benchmark_memory_32bit.txt`** - Memory profiling results using 32-bit mode (`RQRCODE_CORE_ARCH_BITS=32`)

### Performance Benchmarks
- **`benchmark_performance_64bit.txt`** - Speed benchmarks using default 64-bit mode
- **`benchmark_performance_32bit.txt`** - Speed benchmarks using 32-bit mode (`RQRCODE_CORE_ARCH_BITS=32`)

## Key Findings

Setting `RQRCODE_CORE_ARCH_BITS=32` on 64-bit systems provides:

- **70-76% memory reduction** across all scenarios
- **2-4% speed improvement** (not just "no penalty"—it's actually faster)
- **85-87% fewer object allocations**
- **Zero test failures** (all 108 assertions pass)

## Running Benchmarks

### Memory Profiling

```bash
# 64-bit (default)
ruby test/benchmark_memory.rb

# 32-bit mode
RQRCODE_CORE_ARCH_BITS=32 ruby test/benchmark_memory.rb
```

### Performance Benchmarking

```bash
# 64-bit (default)
ruby test/benchmark_performance.rb

# 32-bit mode
RQRCODE_CORE_ARCH_BITS=32 ruby test/benchmark_performance.rb
```

## Test Environment

- **Ruby Version**: 3.3.4
- **Platform**: arm64-darwin24 (Apple Silicon)
- **Date**: December 2025

## Recommendation

**Use `RQRCODE_CORE_ARCH_BITS=32` in production**, especially for:
- Batch QR code generation
- Memory-constrained environments
- High-concurrency web applications
- Large QR codes (version 10+)

The evidence is conclusive: massive memory savings with a small speed boost and zero downsides.