# Technical Debt Roadmap (as of 2026-03-04)

## Current Health Snapshot

- `swift test`: **218 tests executed, 0 failures** (latest local run).
- Snapshot drift issue on macOS has been stabilized by fixing test appearance constraints.
- Mermaid adapter/API mismatch (`MermaidHTMLBuilder.makeHTML`) has been repaired.
- Public API facade (`MarkdownKitEngine`) is already available and documented in README.

## Prioritized Debt List

| Priority | Debt Item | Current Impact | Recommended Action | Done Criteria |
|---|---|---|---|---|
| P1 | MathJax warning noise for unsupported formulas (e.g. `\\binom`) | Benchmark/test logs become noisy, making real failures harder to spot | Add warning suppression/dedup policy and explicit fallback behavior tests | Repeated warnings are throttled and fallback path is covered by tests |
| P1 | Concurrency model is implicit (layout/math/webview pipelines) | Future refactors can accidentally introduce shared-state races | Document isolation boundaries (what is `MainActor`, what is background safe), and add guard tests where practical | Threading contract documented and regression-tested for key paths |
| P1 | `SplashHighlighter.highlight(_:language:)` ignores `language` parameter | API intent and actual behavior diverge; language-specific expectations may be misleading | Either implement language-aware behavior or document/deprecate argument semantics | Public API semantics and implementation are aligned |
| P2 | iOS table rendering still uses text/tab emulation while macOS uses native table blocks | Cross-platform visual parity gap remains for complex tables | Continue improving iOS readability and clarify parity boundary in docs/tests | Narrow-width and alignment behavior stay stable; constraints documented |
| P2 | Verification cost for full suite remains high (benchmarks in `swift test`) | Slower local feedback loop | Keep fast-path verification as default and separate heavy benchmark path | Team default command runs quickly; heavy path is explicit |
| P2 | Documentation drift can reappear as test counts/features evolve | Mismatch between docs and code causes onboarding confusion | Automate or semi-automate doc refresh for coverage/status docs | Coverage/status docs generated from repeatable commands/scripts |

## Recommended Execution Order

1. Reduce MathJax warning noise and lock fallback expectations.
2. Clarify concurrency/isolation contract for layout + renderer subsystems.
3. Align `SplashHighlighter` language API behavior or contract.
4. Keep improving iOS table parity within current architecture constraints.
5. Continue hardening verification workflow and doc automation.

## Suggested Work Batches

### Batch A (Immediate)

- Math warning throttling + tests.
- Verification workflow split (fast vs heavy) and command docs.

### Batch B (Short Term)

- Concurrency contract documentation update.
- `SplashHighlighter` API/behavior alignment.

### Batch C (Stabilization)

- iOS table parity incremental improvements.
- Continue reducing manual documentation maintenance.
