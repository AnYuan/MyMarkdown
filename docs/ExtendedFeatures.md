# ChatGPT Parity Extended Features

To reach full feature parity with ChatGPT's sophisticated rendering application, the `MyMarkdown` engine integrates several advanced modules beyond standard CommonMark layout.

## 1. Syntax Highlighting (Splash)
Instead of relying on heavy JavaScript-based libraries (like `highlight.js`) embedded inside web views, the engine natively parses code strings using [Splash](https://github.com/JohnSundell/Splash). 
- `SplashHighlighter` acts as a middleware mapping `Theme.codeColor` components to Splash's internal lexer format.
- Operations run entirely on a background thread during `LayoutSolver` routines.

## 2. LaTeX Math Rendering (MathJax SVG)
Native Swift doesn't inherently understand `$\frac{1}{2}$`.
- We use an invisible `WKWebView` on the background thread instance via `MathRenderer`.
- It executes `MathJax` logic to convert the LaTeX AST fragment into an SVG image.
- We snapshot the `CGImage` of this SVG natively and wrap it inside an asynchronous `NSTextAttachment` inserted directly into the TextKit 2 layout pipeline.

## 3. GitHub Flavored Markdown (GFM) Tables
Rendering tables inside virtualized CollectionViews is notoriously complex. Building CollectionView grids inside CollectionView cells breaks virtual scrolling performance.
- We solve this natively by utilizing `NSTextTab` APIs built directly into `NSMutableParagraphStyle`.
- When `LayoutSolver` encounters a `TableNode`, it computes the uniform column width and establishes exact text tab alignment locations. 
- The entire AST Table is structurally flattened and visually presented as a single dynamic paragraph of meticulously aligned strings.

## 4. Native Actions (Copy/Paste)
The `AsyncCodeView` component introduces OS-level actions overlaying the asynchronous rendering layer. A native `UIButton` (iOS) or `NSButton` (macOS) sits atop the background canvas, injecting the raw AST `.code` string directly into the system pasteboard (`UIPasteboard`) upon tap, complete with animation state polling.

## 5. Dynamic Theme Transitions
When OS-level appearances change (e.g. User transitions from Light to Dark mode), evaluating dynamic colors captured within the `NSAttributedString` object cache must be violently purged.
`MarkdownCollectionViewThemeDelegate` safely delegates `traitCollectionDidChange` signals for instantaneous foreground invalidation and background re-computation without leaking memory.
