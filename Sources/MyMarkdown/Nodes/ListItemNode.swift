//
//  ListItemNode.swift
//  MyMarkdown
//

import Foundation
import Markdown

public enum CheckboxState {
    case checked, unchecked, none
}

public struct ListItemNode: BlockNode {
    public let id = UUID()
    public let range: SourceRange?
    public let checkbox: CheckboxState
    public let children: [MarkdownNode]
    
    public init(range: SourceRange?, checkbox: CheckboxState = .none, children: [MarkdownNode]) {
        self.range = range
        self.checkbox = checkbox
        self.children = children
    }
}
