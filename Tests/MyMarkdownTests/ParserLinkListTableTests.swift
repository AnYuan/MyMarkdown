import XCTest
@testable import MyMarkdown

final class ParserLinkListTableTests: XCTestCase {

    // MARK: - Link Parsing

    func testLinkWithDestination() throws {
        let doc = TestHelper.parse("[Click here](https://example.com)")
        let para: ParagraphNode? = TestHelper.assertChild(doc, at: 0, is: ParagraphNode.self)
        let link: LinkNode? = TestHelper.assertChild(para!, at: 0, is: LinkNode.self)
        XCTAssertEqual(link?.destination, "https://example.com")
        // Link text child
        let linkText: TextNode? = TestHelper.assertChild(link!, at: 0, is: TextNode.self)
        XCTAssertEqual(linkText?.text, "Click here")
    }

    func testLinkWithoutTitle() throws {
        let doc = TestHelper.parse("[Go](https://go.dev)")
        let para: ParagraphNode? = TestHelper.assertChild(doc, at: 0, is: ParagraphNode.self)
        let link: LinkNode? = TestHelper.assertChild(para!, at: 0, is: LinkNode.self)
        XCTAssertEqual(link?.destination, "https://go.dev")
    }

    // MARK: - InlineCode Parsing

    func testInlineCodeParsing() throws {
        let doc = TestHelper.parse("Use `let x = 1` in Swift")
        let para: ParagraphNode? = TestHelper.assertChild(doc, at: 0, is: ParagraphNode.self)
        XCTAssertNotNil(para)
        var foundInlineCode = false
        for child in para!.children {
            if let inlineCode = child as? InlineCodeNode {
                XCTAssertEqual(inlineCode.code, "let x = 1")
                XCTAssertTrue(inlineCode.children.isEmpty)
                foundInlineCode = true
            }
        }
        XCTAssertTrue(foundInlineCode, "Expected InlineCodeNode in paragraph children")
    }

    // MARK: - Unordered List Parsing

    func testUnorderedListParsing() throws {
        let markdown = """
        - Item A
        - Item B
        - Item C
        """
        let doc = TestHelper.parse(markdown)
        let list: ListNode? = TestHelper.assertChild(doc, at: 0, is: ListNode.self)
        XCTAssertNotNil(list)
        XCTAssertFalse(list!.isOrdered)
        XCTAssertEqual(list!.children.count, 3)

        for (index, child) in list!.children.enumerated() {
            let item = child as? ListItemNode
            XCTAssertNotNil(item, "child[\(index)] should be ListItemNode")
            XCTAssertEqual(item?.checkbox, CheckboxState.none)
        }
    }

    // MARK: - Ordered List Parsing

    func testOrderedListParsing() throws {
        let markdown = """
        1. First
        2. Second
        """
        let doc = TestHelper.parse(markdown)
        let list: ListNode? = TestHelper.assertChild(doc, at: 0, is: ListNode.self)
        XCTAssertNotNil(list)
        XCTAssertTrue(list!.isOrdered)
        XCTAssertEqual(list!.children.count, 2)
    }

    // MARK: - Checkbox / Task List Parsing

    func testCheckboxTaskListParsing() throws {
        let markdown = """
        - [x] Done task
        - [ ] Pending task
        - Regular item
        """
        let doc = TestHelper.parse(markdown)
        let list: ListNode? = TestHelper.assertChild(doc, at: 0, is: ListNode.self)
        XCTAssertEqual(list?.children.count, 3)

        let checked = list?.children[0] as? ListItemNode
        XCTAssertEqual(checked?.checkbox, .checked)

        let unchecked = list?.children[1] as? ListItemNode
        XCTAssertEqual(unchecked?.checkbox, .unchecked)

        let regular = list?.children[2] as? ListItemNode
        XCTAssertEqual(regular?.checkbox, CheckboxState.none)
    }

    // MARK: - Table Parsing (GFM)

    func testBasicTableParsing() throws {
        let markdown = """
        | Name | Age |
        |------|-----|
        | Alice | 30 |
        | Bob | 25 |
        """
        let doc = TestHelper.parse(markdown)
        let table: TableNode? = TestHelper.assertChild(doc, at: 0, is: TableNode.self)
        XCTAssertNotNil(table)

        XCTAssertEqual(table!.columnAlignments.count, 2)

        // Table children: TableHeadNode, TableBodyNode
        XCTAssertEqual(table!.children.count, 2)
        let head = table!.children[0] as? TableHeadNode
        XCTAssertNotNil(head)
        let body = table!.children[1] as? TableBodyNode
        XCTAssertNotNil(body)

        // Head should contain cells (may be rows or direct cells depending on parser)
        XCTAssertGreaterThan(head!.children.count, 0)

        // Body has 2 rows
        XCTAssertEqual(body?.children.count, 2)
    }

    func testTableWithColumnAlignments() throws {
        let markdown = """
        | Left | Center | Right |
        |:-----|:------:|------:|
        | a    | b      | c     |
        """
        let doc = TestHelper.parse(markdown)
        let table: TableNode? = TestHelper.assertChild(doc, at: 0, is: TableNode.self)
        XCTAssertNotNil(table)

        XCTAssertEqual(table!.columnAlignments.count, 3)
        XCTAssertEqual(table!.columnAlignments[0], .left)
        XCTAssertEqual(table!.columnAlignments[1], .center)
        XCTAssertEqual(table!.columnAlignments[2], .right)
    }

    func testTableCellTextContent() throws {
        let markdown = """
        | Key | Value |
        |-----|-------|
        | foo | bar   |
        """
        let doc = TestHelper.parse(markdown)
        guard let table = doc.children[0] as? TableNode else {
            XCTFail("Expected TableNode"); return
        }
        guard let body = table.children[1] as? TableBodyNode else {
            XCTFail("Expected TableBodyNode"); return
        }
        guard let row = body.children[0] as? TableRowNode else {
            XCTFail("Expected TableRowNode"); return
        }
        guard let cell = row.children[0] as? TableCellNode else {
            XCTFail("Expected TableCellNode"); return
        }
        let text = cell.children[0] as? TextNode
        XCTAssertEqual(text?.text, "foo")
    }

    // MARK: - InlineHTML Visitor

    func testInlineHTMLFallsBackToTextNode() throws {
        let doc = TestHelper.parse("Hello <br> there")
        let para: ParagraphNode? = TestHelper.assertChild(doc, at: 0, is: ParagraphNode.self)
        XCTAssertNotNil(para)
        XCTAssertGreaterThan(para!.children.count, 0)
        // Should contain TextNode children (inline HTML converted to text)
        var foundHTML = false
        for child in para!.children {
            if let textNode = child as? TextNode, textNode.text.contains("<br>") {
                foundHTML = true
            }
        }
        XCTAssertTrue(foundHTML, "Expected inline HTML to be converted to TextNode")
    }

    func testHTMLBlockFallsBackToTextNode() throws {
        let markdown = """
        <details>
        </details>
        """
        let doc = TestHelper.parse(markdown)
        let textNodes = doc.children.compactMap { $0 as? TextNode }
        XCTAssertFalse(textNodes.isEmpty)

        let joined = textNodes.map(\.text).joined(separator: "\n")
        XCTAssertTrue(joined.contains("<details>"))
        XCTAssertTrue(joined.contains("</details>"))
    }
}
