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

    func testHTMLBuilderCreatesValidBaseStructure() {
        let html = MermaidHTMLBuilder.makeBaseHTML()

        XCTAssertTrue(html.contains(#"<div id="mermaid-root"></div>"#))
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
    }
}
#endif
