import XCTest
@testable import MyMarkdown

final class LayoutTests: XCTestCase {
    
    func testBackgroundLayoutSizingAndCaching() async throws {
        let parser = MarkdownParser()
        let markdownString = """
        # Hello
        This is a much longer paragraph that should theoretically wrap if we constrain it to a very tight width, unlike the header.
        """
        
        let docNode = parser.parse(markdownString)
        
        let cache = LayoutCache()
        let solver = LayoutSolver(cache: cache)
        
        // 1. First Pass Layout (Not Cached)
        let tightWidth: CGFloat = 100.0
        
        let _ = PerformanceProfiler.measure(.layoutCalculation) {
            // Cannot use measure directly with async in basic XCTest yet without thunks, 
            // so using a semaphore or just awaiting.
        }
        
        // We will just await for the test since XCTest perform measure blocks synchronusly
        let rootLayout = await solver.solve(node: docNode, constrainedToWidth: tightWidth)
        
        XCTAssertEqual(rootLayout.children.count, 2)
        
        let headerLayout = rootLayout.children[0]
        let paragraphLayout = rootLayout.children[1]
        
        // 2. Verify TextKit 2 constraints
        // The header "Hello" should easily fit within 100 width.
        XCTAssertLessThanOrEqual(headerLayout.size.width, tightWidth)
        XCTAssertGreaterThan(headerLayout.size.height, 0)
        
        // The paragraph is long, so it MUST wrap, meaning height will be significantly larger than one line.
        XCTAssertLessThanOrEqual(paragraphLayout.size.width, tightWidth)
        XCTAssertGreaterThan(paragraphLayout.size.height, headerLayout.size.height)
        
        // 3. Verify Caching
        // A second request for the exact same node at the exact same width should instantaneously return 
        // the exact same reference from the LayoutCache.
        let cachedLayout = await solver.solve(node: docNode, constrainedToWidth: tightWidth)
        XCTAssertEqual(rootLayout.size, cachedLayout.size)
        
        // Verify we can clear the cache
        cache.clear()
        let nilLayout = cache.getLayout(for: docNode, constrainedToWidth: tightWidth)
        XCTAssertNil(nilLayout)
    }
}
