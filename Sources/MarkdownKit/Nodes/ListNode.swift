//
//  ListNode.swift
//  MarkdownKit
//

import Foundation
import Markdown

public struct ListNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let isOrdered: Bool
    public let children: [MarkdownNode]
    
    public init(range: SourceRange?, isOrdered: Bool, children: [MarkdownNode]) {
        self.range = range
        self.isOrdered = isOrdered
        self.children = children
    }
}
