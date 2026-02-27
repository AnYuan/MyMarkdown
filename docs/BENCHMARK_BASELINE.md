# MarkdownKit Benchmark Baseline

**Date**: 2026-02-27
**Platform**: macOS · arm64 (Apple Silicon)
**Harness**: BenchmarkHarness (warmup=3, iterations=20, mach_absolute_time)
**Commit**: `2f0fd51`

## Phase 1: Parse

| Operation | Avg | P50 | P95 | Mem |
|-----------|-----|-----|-----|-----|
| parse(small) | 0.24ms | 0.24ms | 0.24ms | 16KB |
| parse(medium) | 1.63ms | 1.62ms | 1.72ms | 32KB |
| parse(large) | 12.67ms | 12.45ms | 13.96ms | 32KB |
| parse(code-heavy) | 0.26ms | 0.26ms | 0.27ms | ~0 |
| parse(table-heavy) | 12.57ms | 12.40ms | 13.58ms | 32KB |
| parse(math-heavy) | 0.53ms | 0.52ms | 0.62ms | 16KB |

## Phase 2: Layout (solve)

| Operation | Avg | P50 | P95 | Mem |
|-----------|-----|-----|-----|-----|
| solve(small) | 0.62ms | 0.60ms | 0.67ms | 32KB |
| solve(medium) | 110.9ms | 109.6ms | 118.0ms | 272KB |
| solve(large) | 28.77ms | 28.63ms | 29.17ms | 32KB |
| solve(code-heavy) | 14.67ms | 14.64ms | 15.06ms | ~0 |
| solve(table-heavy) | 16.32ms | 16.31ms | 16.54ms | 16KB |
| solve(math-heavy) | 57.02ms | 56.66ms | 59.45ms | 608KB |

## Cache Performance

| Operation | Avg | P50 | P95 | Mem |
|-----------|-----|-----|-----|-----|
| solve(cold)(medium) | 113.1ms | 110.0ms | 119.1ms | 160KB |
| solve(warm)(medium) | 0.006ms | 0.006ms | 0.007ms | ~0 |
| getLayout(hit) | <0.001ms | <0.001ms | 0.001ms | ~0 |
| getLayout(miss) | <0.001ms | <0.001ms | <0.001ms | ~0 |
| setLayout() | <0.001ms | <0.001ms | 0.001ms | ~0 |
| clear() | <0.001ms | <0.001ms | <0.001ms | ~0 |
| solve(tiny-cache, eviction) | 1558ms | 1510ms | 1799ms | 192KB |
| solve(large-cache, no eviction) | 0.018ms | 0.017ms | 0.022ms | ~0 |

## Per-Node-Type Layout

| Node Type | Avg | P50 | P95 | Mem |
|-----------|-----|-----|-----|-----|
| headers (20 H1-H3) | 1.46ms | 1.47ms | 1.83ms | ~0 |
| paragraphs (20 mixed) | 2.55ms | 2.53ms | 2.74ms | ~0 |
| code-blocks (5×15 lines) | 15.27ms | 15.20ms | 15.58ms | 32KB |
| unordered-lists (5×8) | 1.54ms | 1.53ms | 1.60ms | 32KB |
| ordered-lists (5×8) | 1.57ms | 1.57ms | 1.62ms | ~0 |
| blockquotes (15) | 1.60ms | 1.58ms | 1.67ms | ~0 |
| tables (3×4×10) | 2.86ms | 2.83ms | 3.06ms | 32KB |
| thematic-breaks (20) | 0.94ms | 0.91ms | 1.10ms | ~0 |

## Per-Syntax Tiered (simple / complex / extreme)

| Syntax | Simple | Complex | Extreme | Extreme Mem |
|--------|--------|---------|---------|-------------|
| header | 0.045ms | 0.52ms | 3.86ms | ~0 |
| paragraph | 0.043ms | 0.45ms | 6.74ms | ~0 |
| code-block | 0.66ms | 11.9ms | 224ms | 48KB |
| unordered-list | 0.13ms | 1.14ms | 7.29ms | 112KB |
| ordered-list | 0.14ms | 1.34ms | 7.23ms | ~0 |
| blockquote | 0.061ms | 0.46ms | 4.39ms | ~0 |
| table | 0.21ms | 1.82ms | 12.1ms | 32KB |
| thematic-break | 0.056ms | 0.43ms | 2.13ms | ~0 |
| inline-mix | 0.055ms | 0.44ms | 2.53ms | ~0 |

## Input Size Scaling

| Lines | Parse | Layout | Combined |
|-------|-------|--------|----------|
| 10 | 1.56ms | 1.46ms | ~3ms |
| 50 | 4.04ms | 4.70ms | ~9ms |
| 200 | 16.2ms | 18.2ms | ~34ms |
| 1000 | 81.9ms | 89.4ms | ~171ms |

Scaling characteristic: **O(n)** — both parse and layout scale linearly with input size.

## Width Scaling (medium fixture)

| Width | Avg | P95 |
|-------|-----|-----|
| 320px | 117.3ms | 120.3ms |
| 600px | 116.0ms | 121.5ms |
| 800px | 111.6ms | 117.7ms |
| 1024px | 115.5ms | 121.6ms |

Width has negligible impact on layout performance.

## Plugin Composition (large fixture)

| Config | Avg | Delta |
|--------|-----|-------|
| 0 plugins | 6.31ms | — |
| 1 plugin (math) | 8.24ms | +1.93ms |
| 2 plugins (math+diagram) | 9.38ms | +1.14ms |
| 3 plugins (all) | 12.41ms | +3.03ms |

Each plugin adds ~1-3ms marginal cost on the large fixture.

## Concurrency

| Mode | Avg | Speedup |
|------|-----|---------|
| sequential 4x (medium) | 462.7ms | 1.0x |
| concurrent 4x (medium) | 119.4ms | 3.9x |

Near-linear concurrency speedup on 4 parallel layout solves.

## Key Observations

1. **Code-block rendering is the primary bottleneck** — Splash syntax highlighting dominates at 224ms for extreme tier (10 blocks × 100 lines), while paragraph extreme is only 6.7ms.
2. **Cache is effectively free** — hit/miss/set/clear all <0.001ms. Warm cache eliminates 99.99% of solve cost.
3. **Cache eviction is catastrophic** — tiny cache (countLimit=10) causes 1.5s vs 0.018ms with large cache. The default 100k limit is well-chosen.
4. **Math rendering is memory-intensive** — 608KB peak for math-heavy fixture due to MathJax/WKWebView rasterization.
5. **Tables scale sub-linearly** — 10×50 extreme table at 12ms, not disproportionately expensive.
6. **Pipeline is O(n)** — confirmed linear scaling from 10 to 1000 lines for both parse and layout.
7. **Width is irrelevant** — 320px to 1024px shows <5% variance in layout time.

## Reproduction

```bash
swift test --filter "MarkdownKitBenchmarkTests/testBenchmarkFullReport"
swift test --filter "BenchmarkNodeTypeTests/testDeepBenchmarkFullReport"
swift test --filter "BenchmarkNodeTypeTests/testPerSyntaxTieredBenchmark"
swift test --filter "BenchmarkCacheTests"
```
