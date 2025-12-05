# StackProf Performance Analysis

**Date**: December 5, 2025  
**Tool**: StackProf CPU profiling  
**Ruby**: 3.3.4 (arm64-darwin24)  
**ARCH_BITS**: 64

---

## Executive Summary

Profiling across different QR code sizes (v1, v5, v10, v20) reveals clear optimization targets:

**Top 3 Hotspots** (by CPU samples):
1. **`demerit_points_1_same_color`** - 12-30% of total CPU time
2. **Garbage Collection** - 42-75% of samples (varies by size)
3. **`demerit_points_2_full_blocks`** and **`demerit_points_3_dangerous_patterns`** - 2-6% combined

**Key Insight**: As QR codes grow larger, the demerit calculation functions become the dominant bottleneck, spending increasing time in nested loops checking module patterns.

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

### 🔥 Priority 1: `demerit_points_1_same_color`
**File**: `lib/rqrcode_core/qrcode/qr_util.rb:171`  
**CPU Impact**: 12.7% → 30.2% (as QR code size increases)

**Current Implementation**: Nested loops checking for consecutive same-colored modules

**Why It's Slow**:
- O(n²) complexity over module_count
- Runs on every row and column for all 8 mask patterns
- Heavy array access patterns
- No early termination or caching

**Optimization Ideas**:
1. **Cache mask pattern results** between iterations
2. **Vectorize** consecutive checks (count runs in single pass)
3. **Pre-compute** module patterns where possible
4. **Early termination** when demerit score exceeds thresholds
5. **Reduce redundant array access** - store values in locals

**Expected Impact**: 15-30% speed improvement for large QR codes

---

### 🔥 Priority 2: Garbage Collection Overhead
**Impact**: 42-75% of samples (higher for small QR codes)

**Root Causes** (from memory profiling):
- Integer allocations (70-76% of objects) - **SOLVED by ARCH_BITS=32**
- Array allocations (15-22% of objects)
- Temporary objects in loops

**Optimization Ideas**:
1. **Use ARCH_BITS=32** (already documented, proven 70-76% memory reduction)
2. **Reduce temporary arrays** in polynomial operations
3. **Reuse buffers** where safe
4. **Object pooling** for frequently allocated types

**Expected Impact**: ARCH_BITS=32 already provides 2-4% speed improvement

---

### 🔥 Priority 3: `demerit_points_2_full_blocks`
**File**: `lib/rqrcode_core/qrcode/qr_util.rb:202`  
**CPU Impact**: 1.6% → 3.5% (increases with size)

**Current Implementation**: Checks for 2x2 blocks of same color

**Optimization Ideas**:
1. **Single-pass detection** instead of multiple range iterations
2. **Bit manipulation** for faster 2x2 pattern matching
3. **Cache** intermediate results

**Expected Impact**: 5-10% improvement in demerit calculations

---

### 🔥 Priority 4: `demerit_points_3_dangerous_patterns`
**File**: `lib/rqrcode_core/qrcode/qr_util.rb:223`  
**CPU Impact**: 0.6% → 2.8% (increases with size)

**Current Implementation**: Pattern matching for specific sequences

**Optimization Ideas**:
1. **Pre-compile patterns** as bit masks
2. **Rolling hash** for pattern detection
3. **Reduce array allocations** in pattern checks

**Expected Impact**: 3-5% improvement in demerit calculations

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

### Priority 6: `Range#each` Overhead
**CPU Impact**: 4.1% → 8.6% (iterator overhead)

**Observation**: Ruby's Range#each shows up prominently. Most calls are from demerit functions.

**Optimization Ideas**:
1. **Replace Range#each with while loops** in hot paths
2. **Use Integer#times** instead of ranges where appropriate
3. **Reduce iterator allocations**

**Expected Impact**: 2-4% improvement

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

## Recommended Next Steps

1. **Immediate Win**: Document and promote `RQRCODE_CORE_ARCH_BITS=32` (✅ Already done)

2. **High Impact**: Optimize `demerit_points_1_same_color`
   - Profile specific code paths within the function
   - Implement vectorized counting or caching
   - Benchmark improvements

3. **Medium Impact**: Optimize other demerit functions
   - Reduce redundant iterations
   - Cache intermediate results
   - Use more efficient data structures

4. **Low Hanging Fruit**: Replace Range#each with while loops in hot paths

5. **Long Term**: Consider caching mask pattern evaluations between get_best_mask_pattern iterations

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

StackProf profiling has identified clear optimization targets:

1. **`demerit_points_1_same_color`** is the primary bottleneck for large QR codes (30% CPU)
2. **GC overhead** dominates small QR codes but is addressable via ARCH_BITS=32
3. **Other demerit functions** are secondary targets (6-8% combined)
4. **The optimization effort should focus on large QR codes** (v10+) where performance degrades most significantly

The profiling data provides concrete evidence to guide optimization work, ensuring we focus on changes that will have measurable impact.
