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
        // No delegate set — the registerForTraitChanges callback should handle nil gracefully
        let view = MarkdownCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        XCTAssertNil(view.themeDelegate)
        // View initializes without crash even with no delegate
    }

    func testLayoutsPropertySetter() {
        let view = MarkdownCollectionView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        // Setting empty layouts should not crash
        view.layouts = []
        XCTAssertEqual(view.layouts.count, 0)
    }
}
#endif
