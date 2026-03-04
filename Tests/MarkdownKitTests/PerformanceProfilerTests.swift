import XCTest
@testable import MarkdownKit

final class PerformanceProfilerTests: XCTestCase {

    func testProfilerExecutionMeasurement() {
        let executionTime = PerformanceProfiler.measure(.totalRendering) {
            usleep(10_000) // Sleep 10ms
        }
        XCTAssertGreaterThan(executionTime, 0, "Measured execution time should be greater than 0 ms")
    }
    
    func testAsyncProfilerExecutionMeasurement() async {
        let executionTime = await PerformanceProfiler.measureAsync(.astParsing, log: true) {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        XCTAssertGreaterThan(executionTime, 0, "Measured async execution time should be greater than 0 ms")
    }
}
