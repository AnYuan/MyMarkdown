# MarkdownKit Codebase Knowledge (2026-03-03)

This document is a consolidated engineering knowledge base for the current `MarkdownKit` repository state.
It is intended to replace ad-hoc manual checking with a reproducible understanding of architecture, behaviors, tests, and known risks.

## 1. Repository Snapshot

- Branch: `main`
- HEAD: `90bfd6b` (`fix: add 8pt horizontal inset to iOS UIKit table rendering...`)
- Swift tools: `6.2`
- Platforms (Package.swift): `iOS 17+`, `macOS 26.0+` (note: future OS target is intentional in this repo)
- Dependencies:
  - `apple/swift-markdown` (`branch: main`)
  - `JohnSundell/Splash` (`>= 0.16.0`)
  - `colinc86/MathJaxSwift` (`>= 3.4.0`)
  - `pointfreeco/swift-snapshot-testing` (`>= 1.17.0`)
- File counts at review time:
  - Source files (`Sources/MarkdownKit/**/*.swift`): 53
  - Test files (`Tests/MarkdownKitTests/*.swift`): 47
  - Docs files (`docs/*.md`): 13 (before adding this file)

## 2. Build / Run / Test Commands

### 2.1 Core commands

```bash
swift build
swift test
swift run MarkdownKitDemo
```

### 2.2 High-value verification commands (automation-first)

```bash
# Syntax + width + plugin pipeline regression gate
swift test --filter SyntaxMatrixTests

# CommonMark corpus parse resilience (652 fixtures)
swift test --filter CommonMarkSpecTests

# Security guardrails
swift test --filter URLSanitizerTests
swift test --filter DepthLimitTests
swift test --filter FuzzTests

# Benchmarks + regression guardrails
swift test --filter MarkdownKitBenchmarkTests/testBenchmarkFullReport
swift test --filter BenchmarkNodeTypeTests/testDeepBenchmarkFullReport
```

### 2.3 Results captured during this review

- `SyntaxMatrixTests`: pass (1 test, 0 failures)
- `MarkdownKitBenchmarkTests/testBenchmarkFullReport`: pass (1 test, 0 failures)
- `BenchmarkNodeTypeTests/testDeepBenchmarkFullReport`: pass (1 test, 0 failures)
- Benchmark runs still print repeated MathJax warnings for `\binom` (known limitation in current math conversion path).

## 3. End-to-End Architecture

Pipeline:

1. `MarkdownParser.parse(_:)`
2. `swift-markdown` builds `Document`
3. `MarkdownKitVisitor` maps syntax tree to internal `MarkdownNode` structs
4. `ASTPlugin` chain rewrites AST (`Details`, `Diagram`, `Math`, optional `GitHubAutolink`)
5. `LayoutSolver.solve(node:width:)` creates themed attributed output + size via `TextKitCalculator`
6. `LayoutCache` memoizes `(nodeID, width)` results
7. Platform UI containers (`MarkdownCollectionView`) mount `LayoutResult` rows
8. Node-specific views render asynchronously (`AsyncTextView`, `AsyncCodeView`, `AsyncImageView`)

Core design goal: do parsing/layout expensive work off main thread, keep collection sizing O(1) at render time.

## 4. Module Knowledge

### 4.1 Parsing Layer

Primary files:

- `Sources/MarkdownKit/Parsing/MarkdownParser.swift`
- `Sources/MarkdownKit/Parsing/MarkdownKitVisitor.swift`
- `Sources/MarkdownKit/Parsing/ASTPlugin.swift`
- `Sources/MarkdownKit/Parsing/*ExtractionPlugin.swift`
- `Sources/MarkdownKit/Parsing/Plugins/GitHubAutolinkPlugin.swift`

Key facts:

- `MarkdownParser` accepts ordered plugin list; order matters for transformation behavior.
- `MarkdownKitVisitor` has recursion-depth protection (`maxDepth`, default 50).
- `HTMLBlock` and `InlineHTML` currently degrade to `TextNode` raw text; feature plugins then reinterpret recognized syntax.
- `visitSoftBreak` converts to `" "` and `visitLineBreak` to `"\n"`.

### 4.2 AST Nodes

Node system is strongly typed and immutable-ish (`struct`, UUID id, child arrays):

- Block nodes: `DocumentNode`, `HeaderNode`, `ParagraphNode`, `CodeBlockNode`, `ListNode`, `ListItemNode`, `Table*`, `BlockQuoteNode`, `ThematicBreakNode`, `DetailsNode`, `SummaryNode`, `DiagramNode`
- Inline nodes: `TextNode`, `InlineCodeNode`, `LinkNode`, `ImageNode`, `EmphasisNode`, `StrongNode`, `StrikethroughNode`
- Other: `MathNode`

Security boundary:

- `LinkNode` and `ImageNode` sanitize URLs via `URLSanitizer` at init time.

