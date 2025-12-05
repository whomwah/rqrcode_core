# RQRCode Core - Performance Optimization Plan

This document outlines the step-by-step plan for implementing the performance improvements identified in BENCHMARKS.md.

**Created**: December 4, 2025  
**Status**: In Progress

---

## Overview

This plan addresses the "Future Optimization Ideas" section from BENCHMARKS.md, organized by category and priority. Each optimization will be done incrementally with benchmarking before/after to measure impact.

---

## Phase 1: Memory Optimizations (High Priority)

### Task #1: ARCH_BITS Investigation ✅
**Priority**: High  
**Status**: COMPLETE  
**File**: `lib/rqrcode_core/qrcode/qr_util.rb:69`

**Goals**:
- ✅ Run memory benchmarks with default 64-bit setting (baseline)
- ✅ Run memory benchmarks with `RQRCODE_CORE_ARCH_BITS=32`
- ✅ Run performance benchmarks for speed comparison
- ✅ Document memory differences and performance impact
- ✅ Determine if 32-bit can be safely used as default
- ✅ Make recommendation based on data

**Results**:

| Metric | 64-bit | 32-bit | Improvement |
|--------|--------|--------|-------------|
| Single v1 | 0.38 MB | 0.10 MB | **74% reduction** |
| Single v24 | 8.53 MB | 2.92 MB | **66% reduction** |
| 100x v1 | 37.91 MB | 9.10 MB | **76% reduction** |
| Speed (small) | 152.7 i/s | 157.1 i/s | **+2.9% faster** |
| Speed (large) | 4.77 i/s | 4.87 i/s | **+2.1% faster** |
| Objects (100x v1) | 872,700 | 117,500 | **87% reduction** |

**Key Findings**:
- Integer allocations nearly eliminated (from 70-76% to ~0%)
- All 108 test assertions pass
- Actually faster due to better cache utilization and reduced GC pressure
- No correctness issues

**Recommendation**: ✅ **STRONGLY RECOMMEND** users set `RQRCODE_CORE_ARCH_BITS=32` in production for 70-76% memory savings with 2-4% speed improvement. Not changing default to maintain backwards compatibility, but documenting heavily in README and code comments.

**Documentation Updated**:
- ✅ Updated `lib/rqrcode_core/qrcode/qr_util.rb` comment with benchmark data
- ✅ Replaced README "Experimental" section with prominent "Performance Optimization" section
- ✅ Updated `docs/BENCHMARKS.md` with proven results
- ✅ Moved all benchmark files to `test/benchmarks/` directory
- ✅ Created `test/benchmarks/ARCH_BITS_ANALYSIS.md` with complete analysis

See `test/benchmarks/ARCH_BITS_ANALYSIS.md` for detailed analysis.

---

### Task #2: Optimize String Concatenation in Rendering
**Priority**: Medium  
**Status**: Pending  
**File**: `lib/rqrcode_core/qrcode/qr_code.rb:178-199`

**Goals**:
- Replace string concatenation with more efficient methods
- Use array join or string buffer approach
- Benchmark rendering time before/after

**Current Code Pattern**:
```ruby
cols = light * quiet_zone_size
row.each do |col|
  cols += (col ? dark : light)  # String concatenation in loop
end
```

**Optimization Strategy**:
- Build array of strings, then join once
- Reduces temporary string allocations

---

### Task #3: More Efficient Data Structures for Modules
**Priority**: Medium  
**Status**: Pending  
**Files**: Various

**Goals**:
- Evaluate current Array of Arrays approach for modules
- Consider alternatives: Flat array with index calculations, BitArray
- Analyze trade-offs: Memory vs access speed
- Benchmark access patterns

**Current**: `@modules = Array.new(@module_count)`  
**Considerations**: Module count can be 177x177 = 31,329 cells for v40

---

## Phase 2: Speed Optimizations

### Task #4: Profile Hot Paths with stackprof
**Priority**: High  
**Status**: Pending

**Goals**:
- Add stackprof gem to development dependencies
- Create profiling script for various QR code sizes
- Focus on large QR codes (v20+) where performance degrades
- Identify actual bottlenecks with data

**Approach**:
1. Add stackprof to Gemfile (development group)
2. Create `test/profile_stackprof.rb` script
3. Profile small (v1), medium (v10), large (v20+) codes
4. Generate flamegraphs or reports
5. Use data to prioritize optimization efforts

---

### Task #5: Cache Frequently Computed Values
**Priority**: Medium  
**Status**: Pending  
**File**: `lib/rqrcode_core/qrcode/qr_util.rb:119-127`

**Goals**:
- Identify values computed multiple times
- Implement memoization where appropriate
- Add class-level caching for version-specific calculations

**Candidates**:
- `get_error_correct_polynomial(error_correct_length)` - called per RS block
- Pattern positions (already cached in table)
- BCH calculations for common versions

---

### Task #6: Optimize Inner Loops in Encoding
**Priority**: Medium  
**Status**: Pending  
**Files**:
- `lib/rqrcode_core/qrcode/qr_util.rb:163-192` (demerit_points_1_same_color)
- `lib/rqrcode_core/qrcode/qr_code.rb:367-404` (map_data)

**Goals**:
- Focus on nested loops that iterate over module_count
- Reduce redundant calculations inside loops
- Consider pre-computing values or caching

