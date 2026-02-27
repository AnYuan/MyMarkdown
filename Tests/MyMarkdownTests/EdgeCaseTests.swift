import XCTest
@testable import MyMarkdown

final class EdgeCaseTests: XCTestCase {

    // MARK: - Empty / Whitespace Input

    func testParseEmptyString() throws {
        let doc = TestHelper.parse("")
        XCTAssertEqual(doc.children.count, 0)
    }

    func testParseWhitespaceOnly() throws {
        let doc = TestHelper.parse("   \n\n   ")
        XCTAssertEqual(doc.children.count, 0)
    }

    // MARK: - Deeply Nested Structures

    func testNestedListParsing() throws {
        let markdown = """
        - Level 1
          - Level 2
            - Level 3
        """
        let doc = TestHelper.parse(markdown)
        let outerList = doc.children[0] as? ListNode
        XCTAssertNotNil(outerList)
        XCTAssertGreaterThan(outerList!.children.count, 0)
    }

    // MARK: - Mixed Content

    func testMixedContentDocument() throws {
        let markdown = """
        # Title
        A paragraph with `inline code` and a [link](https://x.com).

        - Item 1
        - Item 2

        ```swift
        let x = 1
        ```

        | A | B |
        |---|---|
        | 1 | 2 |
        """
        let doc = TestHelper.parse(markdown)
        // Should have: Header, Paragraph, List, CodeBlock, Table
        XCTAssertGreaterThanOrEqual(doc.children.count, 5)

        XCTAssertTrue(doc.children[0] is HeaderNode)
        XCTAssertTrue(doc.children[1] is ParagraphNode)
        XCTAssertTrue(doc.children[2] is ListNode)
        XCTAssertTrue(doc.children[3] is CodeBlockNode)
        XCTAssertTrue(doc.children[4] is TableNode)
    }

    // MARK: - Header Levels

    func testAllSixHeaderLevels() throws {
        for level in 1...6 {
            let markdown = String(repeating: "#", count: level) + " H\(level)"
            let doc = TestHelper.parse(markdown)
            let header = doc.children[0] as? HeaderNode
            XCTAssertNotNil(header, "H\(level) should parse to HeaderNode")
            XCTAssertEqual(header?.level, level)
        }
    }

    // MARK: - Special Characters

    func testSpecialCharactersInText() throws {
        let doc = TestHelper.parse("Hello & \"friends\" 'there'")
        let para = doc.children[0] as? ParagraphNode
        XCTAssertNotNil(para)
        XCTAssertGreaterThan(para!.children.count, 0)
    }

    func testUnicodeContentParsing() throws {
        let doc = TestHelper.parse("# \u{1F600} Emoji Header\n\u{4F60}\u{597D}\u{4E16}\u{754C}")
        XCTAssertGreaterThanOrEqual(doc.children.count, 2)
    }

    // MARK: - Layout Edge Cases

    func testZeroWidthLayoutDoesNotCrash() async throws {
        let layout = await TestHelper.solveLayout("# Hello", width: 0)
        XCTAssertNotNil(layout)
    }

    func testVeryLargeWidthLayout() async throws {
        let layout = await TestHelper.solveLayout("Short text", width: 100_000)
        let childLayout = layout.children[0]
        XCTAssertGreaterThan(childLayout.size.width, 0)
    }

    func testVeryLongTextLayout() async throws {
        let longText = String(repeating: "word ", count: 10_000)
        let layout = await TestHelper.solveLayout(longText, width: 400)
        let childLayout = layout.children[0]
        XCTAssertGreaterThan(childLayout.size.height, 0)
        XCTAssertLessThanOrEqual(childLayout.size.width, 400)
    }

    // MARK: - Code Block Edge Cases

    func testCodeBlockWithNoLanguage() throws {
        let markdown = """
        ```
        plain code
        ```
        """
        let doc = TestHelper.parse(markdown)
        let code = doc.children[0] as? CodeBlockNode
        XCTAssertNotNil(code)
        XCTAssertNil(code?.language)
        XCTAssertTrue(code?.code.contains("plain code") ?? false)
    }

    func testEmptyCodeBlock() throws {
        let markdown = """
        ```swift
        ```
        """
        let doc = TestHelper.parse(markdown)
        let code = doc.children[0] as? CodeBlockNode
        XCTAssertNotNil(code)
        XCTAssertEqual(code?.language, "swift")
    }

    // MARK: - LayoutResult Direct Construction

    func testLayoutResultInitDefaults() {
        let node = TextNode(range: nil, text: "test")
        let result = LayoutResult(node: node, size: CGSize(width: 100, height: 50))
        XCTAssertNil(result.attributedString)
        XCTAssertTrue(result.children.isEmpty)
        XCTAssertEqual(result.size.width, 100)
        XCTAssertEqual(result.size.height, 50)
    }
}