### 4.3 Plugins and Their Contracts

### `MathExtractionPlugin`

- Converts:
  - Inline `$...$` -> `MathNode(.inline)`
  - Multi-paragraph `$$ ... $$` -> `MathNode(.block)`
  - Fenced code languages `math|latex|tex` -> `MathNode(.block)`
- Guards against escaped dollars and naive false positives.

### `DiagramExtractionPlugin`

- Converts fenced code (`mermaid`, `geojson`, `topojson`, `stl`) from `CodeBlockNode` to `DiagramNode`.
- Recurses through nested nodes, including details/table/list trees.

### `DetailsExtractionPlugin`

- Rewrites `<details>` / `<summary>` raw HTML-like text into `DetailsNode` + `SummaryNode`.
- Supports:
  - inline `<summary>text</summary>`
  - multi-line `<summary>` ... `</summary>`
  - nested details
  - `open` attribute parsing
- Malformed details without matching close tag are kept unmodified.

### `GitHubAutolinkPlugin`

- Matches and rewrites:
  - `@mention`
  - issue/reference forms like `#123` / `owner/repo#123`
  - commit SHA (7-40 hex)
- Wraps matches into `LinkNode` using delegate-resolved URL or fallback custom schemes (`x-mention://`, etc.).
- Does not recurse inside existing links/code/math/diagram/image nodes.

### 4.4 Layout and Styling Layer

Primary files:

- `Sources/MarkdownKit/Layout/LayoutSolver.swift`
- `Sources/MarkdownKit/Layout/TextKitCalculator.swift`
- `Sources/MarkdownKit/Layout/LayoutCache.swift`
- `Sources/MarkdownKit/Theme/Theme.swift`
- `Sources/MarkdownKit/Highlighter/SplashHighlighter.swift`

Key behaviors:

- `LayoutSolver.solve`:
  - yields cooperatively (`Task.yield`)
  - cache hit short-circuit
  - builds attributed text and measures it
  - special inset math for code/diagram blocks
  - recursively solves children for `DocumentNode`

- `TextKitCalculator` uses TextKit 2 stack (`NSTextLayoutManager`, `NSTextContainer`, etc.) and returns ceiled size.

- Theme tokens:
  - typography per major type (`header1`, `header2`, `header3`, `paragraph`, `codeBlock`)
  - color tokens for text, code, table

### Node-specific layout details

- Inline code:
  - Monospaced font, background color, foreground from `theme.codeColor`
  - No lexical token highlight for inline code (style only)
- Code block:
  - Optional uppercase language label line (`SWIFT`, etc.)
  - Splash highlight output
- Links:
  - `systemBlue` + underline + `.link` attribute
- Images:
  - Attempt async load and attach as `NSTextAttachment`
  - On failure fallback to `[alt]` text in secondary label color
- Math:
  - Uses `MathRenderer` image attachment when possible
  - Fallback to raw equation text (code-like style)
- Details:
  - Closed: `▶ summary`
  - Open: `▼ summary` + body lines
- Thematic break:
  - Rendered as 40 `─` characters
- Blockquote:
  - Prefix `┃`, indented paragraph style

### Table rendering by platform

- macOS (`AppKit` path):
  - Real `NSTextTableBlock` rendering with borders/background.
  - Supports zebra stripe + alignment + cell block configuration.
- iOS (`UIKit` path):
  - Tab-stop based pseudo-table layout (not `NSTextTableBlock`).
  - Uses row text with `\t`, header separator via dash rows, and 8pt horizontal inset.
  - Practical for speed and compatibility, but visual richness is lower than AppKit path.

### 4.5 UI Layer

Primary files:

- iOS:
  - `UI/iOS/MarkdownCollectionView_iOS.swift`
  - `UI/iOS/MarkdownCollectionViewCell.swift`
  - `UI/Components/AsyncTextView.swift`
  - `UI/Components/AsyncCodeView.swift`
  - `UI/Components/AsyncImageView.swift`
- macOS:
  - `UI/macOS/MarkdownCollectionView_macOS.swift`
  - `UI/macOS/MarkdownItemView.swift`

Key facts:

- iOS collection view cell routes by top-level node type:
  - `ImageNode` -> `AsyncImageView`
  - `CodeBlockNode`/`DiagramNode` -> `AsyncCodeView`
  - others -> `AsyncTextView`
- `AsyncTextView` draws text to bitmap off-main and assigns `layer.contents`.
- `AsyncCodeView` wraps `AsyncTextView`, adds copy button and padded background.
- macOS uses `NSTextView`-based item rendering with interactive summary/checkbox hit tests.

Accessibility:

- Centralized through `PlatformAccessibility`.
- iOS assigns traits/labels/values at cell level.
- macOS sets role/value per `NSTextView`.

