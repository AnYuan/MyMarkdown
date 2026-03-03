import XCTest
@testable import MarkdownKit

final class MarkdownKitTests: XCTestCase {
    
    func testBasicCommonMarkParsing() throws {
        let parser = MarkdownParser()
        let markdownString = """
        # Hello World
        This is a paragraph.
        """
        
        // Measure the pure AST parsing performance to adhere to Section 4 / 6 of PRD
        var docNode: DocumentNode!
        PerformanceProfiler.measure(.astParsing) {
            docNode = parser.parse(markdownString)
        }
        
        XCTAssertEqual(docNode.children.count, 2)
        
        // Test Header Node
        let header = docNode.children[0] as? HeaderNode
        XCTAssertNotNil(header)
        XCTAssertEqual(header?.level, 1)
        XCTAssertEqual(header?.children.count, 1)
        let headerText = header?.children[0] as? TextNode
        XCTAssertEqual(headerText?.text, "Hello World")
        
        // Test Paragraph Node
        let paragraph = docNode.children[1] as? ParagraphNode
        XCTAssertNotNil(paragraph)
        XCTAssertEqual(paragraph?.children.count, 1)
        let paragraphText = paragraph?.children[0] as? TextNode
        XCTAssertEqual(paragraphText?.text, "This is a paragraph.")
    }
    
    func testCodeAndImageGFMParsing() throws {
        let parser = MarkdownParser()
        let markdownString = """
        ```swift
        print("Hello")
        ```
        ![My Image](https://example.com/img.png "Optional Title")
        """
        
        let docNode = parser.parse(markdownString)
        XCTAssertEqual(docNode.children.count, 2)
        
        // Test Code Block
        let codeBlock = docNode.children[0] as? CodeBlockNode
        XCTAssertNotNil(codeBlock)
        XCTAssertEqual(codeBlock?.language, "swift")
        XCTAssertEqual(codeBlock?.code, "print(\"Hello\")\n") // cmark raw code blocks include a trailing newline
        
        // Test Image (contained within a Paragraph block implicitly by swift-markdown)
        let paragraph = docNode.children[1] as? ParagraphNode
        XCTAssertNotNil(paragraph)
        
        let image = paragraph?.children[0] as? ImageNode
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.source, "https://example.com/img.png")
        XCTAssertEqual(image?.altText, "My Image")
        XCTAssertEqual(image?.title, "Optional Title")
    }

    func testEngineDefaultPluginsIncludeCorePipeline() {
        let plugins = MarkdownKitEngine.defaultPlugins()
        XCTAssertEqual(plugins.count, 3)
        XCTAssertTrue(plugins.contains { $0 is DetailsExtractionPlugin })
        XCTAssertTrue(plugins.contains { $0 is DiagramExtractionPlugin })
        XCTAssertTrue(plugins.contains { $0 is MathExtractionPlugin })
    }

    func testEngineCanIncludeGitHubAutolinkPlugin() {
        let parser = MarkdownKitEngine.makeParser(includeGitHubAutolinks: true)
        XCTAssertTrue(parser.plugins.contains { $0 is GitHubAutolinkPlugin })
    }

    func testEngineConvenienceLayoutReturnsChildren() async {
        let layout = await MarkdownKitEngine.layout(
            markdown: "# Title\n\nParagraph text",
            constrainedToWidth: 400
        )

        XCTAssertEqual(layout.children.count, 2)
        XCTAssertTrue(layout.children[0].node is HeaderNode)
        XCTAssertTrue(layout.children[1].node is ParagraphNode)
    }
}
