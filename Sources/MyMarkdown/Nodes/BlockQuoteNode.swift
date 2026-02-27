import Foundation
import Markdown

/// A block node representing a blockquote (> prefix).
public struct BlockQuoteNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let children: [MarkdownNode]

    public init(range: SourceRange?, children: [MarkdownNode]) {
        self.range = range
        self.children = children
    }
}
