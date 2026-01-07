# RQRCode Core - Performance Benchmarks

This document describes the benchmarking infrastructure for rqrcode_core and provides baseline performance metrics.

## Running Benchmarks

### Quick Start

```bash
# Quick comparison (10 iterations, ~5 seconds)
rake benchmark
# or
rake benchmark:simple

# Detailed performance analysis with benchmark-ips (~30 seconds)
rake benchmark:performance

# Memory profiling with detailed allocation tracking (~30 seconds)
rake benchmark:memory

# Run all benchmarks
rake benchmark:all
```

### Individual Benchmark Files

You can also run benchmark files directly:

```bash
ruby test/benchmark_simple.rb
ruby test/benchmark_performance.rb
ruby test/benchmark_memory.rb
```

## System Information

Baselines collected on:
- **Date**: December 4, 2025
- **Ruby Version**: 3.3.4
- **Platform**: arm64-darwin24 (Apple Silicon)
- **ARCH_BITS**: 64

## Benchmark Types

### 1. Simple Benchmark (`benchmark_simple.rb`)

Fast comparison across common scenarios using Ruby's standard `Benchmark` module. Good for quick before/after comparisons during development.

**Iterations**: 10 per test (configurable via `ITERATIONS` constant)
**Runtime**: ~5 seconds

### 2. Performance Benchmark (`benchmark_performance.rb`)

Detailed performance analysis using `benchmark-ips` gem. Provides iterations-per-second metrics with statistical analysis and comparisons.

**Configuration**: 2 seconds measurement, 1 second warmup (configurable)
**Runtime**: ~30-45 seconds

**Scenarios tested**:
- Data sizes (small/medium/large)
- Encoding modes (numeric/alphanumeric/byte)
- QR versions (1, 5, 10, 20, 40)
- Error correction levels (:l, :m, :q, :h)
- Creation vs rendering
- Multi-segment encoding

### 3. Memory Benchmark (`benchmark_memory.rb`)

Memory allocation profiling using `memory_profiler` gem. Tracks total allocated/retained memory and object allocations by class.

**Runtime**: ~30 seconds

**Scenarios tested**:
- Single QR codes (various sizes)
- Batch generation (100 small, 10 large)
- Creation vs rendering
- Different encoding modes
- Multi-segment encoding

## Baseline Performance Metrics

### Performance (iterations per second)

| Scenario | ips | ms/iteration | vs Baseline |
|----------|-----|--------------|-------------|
| Small QR (v1) | 144.1 | 6.94 | 1.00x |
| Medium URL (v5) | 44.6 | 22.41 | 3.23x slower |
| Large (v24) | 4.6 | 217.37 | 31.33x slower |
| Numeric mode | 147.1 | 6.80 | fastest |
| Alphanumeric mode | 100.9 | 9.91 | 1.46x slower |
| Byte mode | 100.9 | 9.91 | 1.46x slower |
| Version 1 | 147.3 | 6.79 | 1.00x |
| Version 5 | 44.8 | 22.33 | 3.29x slower |
| Version 10 | 18.8 | 53.08 | 7.82x slower |
| Version 20 | 6.4 | 155.21 | 22.86x slower |
| Version 40 | 1.9 | 521.09 | 76.74x slower |

**Key Findings**:
- **Version impact**: Performance degrades quadratically with version (module_count = version*4 + 17)
- **Encoding modes**: Numeric mode is ~46% faster than alphanumeric/byte modes
- **Error correction**: Minimal impact (~2% variance) across levels :l, :m, :q, :h
- **Rendering**: Adds ~3% overhead to creation time

### Memory Usage

| Scenario | Allocated | Retained | Objects | Notes |
|----------|-----------|----------|---------|-------|
| Single v1 | 0.38 MB | 0.00 MB | 8,740 | Baseline |
| Single v5 | 0.97 MB | 0.00 MB | 21,264 | 2.5x v1 |
| Single v24 | 8.53 MB | 0.00 MB | 179,659 | 22x v1 |
| 100x v1 | 37.91 MB | 0.00 MB | 872,700 | ~380KB each |
| 10x v24 | 85.32 MB | 0.00 MB | 1,796,590 | ~8.5MB each |
| Create only | 37.91 MB | 0.00 MB | 872,700 | 100 iterations |
| Create + render | 40.27 MB | 0.00 MB | 919,300 | +6% for rendering |

**Key Findings**:
- **No memory retention**: All memory is garbage collectable (0 retained)
- **Top allocations**: Integer (70-76%), Array (15-22%), Range (8-10%)
- **Version scaling**: Memory usage grows quadratically with version
- **Rendering overhead**: Adds ~6% to memory allocation
- **Encoding modes**: Minimal difference (~3% variance) across modes

