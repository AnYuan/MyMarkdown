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

    func testEvictsOldestWhenAtCapacity() async {
        let suppressor = MathWarningSuppressor(capacity: 3)

        // Fill to capacity
        let r1 = await suppressor.shouldLog("error-1")
        let r2 = await suppressor.shouldLog("error-2")
        let r3 = await suppressor.shouldLog("error-3")
        XCTAssertTrue(r1)
        XCTAssertTrue(r2)
        XCTAssertTrue(r3)

        // Duplicates still suppressed
        let dup = await suppressor.shouldLog("error-2")
        XCTAssertFalse(dup)

        // Adding a 4th should evict "error-1"
        let r4 = await suppressor.shouldLog("error-4")
        XCTAssertTrue(r4)

        // "error-1" was evicted, so it should be loggable again
        let relogged = await suppressor.shouldLog("error-1")
        XCTAssertTrue(relogged)

        // Count should not exceed capacity
        let count = await suppressor.count
        XCTAssertLessThanOrEqual(count, 3)
    }
}
#endif
