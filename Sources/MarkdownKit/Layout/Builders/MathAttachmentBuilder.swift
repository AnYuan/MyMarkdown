import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A dedicated builder for rendering `MathNode` attachments into `NSAttributedString`.
/// This encapsulates MathJax SVG generation and accurately calculcates inline typographic offset bounds.
enum MathAttachmentBuilder {
    
    /// Asynchronously builds an attributed string by awaiting MathRenderer evaluation.
    /// - Parameters:
    ///   - node: The target math node.
    ///   - theme: The active theme providing font and fallback styling bounds.
    /// - Returns: An `NSAttributedString` wrapping an `NSTextAttachment` containing the rasterized SVG.
    static func build(
        from node: MathNode,
        theme: Theme,
        contextFont: Font? = nil
    ) async -> NSAttributedString {
        let effectiveFont = contextFont ?? theme.typography.paragraph.font
        #if canImport(WebKit)
        if let image = await renderMath(latex: node.equation, display: !node.isInline) {
            let attachment = NSTextAttachment()
            attachment.image = image

            // Align inline math vertically with surrounding text metrics.
            attachment.bounds = attachmentBounds(
                for: image.size,
                isInline: node.isInline,
                font: effectiveFont
            )
            return NSAttributedString(attachment: attachment)
        }
        #endif

        // Fallback to raw text if conversion/rasterization fails.
        return fallbackString(for: node, theme: theme)
    }

    /// Synchronously builds an attributed string using pre-cached images.
    /// Used by strictly synchronous layout flows.
    static func buildSync(
        from node: MathNode,
        theme: Theme,
        contextFont: Font? = nil
    ) -> NSAttributedString {
        let effectiveFont = contextFont ?? theme.typography.paragraph.font
        #if canImport(WebKit)
        if let image = MathRenderer.cachedImage(for: node.equation) {
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.bounds = attachmentBounds(
                for: image.size,
                isInline: node.isInline,
                font: effectiveFont
            )
            return NSAttributedString(attachment: attachment)
        }
        #endif

        return fallbackString(for: node, theme: theme)
    }
    
    // MARK: - Internal Helpers
    
    #if canImport(WebKit)
    private static func renderMath(latex: String, display: Bool) async -> NativeImage? {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                MathRenderer.shared.render(latex: latex, display: display) { image in
                    continuation.resume(returning: image)
                }
            }
        }
    }
    #endif
    
    private static func attachmentBounds(for imageSize: CGSize, isInline: Bool, font: Font) -> CGRect {
        guard isInline else {
            return CGRect(origin: .zero, size: imageSize)
        }
        
        // Center the inline attachment against the font's typographic midline.
        let textMidline = (font.ascender + font.descender) / 2.0
        let imageMidline = imageSize.height / 2.0
        let offsetY = textMidline - imageMidline
        
        return CGRect(x: 0, y: offsetY, width: imageSize.width, height: imageSize.height)
    }
    
    private static func fallbackString(for node: MathNode, theme: Theme) -> NSAttributedString {
        let token = theme.typography.codeBlock
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = token.lineHeightMultiple
        style.paragraphSpacing = token.paragraphSpacing
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: token.font,
            .paragraphStyle: style,
            .foregroundColor: theme.colors.textColor.foreground
        ]
        
        return NSAttributedString(string: node.equation, attributes: attrs)
    }
}