### ARCH_BITS Impact

To test the memory impact of `ARCH_BITS` setting:

```bash
# Default 64-bit (current baseline)
ruby test/benchmark_memory.rb

# Force 32-bit mode (reduced memory)
RQRCODE_CORE_ARCH_BITS=32 ruby test/benchmark_memory.rb
```

**Expected**: 32-bit mode should reduce memory usage during right-shift operations, particularly noticeable with large QR codes and batch generation.

## Understanding the Results

### benchmark-ips Output

```
Calculating -------------------------------------
          Small (v1)    144.135 (± 0.7%) i/s    (6.94 ms/i)
```

- **144.135 i/s**: 144 iterations per second
- **(± 0.7%)**: Statistical error margin (lower is more consistent)
- **(6.94 ms/i)**: Milliseconds per iteration
- **Comparison section**: Shows relative performance differences

### memory_profiler Output

```
Total allocated: 0.38 MB    # Memory allocated during execution
Total retained:  0.00 MB    # Memory still held after GC
Objects allocated: 8740     # Number of objects created
Objects retained:  0        # Number of objects not GC'd
```

- **Allocated**: All memory used (includes garbage)
- **Retained**: Memory still referenced (memory leaks if high)
- **By class**: Shows which Ruby types are most allocated

## Performance Characteristics

### Version Size Impact

QR Code module count formula: `module_count = version * 4 + 17`

| Version | Modules | Total Cells | Performance Impact |
|---------|---------|-------------|-------------------|
| 1 | 21x21 | 441 | 1.00x (baseline) |
| 5 | 37x37 | 1,369 | ~3.1x slower |
| 10 | 57x57 | 3,249 | ~7.4x slower |
| 20 | 97x97 | 9,409 | ~21x slower |
| 40 | 177x177 | 31,329 | ~71x slower |

Performance degradation is roughly O(n²) where n is version number.

### Encoding Mode Efficiency

1. **Numeric** (fastest): 3.33 bits per digit
2. **Alphanumeric**: 5.5 bits per character
3. **Byte** (slowest): 8 bits per character

For mixed content, multi-segment encoding can be more efficient than byte mode.

### Error Correction Impact

Error correction levels have minimal performance impact (<3% variance):
- `:l` - 7% restoration
- `:m` - 15% restoration
- `:q` - 25% restoration
- `:h` - 30% restoration (default)

The performance cost is in capacity (less data fits), not speed.

## Known Considerations

### Memory on 64-bit Systems

From `lib/rqrcode_core/qrcode/qr_util.rb`:

> 64 consumes a LOT more memory. In tests it's shown changing it to 32
> on 64 bit systems greatly reduces the memory footprint.

This occurs during right-shift zero-fill operations. Use `RQRCODE_CORE_ARCH_BITS=32` to reduce memory at potential compatibility risk.

### Large QR Codes

Version 24+ QR codes are significantly slower (~200ms+ per code). For batch processing:
- Consider caching generated codes
- Use background jobs for generation
- Consider lower error correction levels if acceptable

## Future Optimization Ideas

Potential areas for performance improvement:

1. **Memory Optimization**
   - Investigate ARCH_BITS impact more thoroughly
   - Reduce temporary array allocations
   - Optimize string concatenation in rendering
   - Use more efficient data structures for modules

2. **Speed Optimization**
   - Profile hot paths with stackprof
   - Cache frequently computed values
   - Optimize inner loops in encoding
   - Consider memoization for version calculations

3. **Algorithm Improvements**
   - Review polynomial math operations
   - Optimize mask pattern calculation
   - Benchmark alternative implementations

4. **Benchmarking Infrastructure**
   - Add CI performance regression tests
   - Track performance trends over time
   - Add comparison with other QR libraries
   - Create performance dashboard

## Contributing

When making performance-related changes:

1. Run benchmarks before changes: `rake benchmark:all > before.txt`
2. Make your changes
3. Run benchmarks after: `rake benchmark:all > after.txt`
4. Compare results and document improvements
5. Update this file with new baseline if significant

## References

- [benchmark-ips gem](https://github.com/evanphx/benchmark-ips)
- [memory_profiler gem](https://github.com/SamSaffron/memory_profiler)
- [Ruby Benchmark module](https://ruby-doc.org/stdlib/libdoc/benchmark/rdoc/Benchmark.html)
- [QR Code specification](https://www.qrcode.com/en/about/standards.html)

---

**Last Updated**: December 4, 2025
**Baseline Version**: rqrcode_core 2.0.1
