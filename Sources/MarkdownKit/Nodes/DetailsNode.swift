import Foundation
import Markdown

/// A block node representing an HTML `<details>` container.
public struct DetailsNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let isOpen: Bool
    public let summary: SummaryNode?
    public let children: [MarkdownNode]

    public init(
        range: SourceRange?,
        isOpen: Bool,
        summary: SummaryNode?,
        children: [MarkdownNode]
    ) {
        self.range = range
        self.isOpen = isOpen
        self.summary = summary
        self.children = children
    }
}

/// A block node representing an HTML `<summary>` row.
public struct SummaryNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let children: [MarkdownNode]

    public init(range: SourceRange?, children: [MarkdownNode]) {
        self.range = range
        self.children = children
    }
}
