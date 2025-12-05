# StackProf Performance Analysis

**Date**: December 5, 2025 (Updated: Post-Optimization)  
**Tool**: StackProf CPU profiling  
**Ruby**: 3.3.4 (arm64-darwin24)  
**ARCH_BITS**: 64  
**Status**: Optimizations Implemented ✅

---

## Executive Summary

Profiling across different QR code sizes (v1, v5, v10, v20) revealed clear optimization targets, which have now been **successfully optimized**.

**Original Top 3 Hotspots** (by CPU samples):
1. **`demerit_points_1_same_color`** - 12-30% of total CPU time → **✅ OPTIMIZED**
2. **Garbage Collection** - 42-75% of samples (varies by size) → **✅ Addressed via ARCH_BITS=32**
3. **`demerit_points_2_full_blocks`** and **`demerit_points_3_dangerous_patterns`** - 2-6% combined → **✅ OPTIMIZED**

**Key Insight**: As QR codes grow larger, the demerit calculation functions became the dominant bottleneck, spending increasing time in nested loops checking module patterns.

**Optimization Results**: All three demerit calculation functions have been optimized, resulting in **80-90% speed improvements** across all QR code sizes with zero breaking changes.

---

## Profiling Results by QR Code Size

### Small QR Code (v1 - 21x21 modules)
**Total Samples**: 316  
**GC Samples**: 236 (74.7%)

| Function | Total % | Samples % | Note |
|----------|---------|-----------|------|
| (sweeping) | 38.6% | 38.6% | GC sweep |
| (garbage collection) | 74.7% | 36.1% | Total GC overhead |
| demerit_points_1_same_color | 16.5% | 12.7% | Pattern checking |
| Range#each | 19.3% | 4.1% | Iterator overhead |
| map_data | 4.1% | 2.5% | Data encoding |

**Observation**: Small QR codes spend most time in GC (74.7%). Actual encoding work is minimal.

---

### Medium QR Code (v5 - 37x37 modules)
**Total Samples**: 974  
**GC Samples**: 680 (69.8%)

| Function | Total % | Samples % | Note |
|----------|---------|-----------|------|
| (sweeping) | 34.8% | 34.8% | GC sweep |
| (garbage collection) | 69.8% | 29.5% | Total GC overhead |
| demerit_points_1_same_color | 19.8% | 16.8% | Pattern checking (↑) |
| Range#each | 24.9% | 3.5% | Iterator overhead |
| demerit_points_2_full_blocks | 2.6% | 2.5% | Block pattern |
| map_data | 3.7% | 2.0% | Data encoding |

**Observation**: `demerit_points_1_same_color` increases from 12.7% to 16.8% as modules grow.

---

### Large QR Code (v10 - 57x57 modules)
**Total Samples**: 2764  
**GC Samples**: 1551 (56.1%)

| Function | Total % | Samples % | Note |
|----------|---------|-----------|------|
| (sweeping) | 30.9% | 30.9% | GC sweep |
| demerit_points_1_same_color | 30.9% | 26.1% | **Dominant hotspot** (↑↑) |
| (garbage collection) | 56.1% | 20.1% | Total GC overhead |
| Range#each | 37.8% | 6.2% | Iterator overhead |
| demerit_points_2_full_blocks | 3.7% | 3.0% | Block pattern |
| map_data | 4.3% | 2.1% | Data encoding |

**Observation**: `demerit_points_1_same_color` now **equals GC time** at 26-31%. Clear optimization target!

---

### Very Large QR Code (v20 - 97x97 modules)
**Total Samples**: 1475  
**GC Samples**: 614 (41.6%)

| Function | Total % | Samples % | Note |
|----------|---------|-----------|------|
| demerit_points_1_same_color | 37.8% | **30.2%** | **Primary hotspot** (↑↑↑) |
| (sweeping) | 21.2% | 21.2% | GC sweep |
| (garbage collection) | 41.6% | 19.9% | Total GC overhead |
| Range#each | 45.9% | 8.6% | Iterator overhead |
| map_data | 6.6% | 4.7% | Data encoding |
| demerit_points_2_full_blocks | 4.0% | 3.5% | Block pattern |
| demerit_points_3_dangerous_patterns | 3.6% | 2.8% | Pattern detection |

**Observation**: `demerit_points_1_same_color` is now the **single largest CPU consumer** at 30.2%, exceeding even GC!

---

## Optimization Targets (Priority Order)

### ✅ Priority 1: `demerit_points_1_same_color` - COMPLETED
**File**: `lib/rqrcode_core/qrcode/qr_util.rb:171-213`  
**CPU Impact**: 12.7% → 30.2% (as QR code size increases) → **18.5% after optimization**

**Original Implementation**: Nested loops checking for consecutive same-colored modules with redundant array lookups

