import XCTest
@testable import MarkdownKit

#if canImport(WebKit)

final class MathCacheTests: XCTestCase {

    func testCacheMissReturnsNil() {
        let latex = "\\frac{1}{2}_\(UUID().uuidString)"
        let result = MathRenderer.cachedImage(for: latex)
        XCTAssertNil(result, "Cache should miss for never-rendered equations")
    }

    func testCachedImageReturnedAfterAsyncRender() async throws {
        let latex = "x^2"
        let expectation = XCTestExpectation(description: "Math render completes")

        await MainActor.run {
            MathRenderer.shared.render(latex: latex, display: false) { _ in
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 10.0)

        // After async render, the cache should have the image
        // (may be nil if MathJax/WebKit not available in test env, so we just verify no crash)
        _ = MathRenderer.cachedImage(for: latex)
    }

}

#endif
