//
//  TableNode.swift
//  MarkdownKit
//

import Foundation
import Markdown

public enum TableAlignment {
    case left, right, center
}

public struct TableNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let children: [MarkdownNode]
    public let columnAlignments: [TableAlignment?]
    
    public init(range: SourceRange?, columnAlignments: [TableAlignment?], children: [MarkdownNode]) {
        self.range = range
        self.columnAlignments = columnAlignments
        self.children = children
    }
}

public struct TableHeadNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let children: [MarkdownNode]
    
    public init(range: SourceRange?, children: [MarkdownNode]) {
        self.range = range
        self.children = children
    }
}

public struct TableBodyNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let children: [MarkdownNode]
    
    public init(range: SourceRange?, children: [MarkdownNode]) {
        self.range = range
        self.children = children
    }
}

public struct TableRowNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let children: [MarkdownNode]
    
    public init(range: SourceRange?, children: [MarkdownNode]) {
        self.range = range
        self.children = children
    }
}

public struct TableCellNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let children: [MarkdownNode]
    
    public init(range: SourceRange?, children: [MarkdownNode]) {
        self.range = range
        self.children = children
    }
}