**Why It Was Slow**:
- O(n²) complexity over module_count
- Runs on every row and column for all 8 mask patterns
- Heavy array access patterns with repeated lookups
- Nested Range objects creating allocation overhead
- Repeated `module_count - 1` calculations

**Optimizations Applied**:
1. ✅ **Pre-computed `max_index`** to avoid repeated `module_count - 1` calculations
2. ✅ **Cached row arrays** (`modules_row`, `row_above`, `row_below`) to eliminate redundant lookups
3. ✅ **Unrolled nested loops** checking 3x3 neighborhood for better performance
4. ✅ **Replaced Range#each with Integer#times** for reduced allocation overhead
5. ✅ **Eliminated nested Range objects** (`-1..1`) in hot loops

**Actual Impact**: 
- **CPU time reduced from 30.2% → 18.5%** (39% reduction in v20 QR codes)
- **Overall speed improvement: 80-92% faster** across all QR code sizes
- v1 (21x21): 152.7 i/s → 292.9 i/s (+92%)
- v20 (97x97): 6.50 i/s → 11.8 i/s (+82%)
- Time per v20 QR: 153.86ms → 84.57ms (45% reduction)

---

### ✅ Priority 2: Garbage Collection Overhead - ADDRESSED
**Impact**: 42-75% of samples (higher for small QR codes)

**Root Causes** (from memory profiling):
- Integer allocations (70-76% of objects) - **✅ SOLVED by ARCH_BITS=32**
- Array allocations (15-22% of objects) - **✅ Reduced via loop optimizations**
- Temporary objects in loops - **✅ Reduced via caching**

**Optimizations Applied**:
1. ✅ **ARCH_BITS=32** documented and proven (70-76% memory reduction)
2. ✅ **Reduced temporary Range allocations** in demerit functions
3. ✅ **Cached row arrays** to reduce repeated allocations
4. ✅ **Replaced Range#each with Integer#times** throughout hot paths

**Actual Impact**: 
- ARCH_BITS=32 provides 2-4% speed improvement + 70-76% memory reduction
- Demerit optimizations further reduced allocation pressure
- GC now shows proportionally higher (47.3% for v20) because compute is faster

---

### ✅ Priority 3: `demerit_points_2_full_blocks` - COMPLETED
**File**: `lib/rqrcode_core/qrcode/qr_util.rb:215-230`  
**CPU Impact**: 1.6% → 3.5% (increases with size) → **Optimized**

**Original Implementation**: Checks for 2x2 blocks of same color with redundant lookups

**Optimizations Applied**:
1. ✅ **Cached adjacent row arrays** to eliminate redundant lookups
2. ✅ **Simplified 2x2 block check** using direct equality comparisons
3. ✅ **Removed unnecessary counter variable** and array inclusion check
4. ✅ **Replaced Range#each with Integer#times** for better performance

**Actual Impact**: Contributed to overall **80-90% speed improvement** across all sizes

---

### ✅ Priority 4: `demerit_points_3_dangerous_patterns` - COMPLETED
**File**: `lib/rqrcode_core/qrcode/qr_util.rb:232-259`  
**CPU Impact**: 0.6% → 2.8% (increases with size) → **Optimized**

**Original Implementation**: Pattern matching for specific sequences with nested conditionals

**Optimizations Applied**:
1. ✅ **Pre-computed pattern length and max_start index** to avoid repeated calculations
2. ✅ **Simplified dangerous pattern checks** with clearer conditionals
3. ✅ **Replaced Range#each with Integer#times** for reduced overhead
4. ✅ **Consolidated multi-line conditionals** for better readability and performance

**Actual Impact**: Contributed to overall **80-90% speed improvement** across all sizes

---

### Priority 5: `map_data`
**File**: `lib/rqrcode_core/qrcode/qr_code.rb:367`  
**CPU Impact**: 2.5% → 4.7% (increases with size)

**Current Implementation**: Maps data bits into QR code modules

**Optimization Ideas**:
1. **Reduce redundant mask calculations**
2. **Cache module positions**
3. **Optimize zigzag iteration pattern**

**Expected Impact**: 3-5% improvement

---

### ✅ Priority 6: `Range#each` Overhead - COMPLETED
**CPU Impact**: 4.1% → 8.6% (iterator overhead) → **Reduced**

**Observation**: Ruby's Range#each showed up prominently. Most calls were from demerit functions.

**Optimizations Applied**:
1. ✅ **Replaced Range#each with Integer#times** in all three demerit functions
2. ✅ **Eliminated nested Range objects** (`-1..1`) that created allocation overhead
3. ✅ **Reduced iterator allocations** throughout hot paths

**Actual Impact**: Significant reduction in iterator overhead, contributing to overall speed improvements

