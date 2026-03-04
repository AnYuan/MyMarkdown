import XCTest
@testable import MarkdownKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Multi-actor stress tests that exercise LayoutSolver concurrency boundaries.
/// Validates the @unchecked Sendable contract documented in ConcurrencyContract.md.
final class ConcurrencyStressTests: XCTestCase {

    private struct LayoutMetrics: Sendable {
        let height: CGFloat
        let childCount: Int
    }

    /// Exercise LayoutSolver from multiple concurrent tasks to detect data races.
    /// Each task creates its own parse → solve pipeline to comply with strict concurrency.
    func testConcurrentLayoutSolverAccess() async throws {
        let markdown = "Hello **world**"

        let results = await withTaskGroup(of: LayoutMetrics.self, returning: [LayoutMetrics].self) { group in
            for width in stride(from: 200.0, through: 800.0, by: 100.0) {
                group.addTask {
                    let doc = MarkdownParser().parse(markdown)
                    let solver = LayoutSolver()
                    let result = await solver.solve(node: doc, constrainedToWidth: CGFloat(width))
                    // Check children (paragraph layouts) rather than document-level size
                    let firstChildHeight = result.children.first?.size.height ?? 0
                    return LayoutMetrics(height: firstChildHeight, childCount: result.children.count)
                }
            }

            var collected: [LayoutMetrics] = []
            for await metric in group {
                collected.append(metric)
            }
            return collected
        }

        XCTAssertEqual(results.count, 7)
        for metric in results {
            XCTAssertGreaterThan(metric.childCount, 0, "Document should have child layouts")
            XCTAssertGreaterThan(metric.height, 0, "Child layout should have non-zero height")
        }
    }

    /// Exercise concurrent solve at varying widths with cache reuse.
    func testConcurrentSolveAtVaryingWidths() async throws {
        let markdown = "Hello **world**"

        let results = await withTaskGroup(of: LayoutMetrics.self, returning: [LayoutMetrics].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let doc = MarkdownParser().parse(markdown)
                    let solver = LayoutSolver()
                    _ = await solver.solve(node: doc, constrainedToWidth: 400)
                    let result = await solver.solve(
                        node: doc,
                        constrainedToWidth: CGFloat.random(in: 200...800)
                    )
                    let firstChildHeight = result.children.first?.size.height ?? 0
                    return LayoutMetrics(height: firstChildHeight, childCount: result.children.count)
                }
            }

            var collected: [LayoutMetrics] = []
            for await metric in group {
                collected.append(metric)
            }
            return collected
        }

        XCTAssertEqual(results.count, 10)
        for metric in results {
            XCTAssertGreaterThan(metric.height, 0, "Child layout should have non-zero height")
            XCTAssertGreaterThan(metric.childCount, 0, "Document should have child layouts")
        }
    }

    /// Validate that MarkdownParser.maxInputBytes reads/writes without corruption.
    func testMaxInputBytesThreadSafety() async throws {
        let originalValue = MarkdownParser.maxInputBytes
        defer { MarkdownParser.maxInputBytes = originalValue }

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                MarkdownParser.maxInputBytes = 2_000_000
            }
            for _ in 0..<20 {
                group.addTask {
                    let value = MarkdownParser.maxInputBytes
                    XCTAssertTrue(
                        value == originalValue || value == 2_000_000,
                        "maxInputBytes should not be corrupted: \(value)"
                    )
                }
            }
        }

        MarkdownParser.maxInputBytes = originalValue
    }

    /// Exercise concurrent parse + solve on the same markdown at the same width.
    /// All results should have identical dimensions (deterministic output).
    func testConcurrentSolveProducesDeterministicResults() async throws {
        let markdown = "Hello **world**"

        let results = await withTaskGroup(of: LayoutMetrics.self, returning: [LayoutMetrics].self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let doc = MarkdownParser().parse(markdown)
                    let solver = LayoutSolver()
                    let result = await solver.solve(node: doc, constrainedToWidth: 400)
                    let firstChildHeight = result.children.first?.size.height ?? 0
                    return LayoutMetrics(height: firstChildHeight, childCount: result.children.count)
                }
            }

            var collected: [LayoutMetrics] = []
            for await metric in group {
                collected.append(metric)
            }
            return collected
        }

        XCTAssertEqual(results.count, 10)
        let heights = Set(results.map { Int($0.height.rounded()) })
        XCTAssertEqual(heights.count, 1,
            "Concurrent solvers should produce deterministic heights")
    }
}
