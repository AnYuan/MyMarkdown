import XCTest
@testable import MarkdownKit

#if canImport(WebKit)
final class MathWarningSuppressorTests: XCTestCase {

    func testSuppressesDuplicateWarnings() async {
        let suppressor = MathWarningSuppressor()

        let first = await suppressor.shouldLog("Undefined control sequence \\binom")
        let second = await suppressor.shouldLog("Undefined control sequence \\binom")

        XCTAssertTrue(first)
        XCTAssertFalse(second)
    }

    func testDeduplicatesTrimmedMessages() async {
        let suppressor = MathWarningSuppressor()

        let first = await suppressor.shouldLog("  Undefined control sequence \\binom  ")
        let second = await suppressor.shouldLog("Undefined control sequence \\binom")

        XCTAssertTrue(first)
        XCTAssertFalse(second)
    }
}
#endif
