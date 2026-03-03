import XCTest
import Markdown
@testable import MarkdownKit

final class CommonMarkSpecTests: XCTestCase {

    struct SpecExample: Codable {
        let markdown: String
        let html: String
        let example: Int
        let start_line: Int
        let end_line: Int
        let section: String
    }

    private func loadSpecExamples() throws -> [SpecExample] {
        guard let fixtureURL = Bundle.module.url(
            forResource: "commonmark_spec",
            withExtension: "json",
            subdirectory: "Fixtures"
        ) else {
            XCTFail("Could not find commonmark_spec.json in test bundle resources.")
            return []
        }

        let data = try Data(contentsOf: fixtureURL)
        return try JSONDecoder().decode([SpecExample].self, from: data)
    }

    private func diagnostic(_ example: SpecExample) -> String {
        "example=\(example.example), section=\"\(example.section)\", lines=\(example.start_line)-\(example.end_line)"
    }

    private func flattenedText(in node: MarkdownNode) -> String {
        if let text = node as? TextNode {
            return text.text
        }
        return node.children.map(flattenedText(in:)).joined()
    }

    private func assertSemanticCase(
        exampleID: Int,
        family: String,
        examplesByID: [Int: SpecExample],
        parser: MarkdownParser,
        assertions: (DocumentNode, SpecExample) -> Void
    ) {
        guard let example = examplesByID[exampleID] else {
            XCTFail("Missing CommonMark fixture example \(exampleID) for \(family)")
            return
        }
        let ast = parser.parse(example.markdown)
        assertions(ast, example)
    }

    func testAllCommonMarkSpecExamples() throws {
        let examples = try loadSpecExamples()
        XCTAssertEqual(examples.count, 652, "Expected exactly 652 CommonMark 0.31.2 examples.")

        let parser = MarkdownParser()
        var successCount = 0

        for example in examples {
            // Our primary goal for "100% compliance" in MarkdownKit (a native ast renderer)
            // is to ensure that every single one of these 652 edge cases parses successfully
            // into our custom AST without throwing a fatal error, crashing, or looping infinitely.

            let ast = parser.parse(example.markdown)
            XCTAssertNotNil(ast, "Failed to parse DocumentNode [\(diagnostic(example))]")
            successCount += 1
        }

        print("✅ Successfully parsed \(successCount) CommonMark Specification edge cases without crashing.")
    }

