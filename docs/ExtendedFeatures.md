# ChatGPT Parity Extended Features

To reach full feature parity with ChatGPT's sophisticated rendering application, the `MyMarkdown` engine integrates several advanced modules beyond standard CommonMark layout.

## 1. Syntax Highlighting (Splash)
Instead of relying on heavy JavaScript-based libraries (like `highlight.js`) embedded inside web views, the engine natively parses code strings using [Splash](https://github.com/JohnSundell/Splash). 
- `SplashHighlighter` acts as a middleware mapping `Theme.codeColor` components to Splash's internal lexer format.
- Operations run entirely on a background thread during `LayoutSolver` routines.

## 2. LaTeX Math Rendering (MathJax SVG)
Native Swift doesn't inherently understand `$\frac{1}{2}$`.
- We use `MathJaxSwift` (JavaScriptCore) via `MathRenderer` to convert LaTeX into SVG without relying on a network CDN.
- A shared hidden `WKWebView` is used only for SVG rasterization to produce native image attachments.
- The rasterized result is wrapped into `NSTextAttachment` and inserted into the TextKit 2 layout pipeline.

## 3. GitHub Flavored Markdown (GFM) Tables
Rendering tables inside virtualized CollectionViews is notoriously complex. Building CollectionView grids inside CollectionView cells breaks virtual scrolling performance.
- We render tables as monospaced text blocks to keep layout deterministic and cheap for virtualization.
- When `LayoutSolver` encounters a `TableNode`, it computes per-column width and space-pads each cell to a fixed line width.
- The entire AST table is flattened into aligned text lines (header, separator, body) that measure efficiently in TextKit.

## 4. Native Actions (Copy/Paste)
The `AsyncCodeView` component introduces OS-level actions overlaying the asynchronous rendering layer. A native `UIButton` (iOS) or `NSButton` (macOS) sits atop the background canvas, injecting the raw AST `.code` string directly into the system pasteboard (`UIPasteboard`) upon tap, complete with animation state polling.

## 5. Dynamic Theme Transitions
When OS-level appearances change (e.g. User transitions from Light to Dark mode), evaluating dynamic colors captured within the `NSAttributedString` object cache must be violently purged.
`MarkdownCollectionViewThemeDelegate` safely delegates `traitCollectionDidChange` signals for instantaneous foreground invalidation and background re-computation without leaking memory.
