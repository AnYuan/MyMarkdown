import XCTest
@testable import MyMarkdown

/// A test plugin that replaces all TextNode contents with "REDACTED".
private struct RedactPlugin: ASTPlugin {
    func visit(_ nodes: [MarkdownNode]) -> [MarkdownNode] {
        return nodes.map { node in
            if let text = node as? TextNode {
                return TextNode(range: text.range, text: "REDACTED")
            }
            if let header = node as? HeaderNode {
                let newChildren = visit(header.children)
                return HeaderNode(range: header.range, level: header.level, children: newChildren)
            }
            if let para = node as? ParagraphNode {
                let newChildren = visit(para.children)
                return ParagraphNode(range: para.range, children: newChildren)
            }
            return node
        }
    }
}

final class ASTPluginTests: XCTestCase {

    func testParserWithNoPlugins() throws {
        let parser = MarkdownParser(plugins: [])
        let doc = parser.parse("Hello")
        let para = doc.children[0] as? ParagraphNode
        let text = para?.children[0] as? TextNode
        XCTAssertEqual(text?.text, "Hello")
    }

    func testSinglePluginTransformsAST() throws {
        let doc = TestHelper.parse("# Secret Title", plugins: [RedactPlugin()])
        let header = doc.children[0] as? HeaderNode
        let text = header?.children[0] as? TextNode
        XCTAssertEqual(text?.text, "REDACTED")
    }

    func testMultiplePluginsChainedInOrder() throws {
        let doc = TestHelper.parse("Hello World", plugins: [RedactPlugin(), RedactPlugin()])
        let para = doc.children[0] as? ParagraphNode
        let text = para?.children[0] as? TextNode
        XCTAssertEqual(text?.text, "REDACTED")
    }

    func testPluginReceivesTopLevelNodes() throws {
        var receivedNodeTypes: [String] = []

        struct InspectorPlugin: ASTPlugin {
            let onVisit: ([MarkdownNode]) -> Void
            func visit(_ nodes: [MarkdownNode]) -> [MarkdownNode] {
                onVisit(nodes)
                return nodes
            }
        }

        let plugin = InspectorPlugin { nodes in
            receivedNodeTypes = nodes.map { String(describing: type(of: $0)) }
        }

        _ = TestHelper.parse("# Title\nParagraph text", plugins: [plugin])
        XCTAssertTrue(receivedNodeTypes.contains("HeaderNode"))
        XCTAssertTrue(receivedNodeTypes.contains("ParagraphNode"))
    }

    func testPluginCanInjectMathNode() throws {
        struct MathInjectorPlugin: ASTPlugin {
            func visit(_ nodes: [MarkdownNode]) -> [MarkdownNode] {
                var result: [MarkdownNode] = []
                for node in nodes {
                    if node is ParagraphNode {
                        result.append(MathNode(range: nil, style: .inline, equation: "E=mc^2"))
                    } else {
                        result.append(node)
                    }
                }
                return result
            }
        }

        let doc = TestHelper.parse("Some text", plugins: [MathInjectorPlugin()])
        let math = doc.children[0] as? MathNode
        XCTAssertNotNil(math)
        XCTAssertEqual(math?.equation, "E=mc^2")
        XCTAssertEqual(math?.style, .inline)
    }
}
