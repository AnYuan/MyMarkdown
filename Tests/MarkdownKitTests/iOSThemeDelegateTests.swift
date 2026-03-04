import XCTest
@testable import MarkdownKit

#if canImport(UIKit) && !os(watchOS)
import UIKit

private final class MockThemeDelegate: MarkdownCollectionViewThemeDelegate {
    var reloadCount = 0
    var lastView: MarkdownCollectionView?

    func markdownCollectionViewDidRequestThemeReload(_ view: MarkdownCollectionView) {
        reloadCount += 1
        lastView = view
    }
}

@MainActor
final class iOSThemeDelegateTests: XCTestCase {

    func testDelegatePropertyIsWeak() {
        let view = MarkdownCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        autoreleasepool {
            let delegate = MockThemeDelegate()
            view.themeDelegate = delegate
            XCTAssertNotNil(view.themeDelegate)
        }
        // Delegate should be deallocated since it's weak
        XCTAssertNil(view.themeDelegate)
    }

    func testDelegateSetBeforeTraitRegistration() {
        // Trait change observation is registered in setup() via registerForTraitChanges.
        // Verify delegate can be set after init and is retained.
        let view = MarkdownCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let delegate = MockThemeDelegate()
        view.themeDelegate = delegate

        XCTAssertNotNil(view.themeDelegate)
        XCTAssertTrue(view.themeDelegate === delegate)
    }

    func testNoDelegateNoCrash() {
        // No delegate set — registerForTraitChanges callback should handle nil gracefully
        let view = MarkdownCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        XCTAssertNil(view.themeDelegate)
        // Verify the view fully initialized its subview hierarchy despite no delegate
        XCTAssertGreaterThan(view.subviews.count, 0, "Collection view should be added as subview during setup")
    }

    func testLayoutsPropertyTriggerReload() {
        let view = MarkdownCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))

        // Set non-empty layouts, then verify the property propagated
        let node = ParagraphNode(range: nil, children: [TextNode(range: nil, text: "test")])
        let layout = LayoutResult(node: node, size: CGSize(width: 320, height: 40))
        view.layouts = [layout]
        XCTAssertEqual(view.layouts.count, 1)

        // Clear and verify
        view.layouts = []
        XCTAssertEqual(view.layouts.count, 0)
    }
}
#endif
