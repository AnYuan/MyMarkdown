import XCTest
@testable import MarkdownKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class HighlighterAndProfilerTests: XCTestCase {

    // MARK: - SplashHighlighter

    func testHighlightSwiftCodeProducesMultipleRuns() {
        let highlighter = SplashHighlighter()
        let result = highlighter.highlight("let x = 42\nprint(x)", language: "swift")

        var runCount = 0
        result.enumerateAttributes(
            in: NSRange(location: 0, length: result.length)
        ) { _, _, _ in
            runCount += 1
        }
        XCTAssertGreaterThan(runCount, 1,
            "Swift code should produce multiple highlighted attribute runs")
    }

    func testHighlightEmptyStringProducesEmptyResult() {
        let highlighter = SplashHighlighter()
        let result = highlighter.highlight("", language: nil)
        XCTAssertEqual(result.length, 0)
    }

    func testHighlightWithCustomTheme() {
        let customCode = TypographyToken(font: Font.monospacedSystemFont(ofSize: 20, weight: .bold))
        let theme = Theme(
            typography: Theme.Typography(
                header1: TypographyToken(font: Font.systemFont(ofSize: 32)),
                header2: TypographyToken(font: Font.systemFont(ofSize: 24)),
                header3: TypographyToken(font: Font.systemFont(ofSize: 20)),
                paragraph: TypographyToken(font: Font.systemFont(ofSize: 16)),
                codeBlock: customCode
            ),
            colors: Theme.Colors(
                textColor: ColorToken(foreground: .white),
                codeColor: ColorToken(foreground: .green, background: .black),
                tableColor: ColorToken(foreground: .gray, background: .darkGray)
            )
        )

        let highlighter = SplashHighlighter(theme: theme)
        let result = highlighter.highlight("var name = \"test\"", language: "swift")
        XCTAssertGreaterThan(result.length, 0)
    }

    func testHighlightPreservesCodeContent() {
        let highlighter = SplashHighlighter()
        let code = "func hello() { }"
        let result = highlighter.highlight(code, language: "swift")
        XCTAssertTrue(result.string.contains("func"))
        XCTAssertTrue(result.string.contains("hello"))
    }

    func testHighlightPythonCodeUsesGenericKeywordHighlighting() {
        let highlighter = SplashHighlighter()
        let code = "def hello():\n    print('world')"
        let result = highlighter.highlight(code, language: "python")

        var runCount = 0
        result.enumerateAttributes(
            in: NSRange(location: 0, length: result.length)
        ) { _, _, _ in
            runCount += 1
        }

        XCTAssertGreaterThan(runCount, 1,
            "Python code should have keyword-highlighted attribute runs")
    }

    func testHighlightUnlabeledCodeDoesNotUseSplash() {
        let highlighter = SplashHighlighter()
        let code = "x = 42\nprint(x)"
        let result = highlighter.highlight(code, language: nil)

        var runCount = 0
        result.enumerateAttributes(
            in: NSRange(location: 0, length: result.length)
        ) { _, _, _ in
            runCount += 1
        }

        XCTAssertEqual(runCount, 1,
            "Unlabeled code should fall back to plain styling")
    }

    func testSupportedLanguagesProperty() {
        XCTAssertTrue(SplashHighlighter.supportedLanguages.contains("swift"))
        XCTAssertTrue(SplashHighlighter.supportedLanguages.contains("python"))
        XCTAssertTrue(SplashHighlighter.supportedLanguages.contains("javascript"))
        XCTAssertFalse(SplashHighlighter.supportedLanguages.contains("brainfuck"))
    }

    func testHighlightUnknownLanguageFallsBackToPlain() {
        let highlighter = SplashHighlighter()
        let result = highlighter.highlight("some code", language: "brainfuck")

        var runCount = 0
        result.enumerateAttributes(
            in: NSRange(location: 0, length: result.length)
        ) { _, _, _ in
            runCount += 1
        }

        XCTAssertEqual(runCount, 1,
            "Truly unknown language should use plain styling")
    }

    func testHighlightTreatsSwiftLanguageCaseInsensitively() {
        let highlighter = SplashHighlighter()
        let result = highlighter.highlight("let x = 42\nprint(x)", language: "SWIFT")

        var runCount = 0
        result.enumerateAttributes(
            in: NSRange(location: 0, length: result.length)
        ) { _, _, _ in
            runCount += 1
        }

        XCTAssertGreaterThan(runCount, 1,
            "Swift aliases should still use syntax highlighting")
    }

    // MARK: - PerformanceProfiler

    func testMeasureSyncReturnsNonNegativeTime() {
        let elapsed = PerformanceProfiler.measure(.astParsing, log: false) {
            _ = 1 + 1
        }
        XCTAssertGreaterThanOrEqual(elapsed, 0)
    }

    func testMeasureAsyncReturnsNonNegativeTime() async throws {
        let elapsed = await PerformanceProfiler.measureAsync(.layoutCalculation, log: false) {
            await Task.yield()
        }
        XCTAssertGreaterThanOrEqual(elapsed, 0)
    }

    func testMeasureMetricRawValues() {
        XCTAssertEqual(PerformanceProfiler.Metric.astParsing.rawValue, "AST Parsing")
        XCTAssertEqual(PerformanceProfiler.Metric.layoutCalculation.rawValue, "Layout Calculation")
        XCTAssertEqual(PerformanceProfiler.Metric.viewMounting.rawValue, "View Mounting")
        XCTAssertEqual(PerformanceProfiler.Metric.totalRendering.rawValue, "Total Rendering Time")
    }
}
