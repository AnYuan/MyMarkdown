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
}