**Hot Spots**:
- `demerit_points_1_same_color`: O(n²) with nested checks
- `map_data`: Critical path for encoding data into modules

---

### Task #7: Memoization for Version Calculations
**Priority**: Low  
**Status**: Pending

**Goals**:
- Add memoization for version-specific calculations
- Cache results for common version/level combinations
- Measure impact on batch generation scenarios

---

## Phase 3: Algorithm Improvements

### Task #8: Review Polynomial Math Operations
**Priority**: Medium  
**Status**: Pending  
**File**: `lib/rqrcode_core/qrcode/qr_polynomial.rb`

**Goals**:
- Analyze multiply and mod methods for optimization
- Review recursive mod at line 58
- Consider iterative approach instead of recursive
- Benchmark alternative implementations

**Current Concerns**:
- `multiply`: Creates temporary arrays in nested loops
- `mod`: Recursive calls may cause stack overhead

---

### Task #9: Optimize Mask Pattern Calculation
**Priority**: Medium  
**Status**: Pending  
**File**: `lib/rqrcode_core/qrcode/qr_code.rb:286-300`

**Goals**:
- Review get_best_mask_pattern (tries all 8 patterns)
- Algorithm requires testing all patterns (QR spec)
- Focus on optimizing get_lost_points calculations
- Optimize demerit_points calculations

**Note**: Can't reduce number of patterns tested (spec requirement), but can optimize each pattern evaluation.

---

### Task #10: Benchmark Alternative Implementations
**Priority**: Low  
**Status**: Pending

**Goals**:
- After implementing optimizations, compare with baseline
- Document improvements in BENCHMARKS.md
- Consider alternative algorithms if performance goals not met
- Compare with other QR code libraries for reference

---

## Execution Order

Recommended order for maximum impact:

1. ✅ **ARCH_BITS Investigation** - COMPLETE - Proven 70-76% memory savings + 2-4% speed boost
2. **Profile with stackprof** - Identify actual bottlenecks before optimizing
3. **Optimize identified hot paths** - Based on profiling results
4. **String concatenation** - Relatively easy, clear benchmark target
5. **Caching/memoization** - Progressive improvement
6. **Data structures** - Larger refactor, do later
7. **Algorithm improvements** - Most complex, do last

---

## Process for Each Task

1. **Before Changes**:
   - Run `rake benchmark:all > before_task_N.txt`
   - Document current behavior
   - Identify specific optimization targets

2. **Make Changes**:
   - Implement optimization
   - Run tests: `rake test`
   - Run linter: `rake standard`
   - Fix any issues

3. **After Changes**:
   - Run `rake benchmark:all > after_task_N.txt`
   - Compare results with baseline
   - Document improvements

4. **Update Documentation**:
   - Update this file with results
   - Update BENCHMARKS.md if significant improvement
   - Commit changes with clear message

---

## Success Metrics

Based on BENCHMARKS.md baseline:

### Memory Targets:
- Reduce memory allocations by 10-20% for single QR codes
- Reduce memory allocations by 15-30% for batch generation
- Focus on Integer and Array allocations (85-90% of total)

### Performance Targets:
- Improve large QR code (v20+) generation speed by 10-20%
- Improve batch generation throughput
- Maintain or improve small QR code performance

### Constraints:
- No breaking API changes
- All tests must pass
- Standard Ruby style compliance
- No external runtime dependencies

---

## Results Log

### Task #1: ARCH_BITS Investigation ✅
**Date**: December 4, 2025  
**Status**: Complete  
**Results**: 

**PROVEN: Setting `RQRCODE_CORE_ARCH_BITS=32` provides dramatic improvements with zero downsides:**

- **Memory**: 70-76% reduction across all scenarios
- **Speed**: 2-4% faster (not just "no penalty"—actually faster)
- **Objects**: 85-87% fewer allocations
- **Tests**: All 108 assertions pass
- **Correctness**: No issues found

**Impact by scenario:**
- Single small QR: 0.38 MB → 0.10 MB (74% reduction)
- Single large QR: 8.53 MB → 2.92 MB (66% reduction)
- Batch 100 small: 37.91 MB → 9.10 MB (76% reduction)

**Why it works:** The `rszf` function creates bit masks. With 64-bit, these require large integer allocations. With 32-bit, they fit into smaller representations, dramatically reducing memory allocation while improving cache locality.

**Action taken:**
- Updated README with prominent "Performance Optimization" section
- Updated code comments in `qr_util.rb` with concrete benchmark data
- Updated `docs/BENCHMARKS.md` with proven results
- Organized all benchmark files in `test/benchmarks/` directory
- Created comprehensive analysis document

**Recommendation:** Users should set `RQRCODE_CORE_ARCH_BITS=32` in production. Not changing library default to avoid surprises for existing users, but strongly recommending the optimization through documentation.

Full analysis available in `test/benchmarks/ARCH_BITS_ANALYSIS.md`.

---

## References

- [BENCHMARKS.md](BENCHMARKS.md) - Baseline performance metrics
- [Ruby Performance Optimization](https://ruby-doc.org/core/doc/performance_md.html)
- [memory_profiler gem](https://github.com/SamSaffron/memory_profiler)
- [stackprof gem](https://github.com/tmm1/stackprof)