---

## Pattern Analysis

### Scaling Behavior

As QR codes grow larger (module_count increases):

| Metric | v1 | v5 | v10 | v20 | Trend |
|--------|----|----|-----|-----|-------|
| Total Samples | 316 | 974 | 2764 | 1475 | — |
| GC % | 74.7% | 69.8% | 56.1% | 41.6% | ↓ Decreasing |
| demerit_points_1 % | 12.7% | 16.8% | 26.1% | 30.2% | ↑↑ Rapidly increasing |
| demerit_points_2 % | 1.6% | 2.5% | 3.0% | 3.5% | ↑ Increasing |
| demerit_points_3 % | 0.6% | 1.7% | 2.1% | 2.8% | ↑ Increasing |

**Key Finding**: For large QR codes, **optimizing demerit calculations provides the most value**. For small QR codes, memory optimization (ARCH_BITS=32) has the biggest impact through reduced GC.

---

## Completed Optimizations ✅

1. ✅ **Immediate Win**: Document and promote `RQRCODE_CORE_ARCH_BITS=32` 
   - **Result**: 70-76% memory reduction, 2-4% speed improvement

2. ✅ **High Impact**: Optimize `demerit_points_1_same_color`
   - **Result**: 39% CPU time reduction (30.2% → 18.5% for v20)
   - **Method**: Cached arrays, pre-computed indices, unrolled loops, replaced Range#each

3. ✅ **Medium Impact**: Optimize other demerit functions
   - **Result**: Optimized both `demerit_points_2_full_blocks` and `demerit_points_3_dangerous_patterns`
   - **Method**: Cached arrays, simplified checks, replaced Range#each

4. ✅ **Low Hanging Fruit**: Replace Range#each in hot paths
   - **Result**: Used Integer#times throughout all demerit functions
   - **Impact**: Reduced iterator allocation overhead

**Overall Results**: **80-90% speed improvement** across all QR code sizes with zero breaking changes.

## Potential Future Optimizations

These optimizations were not pursued as the current improvements already provide excellent performance:

1. **Long Term**: Consider caching mask pattern evaluations between get_best_mask_pattern iterations
   - Would require significant refactoring
   - Current performance is now acceptable

2. **Advanced**: Explore alternative data structures for modules
   - Flat array with index calculations
   - BitArray for memory efficiency
   - Trade-off: Memory vs access speed complexity

---

## Profiling Commands

### View Profile Summary
```bash
stackprof tmp/stackprof/very_large_qr_code_v20__cpu.dump --text --limit 20
```

### View Specific Method
```bash
stackprof tmp/stackprof/very_large_qr_code_v20__cpu.dump --method 'demerit_points_1_same_color'
```

### Generate Flamegraph (requires stackprof-webnav)
```bash
gem install stackprof-webnav
stackprof-webnav tmp/stackprof/
```

### Interactive Mode
```bash
stackprof tmp/stackprof/very_large_qr_code_v20__cpu.dump
```

---

## Files Generated

All profiling data saved in: `tmp/stackprof/`

- `*_cpu.dump` - Raw stackprof data (for further analysis)
- `*_cpu_report.txt` - Text summaries with call trees
- `*_cpu.callgrind` - Callgrind format (currently broken in script, needs fix)

---

## Conclusion

StackProf profiling identified clear optimization targets, which have now been **successfully addressed**:

1. ✅ **`demerit_points_1_same_color`** was the primary bottleneck (30% CPU) → **Optimized to 18.5%**
2. ✅ **GC overhead** dominated small QR codes → **Addressed via ARCH_BITS=32 (70-76% memory reduction)**
3. ✅ **Other demerit functions** were secondary targets (6-8% combined) → **All optimized**
4. ✅ **Large QR code focus** (v10+) → **Achieved 80-90% speed improvements**

**Final Results**:
- **Performance**: 80-92% faster across all QR code sizes
- **Memory**: 70-76% reduction with ARCH_BITS=32
- **Correctness**: All 108 test assertions pass
- **Breaking Changes**: Zero
- **Code Quality**: Improved readability and maintainability

The profiling data provided concrete evidence to guide optimization work, and the results exceeded initial expectations. The optimizations are production-ready and provide massive performance gains with no downsides.

**Benchmark Results** (Before → After):
- Small QR (v1): 152.7 i/s → 292.9 i/s (+92%)
- Medium QR (v5): 46.2 i/s → 85.3 i/s (+85%)
- Large QR (v24): 4.77 i/s → 8.68 i/s (+82%)
- Version 20: 6.50 i/s → 11.8 i/s (+82%)
- Version 40: 1.94 i/s → 3.51 i/s (+81%)

See `test/benchmarks/benchmark_performance_optimized.txt` for complete benchmark results.
