# MarkdownKit

MarkdownKit is a high-performance native Markdown renderer for Apple platforms, built in Swift with `swift-markdown` and TextKit-based layout.

## Highlights

- CommonMark + GitHub Flavored Markdown (tables, task lists, strikethrough, links)
- Native table rendering (`NSTextTable`) with GitHub-like styling
- Math support (`$...$`, `$$...$$`, and fenced `math`) via MathJaxSwift
- Collapsed sections support (`<details>/<summary>`)
- Diagram fence detection (`mermaid`, `geojson`, `topojson`, `stl`) with pluggable adapter fallback
- Async layout pipeline and virtualized iOS/macOS collection views

## Requirements

- Swift 6.2+
- iOS 17.0+
- macOS 26.0+

## Quick Start

```bash
swift build
swift test
swift run MarkdownKitDemo
```

## Basic Usage

```swift
import MarkdownKit

let parser = MarkdownKitEngine.makeParser()
let solver = MarkdownKitEngine.makeLayoutSolver()

let document = parser.parse("# Hello MarkdownKit")
let layout = await solver.solve(node: document, constrainedToWidth: 800)
print(layout.children.count)
```

## One-Call Convenience

```swift
import MarkdownKit

let layout = await MarkdownKitEngine.layout(
    markdown: "# Hello\n\nThis is **MarkdownKit**.",
    constrainedToWidth: 800
)
print(layout.children.count)
```

## Automated Verification

Fast regression gate (recommended for daily iteration):

```bash
bash scripts/verify_fast.sh
```

Benchmark-only gate (heavier):

```bash
bash scripts/verify_benchmarks.sh
```

Combined wrapper (fast + optional heavy):

```bash
bash scripts/verify_all.sh
```

Optional heavy benchmark suites:

```bash
bash scripts/verify_all.sh --with-benchmarks
```

One-shot full suite (includes all tests, including benchmarks/snapshots):

```bash
bash scripts/verify_all.sh --full
```

### Test Split Strategy

The test suite is split into fast regression tests and heavy benchmarks:

- **Fast suite** (`verify_fast.sh`): ~200 tests covering parsing, layout, plugins, security, and snapshot stability. Runs in under 60 seconds. Used as CI gate.
- **Benchmark suite** (`verify_benchmarks.sh`): Heavy performance regression tests. Run locally or in nightly CI.
- Running bare `swift test` executes everything including benchmarks. Prefer `verify_fast.sh` for daily iteration.

## Project Structure

- `Sources/MarkdownKit`: core parser, AST nodes, plugins, layout engine, UI components
- `Sources/MarkdownKitDemo`: demo app
- `Tests/MarkdownKitTests`: unit/integration tests
- `docs/`: PRD, feature notes, roadmap
- `scripts/`: local automation and verification entrypoints
- `tasks/`: implementation checklist
