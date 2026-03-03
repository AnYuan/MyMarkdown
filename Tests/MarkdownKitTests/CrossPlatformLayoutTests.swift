import XCTest
@testable import MarkdownKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Tests verifying cross-platform iOS/macOS layout behavior.
final class CrossPlatformLayoutTests: XCTestCase {

    // MARK: - Color.platformSecondaryLabel

    func testPlatformSecondaryLabelIsNotClear() {
        let color = Color.platformSecondaryLabel
        // The secondary label color should be an actual visible color, not .clear
        XCTAssertNotEqual(color, .clear)
    }

    func testPlatformSecondaryLabelMatchesNativeColor() {
        #if canImport(UIKit)
        XCTAssertEqual(Color.platformSecondaryLabel, UIColor.secondaryLabel)
        #elseif canImport(AppKit)
        XCTAssertEqual(Color.platformSecondaryLabel, NSColor.secondaryLabelColor)
        #endif
    }

    // MARK: - Table layout (cross-platform)

    func testTableLayoutProducesNonEmptyAttributedString() async throws {
        let markdown = """
        | Name | Score |
        |------|-------|
        | Alice | 95   |
        | Bob   | 87   |
        """
        let layout = await TestHelper.solveLayout(markdown, width: 500)
        XCTAssertEqual(layout.children.count, 1)

        let tableLayout = layout.children[0]
        XCTAssertNotNil(tableLayout.attributedString)
        XCTAssertGreaterThan(tableLayout.size.height, 0)
        XCTAssertGreaterThan(tableLayout.size.width, 0)
    }

    func testTableLayoutContainsAllCellContent() async throws {
        let markdown = """
        | Platform | Status |
        |----------|--------|
        | macOS    | Done   |
        | iOS      | Done   |
        """
        let layout = await TestHelper.solveLayout(markdown, width: 500)
        let text = layout.children[0].attributedString?.string ?? ""

        XCTAssertTrue(text.contains("Platform"), "Missing header cell 'Platform'")
        XCTAssertTrue(text.contains("Status"), "Missing header cell 'Status'")
        XCTAssertTrue(text.contains("macOS"), "Missing body cell 'macOS'")
        XCTAssertTrue(text.contains("iOS"), "Missing body cell 'iOS'")
        XCTAssertTrue(text.contains("Done"), "Missing body cell 'Done'")
    }

    func testTableLayoutDoesNotExposeRawMarkdown() async throws {
        let markdown = """
        | A | B |
        |---|---|
        | 1 | 2 |
        """
        let layout = await TestHelper.solveLayout(markdown, width: 400)
        let text = layout.children[0].attributedString?.string ?? ""

        XCTAssertFalse(text.contains("|---"), "Should not expose markdown separator syntax")
    }

    func testTableLayoutHeaderUsedBoldFont() async throws {
        let markdown = """
        | Header |
        |--------|
        | Body   |
        """
        let layout = await TestHelper.solveLayout(markdown, width: 400)
        guard let attrStr = layout.children[0].attributedString else {
            XCTFail("Table layout missing attributed string")
            return
        }

        // Check the first character's font (should be from the header row)
        guard attrStr.length > 0 else {
            XCTFail("Empty attributed string")
            return
        }

        let firstCharAttrs = attrStr.attributes(at: 0, effectiveRange: nil)
        guard let font = firstCharAttrs[.font] as? Font else {
            XCTFail("No font attribute on first character")
            return
        }

        #if canImport(UIKit)
        let isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
        #elseif canImport(AppKit)
        let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
        #endif
        XCTAssertTrue(isBold, "Header row should use bold font")
    }

    func testTableLayoutSingleColumnTable() async throws {
        let markdown = """
        | Only |
        |------|
        | Cell |
        """
        let layout = await TestHelper.solveLayout(markdown, width: 400)
        let text = layout.children[0].attributedString?.string ?? ""

        XCTAssertTrue(text.contains("Only"))
        XCTAssertTrue(text.contains("Cell"))
    }

    func testTableLayoutManyColumns() async throws {
        let markdown = """
        | A | B | C | D | E |
        |---|---|---|---|---|
        | 1 | 2 | 3 | 4 | 5 |
        """
        let layout = await TestHelper.solveLayout(markdown, width: 800)
        let text = layout.children[0].attributedString?.string ?? ""

        for char in ["A", "B", "C", "D", "E", "1", "2", "3", "4", "5"] {
            XCTAssertTrue(text.contains(char), "Missing cell '\(char)' in table output")
        }
    }

    // MARK: - Code block language label uses platformSecondaryLabel

    func testCodeBlockLanguageLabelColor() async throws {
        let markdown = """
        ```swift
        let x = 1
        ```
        """
        let layout = await TestHelper.solveLayout(markdown, width: 400)
        guard let attrStr = layout.children[0].attributedString else {
            XCTFail("Code layout missing attributed string")
            return
        }

        // The first run is the language label "SWIFT\n" which should use platformSecondaryLabel
        guard attrStr.length > 0 else { return }
        let attrs = attrStr.attributes(at: 0, effectiveRange: nil)
        guard let color = attrs[.foregroundColor] as? Color else {
            XCTFail("No foreground color on language label")
            return
        }
        XCTAssertEqual(color, Color.platformSecondaryLabel,
                       "Language label should use platformSecondaryLabel color")
    }
}