### 4.6 Diagram and Math Rendering Backends

### Diagram adapters

- `DiagramAdapterRegistry` provides language -> adapter mapping.
- Without adapter, diagram falls back to code-style rendering.
- Included adapter:
  - `MermaidDiagramAdapter` renders by loading Mermaid JS in `WKWebView` and snapshotting.
- Demo app uses `DemoDiagramAdapters` with summary-card adapters for all four languages (safe fallback UX).

### Math backend

- `MathRenderer`:
  - TeX -> SVG via `MathJaxSwift`
  - SVG -> image via hidden `WKWebView` snapshot
- Handles queueing and single render pipeline to avoid overlapping webview operations.

### 4.7 Security and Robustness

Implemented controls:

- URL scheme allow-list sanitation (`URLSanitizer`).
- Defensive filtering against dangerous prefixes (`javascript:`, `vbscript:`, `data:text/html` variants).
- Parser recursion depth limit (`MarkdownKitVisitor.maxDepth`).
- Fuzz coverage exists (`FuzzTests`) for malformed/random payload resilience.

## 5. Automated Test Strategy in Code (Current State)

### 5.1 High-value suites

- `SyntaxMatrixTests`: syntax families x width matrix x plugin chain x semantic assertions.
- `CommonMarkSpecTests`: parses 652 examples for crash resilience.
- `LayoutSolverExtendedTests`, `InlineFormattingLayoutTests`, `CrossPlatformLayoutTests`, `iOSTableLayoutTests`: layout semantics and platform details.
- `DetailsExtractionPluginTests`, `DiagramExtractionPluginTests`, `MathExtractionPluginTests`, `GitHubAutolinkPluginTests`: plugin correctness.
- `URLSanitizerTests`, `DepthLimitTests`, `FuzzTests`: safety/hardening.
- `SnapshotTests` and `iOSSnapshotTests`: visual regression coverage.
- Benchmark suites:
  - `MarkdownKitBenchmarkTests`
  - `BenchmarkNodeTypeTests`
  - `BenchmarkCacheTests`
  - `BenchmarkRegressionGuard`

### 5.2 Automation reality check

The codebase already contains a robust automation backbone for “check all supported syntax + multiple cases”:

- syntax matrix fixtures and invariants (`SyntaxMatrixTests`)
- deterministic local-image fixtures for network-free runs
- plugin composition coverage
- width stress
- benchmark regression thresholds

Manual page-by-page demo verification should now be secondary, not primary.

## 6. Known Gaps / Risks / Technical Debt

1. `Sources/MarkdownKit/MarkdownKit.swift` is still placeholder text and not a curated public API surface.
2. `SplashHighlighter.highlight(_:language:)` ignores `language` argument and always uses Splash default lexer behavior.
3. Inline code has style-only rendering; no token-level inline highlighting.
4. Mermaid adapter depends on remote CDN JS in `WKWebView`; sandbox/network restrictions can break rendering or crash `WebContent`.
5. Remote image rendering can fail in restricted environments; fallback is `[alt]` text.
6. iOS table path is text/tab based and not true native table blocks; visual parity with macOS path is inherently limited.
7. `LayoutCache.CacheKey` hashes full width but equality uses `< 0.1` tolerance; hash/equality semantics are not fully aligned and can reduce predictable hit behavior around near-equal widths.
8. `CommonMarkSpecTests` currently validate parse resilience only, not Markdown-to-HTML semantic equivalence.
9. Some docs in `docs/` are stale relative to current implementation and test counts.

## 7. Extension Points (Where to Add New Features)

1. New syntax transform: add `ASTPlugin` and include in parser pipeline.
2. New diagram type: extend `DiagramLanguage`, add adapter, add tests in diagram layout/plugin suites.
3. New style system behavior: add token fields in `Theme` + consume in `LayoutSolver`.
4. Host integrations:
   - autolink resolution via `MarkdownContextDelegate`
   - details/checkbox callbacks in collection views
5. Performance gate updates:
   - refresh `docs/BENCHMARK_BASELINE.md`
   - update `BenchmarkRegressionGuard` thresholds

## 8. Practical Guidance for Future Reviews

If the goal is “validate everything fast and reliably”, this sequence is recommended:

1. `swift test --filter SyntaxMatrixTests`
2. `swift test --filter "DetailsExtractionPluginTests|DiagramExtractionPluginTests|MathExtractionPluginTests|GitHubAutolinkPluginTests"`
3. `swift test --filter "LayoutSolverExtendedTests|InlineFormattingLayoutTests|CrossPlatformLayoutTests"`
4. `swift test --filter "URLSanitizerTests|DepthLimitTests|FuzzTests"`
5. `swift test --filter MarkdownKitBenchmarkTests/testBenchmarkFullReport`

This gives broad semantic, rendering, safety, and performance coverage without requiring manual demo traversal.
