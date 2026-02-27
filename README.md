# MyMarkdown

MyMarkdown is a high-performance native Markdown renderer for Apple platforms, built in Swift with `swift-markdown` and TextKit-based layout.

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
swift run MyMarkdownDemo
```

## Basic Usage

```swift
import MyMarkdown

let parser = MarkdownParser(
    plugins: [
        DetailsExtractionPlugin(),
        DiagramExtractionPlugin(),
        MathExtractionPlugin()
    ]
)

let document = parser.parse("# Hello MyMarkdown")
let solver = LayoutSolver()
let layout = await solver.solve(node: document, constrainedToWidth: 800)
print(layout.children.count)
```

## Project Structure

- `Sources/MyMarkdown`: core parser, AST nodes, plugins, layout engine, UI components
- `Sources/MyMarkdownDemo`: demo app
- `Tests/MyMarkdownTests`: unit/integration tests
- `docs/`: PRD, feature notes, roadmap
- `tasks/`: implementation checklist
