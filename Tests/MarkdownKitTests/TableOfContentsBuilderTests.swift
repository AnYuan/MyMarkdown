import XCTest
@testable import MarkdownKit

final class TableOfContentsBuilderTests: XCTestCase {
    
    private let parser = MarkdownParser()

    func testEmptyDocumentProducesNoEntries() {
        let doc = parser.parse("")
        let toc = TableOfContentsBuilder.build(from: doc)
        XCTAssertTrue(toc.isEmpty)
    }

    func testSingleHeadingExtraction() {
        let doc = parser.parse("# Hello World")
        let toc = TableOfContentsBuilder.build(from: doc)
        
        XCTAssertEqual(toc.count, 1)
        XCTAssertEqual(toc[0].level, 1)
        XCTAssertEqual(toc[0].text, "Hello World")
    }

    func testNestedHeadingsAndLevels() {
        let markdown = """
        # Title
        Some text here
        ## Subtitle 1
        ### Sub-subtitle
        ## Subtitle 2
        """
        let doc = parser.parse(markdown)
        let toc = TableOfContentsBuilder.build(from: doc)
        
        XCTAssertEqual(toc.count, 4)
        
        XCTAssertEqual(toc[0].level, 1)
        XCTAssertEqual(toc[0].text, "Title")
        
        XCTAssertEqual(toc[1].level, 2)
        XCTAssertEqual(toc[1].text, "Subtitle 1")
        
        XCTAssertEqual(toc[2].level, 3)
        XCTAssertEqual(toc[2].text, "Sub-subtitle")
        
        XCTAssertEqual(toc[3].level, 2)
        XCTAssertEqual(toc[3].text, "Subtitle 2")
    }

    func testHeadingWithInlineStylesIsFlattened() {
        let doc = parser.parse("## Testing **Bold** and *Italic* and `Code`")
        let toc = TableOfContentsBuilder.build(from: doc)
        
        XCTAssertEqual(toc.count, 1)
        XCTAssertEqual(toc[0].level, 2)
        // Ensure bold, italic, and code markdown formatting is stripped to plain text
        XCTAssertEqual(toc[0].text, "Testing Bold and Italic and Code")
    }
}
