import Foundation
import Markdown

/// A visitor that traverses the `swift-markdown` syntax tree and converts Apple's C-backed
/// syntax structures into our highly stabilized, thread-safe, and asynchronous-ready `MarkdownNode` models.
public struct MyMarkdownVisitor: MarkupVisitor {
    public typealias Result = [MarkdownNode]
    
    public init() {}
    
    // MARK: - Core Entry Point
    
    public mutating func defaultVisit(_ markup: Markup) -> [MarkdownNode] {
        var children: [MarkdownNode] = []
        for child in markup.children {
            children.append(contentsOf: visit(child))
        }
        return children
    }
    
    public mutating func visitDocument(_ document: Document) -> [MarkdownNode] {
        let children = defaultVisit(document)
        let node = DocumentNode(range: document.range, children: children)
        return [node]
    }
    
    // MARK: - Basic Nodes
    
    public mutating func visitHeading(_ heading: Heading) -> [MarkdownNode] {
        let children = defaultVisit(heading)
        let node = HeaderNode(range: heading.range, level: heading.level, children: children)
        return [node]
    }
    
    public mutating func visitParagraph(_ paragraph: Paragraph) -> [MarkdownNode] {
        let children = defaultVisit(paragraph)
        let node = ParagraphNode(range: paragraph.range, children: children)
        return [node]
    }
    
    public mutating func visitText(_ text: Text) -> [MarkdownNode] {
        let node = TextNode(range: text.range, text: text.string)
        return [node]
    }
    
    // MARK: - Complex Nodes
    
    public mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> [MarkdownNode] {
        let node = CodeBlockNode(range: codeBlock.range,
                                 language: codeBlock.language,
                                 code: codeBlock.code)
        return [node]
    }
    
    public mutating func visitInlineCode(_ inlineCode: InlineCode) -> [MarkdownNode] {
        let node = InlineCodeNode(range: inlineCode.range, code: inlineCode.code)
        return [node]
    }
    
    public mutating func visitImage(_ image: Image) -> [MarkdownNode] {
        let node = ImageNode(range: image.range,
                             source: image.source,
                             altText: image.plainText,
                             title: image.title)
        return [node]
    }
    
    public mutating func visitLink(_ link: Link) -> [MarkdownNode] {
        let children = defaultVisit(link)
        let node = LinkNode(range: link.range,
                            destination: link.destination,
                            title: link.title,
                            children: children)
        return [node]
    }
    
    // MARK: - Math (Extensions)
    
    /// swift-markdown does not support native `Math` elements by default in standard CommonMark.
    /// To support ChatGPT parity (`$$` and `$`), our Custom AST Middleware will usually attach these later by finding specific `TextNode` string patterns.
    /// However, if an extension is added to `swift-markdown` or inline HTML block evaluates to math, we intercept it here.
    public mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> [MarkdownNode] {
        // Simple fallback to convert raw HTML into a Text Node for now.
        // In a complete implementation, this would look for `<math>` tags or `$$` markers.
        let node = TextNode(range: inlineHTML.range, text: inlineHTML.rawHTML)
        return [node]
    }
}