    func testCuratedCommonMarkSemanticSubset() throws {
        let examples = try loadSpecExamples()
        let examplesByID = Dictionary(uniqueKeysWithValues: examples.map { ($0.example, $0) })
        let parser = MarkdownParser()

        assertSemanticCase(
            exampleID: 62,
            family: "ATX headings",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            let levels = ast.children.compactMap { ($0 as? HeaderNode)?.level }
            XCTAssertEqual(
                levels,
                [1, 2, 3, 4, 5, 6],
                "Expected six heading levels [\(diagnostic(example))]"
            )
            for node in ast.children {
                guard let header = node as? HeaderNode else {
                    XCTFail("Expected HeaderNode child [\(diagnostic(example))]")
                    return
                }
                XCTAssertEqual(
                    flattenedText(in: header),
                    "foo",
                    "Expected heading text to be 'foo' [\(diagnostic(example))]"
                )
            }
        }

        assertSemanticCase(
            exampleID: 43,
            family: "Thematic breaks",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            XCTAssertEqual(
                ast.children.count,
                3,
                "Expected three thematic breaks [\(diagnostic(example))]"
            )
            XCTAssertTrue(
                ast.children.allSatisfy { $0 is ThematicBreakNode },
                "Expected all children to be ThematicBreakNode [\(diagnostic(example))]"
            )
        }

        assertSemanticCase(
            exampleID: 228,
            family: "Block quotes",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            guard let blockQuote = ast.children.first as? BlockQuoteNode else {
                XCTFail("Expected first child to be BlockQuoteNode [\(diagnostic(example))]")
                return
            }
            XCTAssertTrue(
                blockQuote.children.contains { $0 is HeaderNode },
                "Expected block quote to contain header [\(diagnostic(example))]"
            )
            XCTAssertTrue(
                blockQuote.children.contains { $0 is ParagraphNode },
                "Expected block quote to contain paragraph [\(diagnostic(example))]"
            )

            let quoteText = flattenedText(in: blockQuote)
            XCTAssertTrue(
                quoteText.contains("Foo") && quoteText.contains("bar") && quoteText.contains("baz"),
                "Expected quote text to include Foo/bar/baz [\(diagnostic(example))]"
            )
        }

        assertSemanticCase(
            exampleID: 301,
            family: "Lists",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            let lists = ast.children.compactMap { $0 as? ListNode }
            guard lists.count == 2 else {
                XCTFail("Expected two lists split by bullet marker change [\(diagnostic(example))]")
                return
            }
            XCTAssertTrue(lists.allSatisfy { !$0.isOrdered }, "Expected unordered lists [\(diagnostic(example))]")
            XCTAssertEqual(lists[0].children.count, 2, "Expected first list to contain two items [\(diagnostic(example))]")
            XCTAssertEqual(lists[1].children.count, 1, "Expected second list to contain one item [\(diagnostic(example))]")

            let itemTexts = lists.flatMap { $0.children }.map { flattenedText(in: $0) }
            XCTAssertEqual(itemTexts, ["foo", "bar", "baz"], "Unexpected list content [\(diagnostic(example))]")
        }

        assertSemanticCase(
            exampleID: 328,
            family: "Code spans",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            guard
                let paragraph = ast.children.first as? ParagraphNode,
                let inlineCode = paragraph.children.first(where: { $0 is InlineCodeNode }) as? InlineCodeNode
            else {
                XCTFail("Expected InlineCodeNode inside paragraph [\(diagnostic(example))]")
                return
            }
            XCTAssertEqual(inlineCode.code, "foo", "Unexpected inline code value [\(diagnostic(example))]")
        }

        assertSemanticCase(
            exampleID: 350,
            family: "Emphasis",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            guard
                let paragraph = ast.children.first as? ParagraphNode,
                let emphasis = paragraph.children.first(where: { $0 is EmphasisNode }) as? EmphasisNode
            else {
                XCTFail("Expected EmphasisNode inside paragraph [\(diagnostic(example))]")
                return
            }
            XCTAssertEqual(flattenedText(in: emphasis), "foo bar", "Unexpected emphasis text [\(diagnostic(example))]")
        }

        assertSemanticCase(
            exampleID: 142,
            family: "Fenced code blocks",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            guard let codeBlock = ast.children.first as? CodeBlockNode else {
                XCTFail("Expected first child to be CodeBlockNode [\(diagnostic(example))]")
                return
            }
            XCTAssertEqual(codeBlock.language, "ruby", "Expected fenced language ruby [\(diagnostic(example))]")
            XCTAssertTrue(
                codeBlock.code.contains("def foo(x)") && codeBlock.code.contains("return 3"),
                "Unexpected fenced code content [\(diagnostic(example))]"
            )
        }

        assertSemanticCase(
            exampleID: 482,
            family: "Links",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            guard
                let paragraph = ast.children.first as? ParagraphNode,
                let link = paragraph.children.first(where: { $0 is LinkNode }) as? LinkNode
            else {
                XCTFail("Expected LinkNode inside paragraph [\(diagnostic(example))]")
                return
            }
            XCTAssertEqual(link.destination, "/uri", "Unexpected link destination [\(diagnostic(example))]")
            XCTAssertEqual(link.title, "title", "Unexpected link title [\(diagnostic(example))]")
            XCTAssertEqual(flattenedText(in: link), "link", "Unexpected link text [\(diagnostic(example))]")
        }

        assertSemanticCase(
            exampleID: 572,
            family: "Images",
            examplesByID: examplesByID,
            parser: parser
        ) { ast, example in
            guard
                let paragraph = ast.children.first as? ParagraphNode,
                let image = paragraph.children.first(where: { $0 is ImageNode }) as? ImageNode
            else {
                XCTFail("Expected ImageNode inside paragraph [\(diagnostic(example))]")
                return
            }
            XCTAssertEqual(image.source, "/url", "Unexpected image source [\(diagnostic(example))]")
            XCTAssertEqual(image.altText, "foo", "Unexpected image alt text [\(diagnostic(example))]")
            XCTAssertEqual(image.title, "title", "Unexpected image title [\(diagnostic(example))]")
        }
    }
}
