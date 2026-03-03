import XCTest
@testable import MarkdownKit

#if canImport(UIKit) && !os(watchOS)
import UIKit

@MainActor
final class AsyncCodeViewCopyTests: XCTestCase {

    // MARK: - Helpers

    private func findCopyButton(in view: AsyncCodeView) -> UIButton? {
        view.subviews.compactMap { $0 as? UIButton }.first
    }

    private func configuredCodeView(code: String = "let x = 42", language: String? = "swift") -> AsyncCodeView {
        let node = CodeBlockNode(range: nil, language: language, code: code)
        let attrStr = NSAttributedString(string: code)
        let layout = LayoutResult(
            node: node,
            size: CGSize(width: 300, height: 100),
            attributedString: attrStr
        )
        let view = AsyncCodeView(frame: CGRect(origin: .zero, size: layout.size))
        view.configure(with: layout)
        return view
    }

    // MARK: - Tests

    func testCopyButtonExists() {
        let view = AsyncCodeView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        let button = findCopyButton(in: view)
        XCTAssertNotNil(button, "AsyncCodeView should contain a UIButton for copying")
    }

    func testCopySetsClipboard() {
        let view = configuredCodeView(code: "print(\"hello\")")
        let button = findCopyButton(in: view)!

        button.sendActions(for: .touchUpInside)

        XCTAssertEqual(UIPasteboard.general.string, "print(\"hello\")")
    }

    func testCopyWithEmptyCodeDoesNothing() {
        let sentinel = "SENTINEL_\(UUID().uuidString)"
        UIPasteboard.general.string = sentinel

        let view = configuredCodeView(code: "")
        let button = findCopyButton(in: view)!

        button.sendActions(for: .touchUpInside)

        // Pasteboard should remain unchanged since rawCode is empty
        XCTAssertEqual(UIPasteboard.general.string, sentinel)
    }

    func testCopyButtonImageChangesAfterCopy() {
        let view = configuredCodeView()
        let button = findCopyButton(in: view)!

        let originalImage = button.image(for: .normal)
        XCTAssertNotNil(originalImage)

        button.sendActions(for: .touchUpInside)

        // After copy, icon should change to checkmark
        let newImage = button.image(for: .normal)
        XCTAssertNotNil(newImage)
        XCTAssertNotEqual(originalImage, newImage, "Button image should change after copy action")
    }

    func testCopyButtonImageRevertsAfterDelay() async throws {
        let view = configuredCodeView()
        let button = findCopyButton(in: view)!

        let originalImage = button.image(for: .normal)
        button.sendActions(for: .touchUpInside)

        // Wait for the 2-second revert animation
        try await Task.sleep(for: .seconds(2.5))

        let revertedImage = button.image(for: .normal)
        XCTAssertEqual(originalImage, revertedImage, "Button image should revert to original after delay")
    }

    func testCopyWithDiagramNode() {
        let node = DiagramNode(range: nil, language: .mermaid, source: "graph TD; A-->B;")
        let attrStr = NSAttributedString(string: "graph TD; A-->B;")
        let layout = LayoutResult(
            node: node,
            size: CGSize(width: 300, height: 100),
            attributedString: attrStr
        )
        let view = AsyncCodeView(frame: CGRect(origin: .zero, size: layout.size))
        view.configure(with: layout)
        let button = findCopyButton(in: view)!

        button.sendActions(for: .touchUpInside)

        XCTAssertEqual(UIPasteboard.general.string, "graph TD; A-->B;")
    }
}
#endif
