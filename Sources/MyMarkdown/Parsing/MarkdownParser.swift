import Foundation
import Markdown

/// The main entry point for parsing raw Markdown strings into our high-performance
/// AST, executing any injected middleware plugins along the way.
public struct MarkdownParser {
    
    /// The plugins that will be executed sequentially on the tree after the initial parse.
    public var plugins: [ASTPlugin]
    
    public init(plugins: [ASTPlugin] = []) {
        self.plugins = plugins
    }
    
    /// Parses a raw Markdown string into the `MyMarkdown` AST representation.
    ///
    /// - Parameter text: The raw markdown content.
    /// - Returns: The root `DocumentNode` containing the structured tree.
    public func parse(_ text: String) -> DocumentNode {
        // Step 1: Parse using Apple's highly-optimized C-backend.
        let document = Document(parsing: text)
        
        // Step 2: Convert to our thread-safe Native AST.
        var visitor = MyMarkdownVisitor()
        var rawNodes = visitor.defaultVisit(document)
        
        // Step 3: Run middleware plugins to modify the tree (e.g. inject MathNodes).
        for plugin in plugins {
            rawNodes = plugin.visit(rawNodes)
        }
        
        // Step 4: Return wrapped Document
        return DocumentNode(range: document.range, children: rawNodes)
    }
}
