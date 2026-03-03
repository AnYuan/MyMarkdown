import Markdown

/// Defines a mapping strategy from a `swift-markdown` `Markup` node to an array of `MarkdownKit` nodes.
protocol ASTNodeMapper {
    associatedtype MarkupNode: Markup
    
    /// Translates a `swift-markdown` AST node to `MarkdownKit` AST elements.
    /// - Parameters:
    ///   - node: The swift-markdown node to parse.
    ///   - visitor: The current recursive traversal visitor, used to parse children nodes.
    /// - Returns: An array of resulting `MarkdownNode`s.
    func map(_ node: MarkupNode, visitor: inout MarkdownKitVisitor) -> [MarkdownNode]
}
