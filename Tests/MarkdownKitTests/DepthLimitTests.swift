import XCTest
import Markdown
@testable import MarkdownKit

final class DepthLimitTests: XCTestCase {
    
    func testASTConstructionLimitsDepth() {
        // Construct a maliciously deep blockquote payload
        let maliciousDepth = 2000
        var maliciousPayload = ""
        for _ in 0..<maliciousDepth {
            maliciousPayload += "> "
        }
        maliciousPayload += "Hello"
        
        let parser = MarkdownParser()
        let document = parser.parse(maliciousPayload)
        
        // Assert it parsed successfully without crashing, but tree depth is clamped.
        var currentDepth = 0
        var currentNode = document.children.first
        
        while let node = currentNode as? BlockQuoteNode, let next = node.children.first {
            currentDepth += 1
            currentNode = next
        }
        
        // The parser has a maxDepth of 50. It should clamp around there.
        XCTAssertLessThanOrEqual(currentDepth, 50, "Parser allowed nested depth to exceed the security limit.")
    }
}
