import Markdown

struct BlockQuoteMapper: ASTNodeMapper {
    func map(_ node: BlockQuote, visitor: inout MarkdownKitVisitor) -> [MarkdownNode] {
        let children = visitor.defaultVisit(node)
        return [BlockQuoteNode(range: node.range, children: children)]
    }
}

struct CodeBlockMapper: ASTNodeMapper {
    func map(_ node: CodeBlock, visitor: inout MarkdownKitVisitor) -> [MarkdownNode] {
        return [CodeBlockNode(range: node.range,
                              language: node.language,
                              code: node.code)]
    }
}

struct HTMLBlockMapper: ASTNodeMapper {
    func map(_ node: HTMLBlock, visitor: inout MarkdownKitVisitor) -> [MarkdownNode] {
        return [TextNode(range: node.range, text: node.rawHTML)]
    }
}
