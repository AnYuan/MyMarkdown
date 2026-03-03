import XCTest
@testable import MarkdownKit

#if canImport(WebKit)
final class MermaidDiagramAdapterTests: XCTestCase {

    func testBundledScriptExists() {
        XCTAssertNotNil(
            MermaidResourceLocator.bundledScriptURL(),
            "Bundled mermaid.min.js resource should exist"
        )
    }

    func testPreferredScriptURLStringPrefersBundledResource() {
        guard let bundled = MermaidResourceLocator.bundledScriptURL() else {
            XCTFail("Bundled mermaid.min.js resource missing")
            return
        }

        XCTAssertEqual(
            MermaidResourceLocator.preferredScriptURLString(),
            bundled.absoluteString
        )
    }

    func testHTMLBuilderEmbedsScriptAndBase64Source() {
        let source = "graph TD\nA-->B"
        let scriptURLString = "file:///tmp/mermaid.min.js"
        let html = MermaidHTMLBuilder.makeHTML(
            source: source,
            scriptURLString: scriptURLString
        )

        XCTAssertTrue(html.contains(scriptURLString))
        XCTAssertTrue(html.contains("window.atob"))
        XCTAssertFalse(
            html.contains(source),
            "Source should be encoded to avoid inline escaping bugs"
        )
    }
}
#endif
