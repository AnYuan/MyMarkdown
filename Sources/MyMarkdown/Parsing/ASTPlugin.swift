import Foundation

/// A protocol defining a middleware plugin that can inspect or modify the AST
/// before it is sent to the Layout Engine.
///
/// This provides extreme extensibility. For instance, a plugin could search for
/// `TextNode` objects containing `$$` and replace them with `MathNode` objects,
/// or find specific syntax like `[ ]` to create Task List Checkboxes.
public protocol ASTPlugin {
    /// Mutates the given collection of `MarkdownNode` elements.
    ///
    /// - Parameter nodes: The current array of sibling nodes.
    /// - Returns: The modified array of nodes after the plugin has executed its transformations.
    func visit(_ nodes: [MarkdownNode]) -> [MarkdownNode]
}
