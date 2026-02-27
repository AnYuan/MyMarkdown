# Technical Debt Roadmap (as of 2026-02-27)

## Current Health Snapshot

- `swift test` result: `76` tests executed, all passing.
- Table rendering strategy is now aligned across code/tests/docs: monospaced + space-padding columns.

## Prioritized Debt List

| Priority | Debt Item | Current Impact | Recommended Action | Done Criteria |
|---|---|---|---|---|
| P0 | (Resolved) Table rendering strategy mismatch (code vs test vs docs) | Previously caused CI red and ambiguity | Canonicalized to monospaced + space-padding in implementation, tests, and docs | `swift test` all green; single documented table strategy |
| P0 | Public API facade is empty (`MyMarkdown.swift`) | Integration path for consumers is unclear | Add a minimal stable facade (`parse + layout + render model`) and keep internals behind it | External caller can render markdown without touching internal classes directly |
| P1 | Math rendering parity and determinism | UIKit/macOS behavior can diverge; snapshot sizing is fallback-based | Unify platform behavior, make size extraction explicit, and define fallback policy | Same markdown math yields equivalent visual output across supported platforms |
| P1 | Concurrency guarantees are implicit | `TextKit` objects are class-based and reused; future parallel solve calls may race | Document thread model and enforce isolation boundary (queue/actor or per-task instances) | No shared mutable `TextKit` state accessed concurrently |
| P1 | Documentation drift (coverage + feature docs) | Engineering decisions are based on stale text | Update coverage and feature docs after each test/feature change | Docs reflect current code and test status |
| P2 | Platform test matrix is uneven | Some UI paths only validated on one platform/config | Add CI matrix notes and minimum parity tests for iOS/macOS UI wrappers | Critical rendering paths covered on both target platforms |
| P2 | Performance targets lack reproducible benchmark baseline | Hard to detect regressions over time | Add reproducible benchmark scenario + output format using `PerformanceProfiler` | Baseline numbers versioned in docs and comparable per commit |

## Recommended Execution Order

1. Resolve table strategy mismatch first (P0) to get CI and docs back in sync.
2. Add public API facade (P0) before further feature growth.
3. Lock down thread-safety boundaries and math parity (P1).
4. Refresh docs and platform test matrix (P1/P2).
5. Add repeatable benchmark baseline (P2).

## Suggested Work Batches

### Batch A (Immediate, 1-2 commits)

- Align table implementation/tests/docs to one strategy.
- Ensure `swift test` is fully green.

### Batch B (Short term)

- Introduce public API facade in `MyMarkdown.swift`.
- Document thread-safety contract for layout and async rendering components.

### Batch C (Stabilization)

- Cross-platform math rendering parity updates.
- Documentation refresh and benchmark baseline publication.
