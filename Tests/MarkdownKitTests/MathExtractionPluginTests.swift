import XCTest
@testable import MarkdownKit

final class MathExtractionPluginTests: XCTestCase {

    func testFencedMathCodeBlockConvertsToBlockMathNode() throws {
        let markdown = """
        ```math
        \\frac{n(n+1)}{2}
        ```
        """

        let doc = TestHelper.parse(markdown, plugins: [MathExtractionPlugin()])
        guard let math = doc.children.first as? MathNode else {
            XCTFail("Expected fenced math block to be converted to MathNode")
            return
        }

        XCTAssertEqual(math.style, .block)
        XCTAssertEqual(math.equation, "\\frac{n(n+1)}{2}")
    }

    func testNonMathFencedCodeBlockRemainsCodeBlockNode() throws {
        let markdown = """
        ```swift
        let x = 1
        ```
        """

        let doc = TestHelper.parse(markdown, plugins: [MathExtractionPlugin()])
        XCTAssertTrue(doc.children.first is CodeBlockNode)
    }

    func testInlineMathParsesMultipleExpressionsInSingleParagraph() throws {
        let markdown = "Before $x$ middle $y^2$ after"
        let doc = TestHelper.parse(markdown, plugins: [MathExtractionPlugin()])

        guard let paragraph = doc.children.first as? ParagraphNode else {
            XCTFail("Expected ParagraphNode")
            return
        }

        XCTAssertEqual(paragraph.children.count, 5)
        XCTAssertEqual((paragraph.children[0] as? TextNode)?.text, "Before ")
        XCTAssertEqual((paragraph.children[1] as? MathNode)?.equation, "x")
        XCTAssertEqual((paragraph.children[2] as? TextNode)?.text, " middle ")
        XCTAssertEqual((paragraph.children[3] as? MathNode)?.equation, "y^2")
        XCTAssertEqual((paragraph.children[4] as? TextNode)?.text, " after")
    }

    func testEscapedDollarDoesNotCreateUnexpectedInlineMath() throws {
        let markdown = #"Escaped \$notMath\$ and real $x$"#
        let doc = TestHelper.parse(markdown, plugins: [MathExtractionPlugin()])

        guard let paragraph = doc.children.first as? ParagraphNode else {
            XCTFail("Expected ParagraphNode")
            return
        }

        let mathNodes = paragraph.children.compactMap { $0 as? MathNode }
        XCTAssertEqual(mathNodes.count, 1)
        XCTAssertEqual(mathNodes.first?.equation, "x")
    }

    func testUnterminatedInlineMathFallsBackToText() throws {
        let markdown = "Price: $x + y"
        let doc = TestHelper.parse(markdown, plugins: [MathExtractionPlugin()])

        guard let paragraph = doc.children.first as? ParagraphNode else {
            XCTFail("Expected ParagraphNode")
            return
        }

        XCTAssertTrue(paragraph.children.allSatisfy { $0 is TextNode })
        let fullText = paragraph.children.compactMap { ($0 as? TextNode)?.text }.joined()
        XCTAssertEqual(fullText, "Price: $x + y")
    }

    func testBlockMathAcrossParagraphsConvertsToSingleMathNode() throws {
        let markdown = """
        $$

        \\frac{a}{b}

        $$
        """
        let doc = TestHelper.parse(markdown, plugins: [MathExtractionPlugin()])

        guard let math = doc.children.first as? MathNode else {
            XCTFail("Expected block math delimiters to merge into MathNode")
            return
        }

        XCTAssertEqual(math.style, .block)
        XCTAssertEqual(math.equation, "\\frac{a}{b}")
    }
}
