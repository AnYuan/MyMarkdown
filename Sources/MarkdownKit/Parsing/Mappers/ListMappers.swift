import Markdown

struct OrderedListMapper: ASTNodeMapper {
    func map(_ node: OrderedList, visitor: inout MarkdownKitVisitor) -> [MarkdownNode] {
        let children = visitor.defaultVisit(node)
        return [ListNode(range: node.range, isOrdered: true, children: children)]
    }
}

struct UnorderedListMapper: ASTNodeMapper {
    func map(_ node: UnorderedList, visitor: inout MarkdownKitVisitor) -> [MarkdownNode] {
        let children = visitor.defaultVisit(node)
        return [ListNode(range: node.range, isOrdered: false, children: children)]
    }
}

struct ListItemMapper: ASTNodeMapper {
    func map(_ node: ListItem, visitor: inout MarkdownKitVisitor) -> [MarkdownNode] {
        let children = visitor.defaultVisit(node)
        let checkboxState: CheckboxState
        switch node.checkbox {
        case .checked: checkboxState = .checked
        case .unchecked: checkboxState = .unchecked
        case .none: checkboxState = .none
        }
        return [ListItemNode(range: node.range, checkbox: checkboxState, children: children)]
    }
}
