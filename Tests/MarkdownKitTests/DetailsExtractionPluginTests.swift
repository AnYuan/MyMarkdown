import XCTest
@testable import MarkdownKit

final class DetailsExtractionPluginTests: XCTestCase {

    func testDetailsBlockWithInlineSummaryConvertsToDedicatedNode() throws {
        let markdown = """
        <details>
        <summary>Project status</summary>

        Content paragraph.
        </details>
        """

        let doc = TestHelper.parse(markdown, plugins: [DetailsExtractionPlugin()])
        guard let details = doc.children.first as? DetailsNode else {
            XCTFail("Expected top-level DetailsNode")
            return
        }

        XCTAssertFalse(details.isOpen)
        XCTAssertEqual(extractedText(from: details.summary), "Project status")
        XCTAssertTrue(extractedText(from: details).contains("Content paragraph."))
    }

    func testDetailsOpenAttributeSetsExpandedState() throws {
        let markdown = """
        <details open>
        <summary>Expanded</summary>

        Body text.
        </details>
        """

        let doc = TestHelper.parse(markdown, plugins: [DetailsExtractionPlugin()])
        let details = doc.children.first as? DetailsNode
        XCTAssertNotNil(details)
        XCTAssertEqual(details?.isOpen, true)
    }

    func testNestedDetailsAreParsedRecursively() throws {
        let markdown = """
        <details>
        <summary>Outer</summary>

        <details>
        <summary>Inner</summary>

        Nested body.
        </details>
        </details>
        """

        let doc = TestHelper.parse(markdown, plugins: [DetailsExtractionPlugin()])
        guard let outer = doc.children.first as? DetailsNode else {
            XCTFail("Expected outer DetailsNode")
            return
        }

        XCTAssertEqual(extractedText(from: outer.summary), "Outer")
        let nestedDetails = outer.children.compactMap { $0 as? DetailsNode }
        XCTAssertEqual(nestedDetails.count, 1)
        XCTAssertEqual(extractedText(from: nestedDetails.first?.summary), "Inner")
        XCTAssertTrue(extractedText(from: nestedDetails.first).contains("Nested body."))
    }

    func testMalformedDetailsWithoutClosingTagFallsBackToOriginalNodes() throws {
        let markdown = """
        <details>
        <summary>Unclosed</summary>

        Body without closing tag.
        """

        let doc = TestHelper.parse(markdown, plugins: [DetailsExtractionPlugin()])
        let hasDetailsNode = doc.children.contains { $0 is DetailsNode }
        XCTAssertFalse(hasDetailsNode, "Unclosed details block should not be rewritten")
    }
}

private func extractedText(from node: MarkdownNode?) -> String {
    guard let node else { return "" }

    switch node {
    case let text as TextNode:
        return text.text
    default:
        return node.children.map { extractedText(from: $0) }.joined(separator: " ")
    }
}
