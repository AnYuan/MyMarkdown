import XCTest
@testable import MarkdownKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Micro-benchmarks for cache operations: get/set cost, eviction behavior under pressure.
final class BenchmarkCacheTests: XCTestCase {

    private let harness = BenchmarkHarness(warmup: 3, iterations: 20)
    private let defaultWidth: CGFloat = 800.0

    // MARK: - Cache Get/Set Micro-Benchmarks

    /// Measures the raw cost of cache hit, miss, set, and clear operations.
    func testCacheGetSetMicro() async {
        var results: [BenchmarkResult] = []

        let parser = MarkdownParser()
        let doc = parser.parse(BenchmarkFixtures.medium)
        let cache = LayoutCache()
        let solver = LayoutSolver(cache: cache)

        // Populate cache
        _ = await solver.solve(node: doc, constrainedToWidth: defaultWidth)

        // Cache hit
        results.append(
            harness.measure(label: "getLayout(hit)", fixture: "medium") {
                _ = cache.getLayout(for: doc, constrainedToWidth: self.defaultWidth)
            }
        )

        // Cache miss (different width)
        results.append(
            harness.measure(label: "getLayout(miss)", fixture: "medium") {
                _ = cache.getLayout(for: doc, constrainedToWidth: 999)
            }
        )

        // setLayout cost
        let layout = cache.getLayout(for: doc, constrainedToWidth: defaultWidth)!
        results.append(
            harness.measure(label: "setLayout()", fixture: "medium") {
                cache.setLayout(layout, constrainedToWidth: 12345)
            }
        )

        // clear() cost
        results.append(
            harness.measure(label: "clear()", fixture: "medium") {
                cache.clear()
            }
        )

        BenchmarkReportFormatter.printSections([
            ("Cache Operations", results),
        ])
    }

    // MARK: - Cache Eviction Pressure

    /// Compares solve performance with a tiny cache (forced eviction) vs a large cache.
    func testCacheEvictionPressure() async {
        var results: [BenchmarkResult] = []
        let parser = MarkdownParser()
        let doc = parser.parse(BenchmarkFixtures.medium)

        // Tiny cache: countLimit=10, forces constant eviction
        let tinyCache = LayoutCache(countLimit: 10)
        let tinySolver = LayoutSolver(cache: tinyCache)
        results.append(
            await harness.measureAsync(label: "solve(tiny-cache)", fixture: "medium") {
                for w in stride(from: 300, through: 1000, by: 50) {
                    _ = await tinySolver.solve(node: doc, constrainedToWidth: CGFloat(w))
                }
            }
        )

        // Large cache: no eviction expected
        let bigCache = LayoutCache(countLimit: 100_000)
        let bigSolver = LayoutSolver(cache: bigCache)
        results.append(
            await harness.measureAsync(label: "solve(large-cache)", fixture: "medium") {
                for w in stride(from: 300, through: 1000, by: 50) {
                    _ = await bigSolver.solve(node: doc, constrainedToWidth: CGFloat(w))
                }
            }
        )

        // Second pass on large cache: everything should be cached
        results.append(
            await harness.measureAsync(label: "solve(warm-large)", fixture: "medium") {
                for w in stride(from: 300, through: 1000, by: 50) {
                    _ = await bigSolver.solve(node: doc, constrainedToWidth: CGFloat(w))
                }
            }
        )

        BenchmarkReportFormatter.printSections([
            ("Cache Eviction Pressure", results),
        ])
    }
}
