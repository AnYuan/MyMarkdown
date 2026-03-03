import Foundation

#if os(macOS)
import AppKit

@MainActor
enum SnapshotTestHelper {
    static func applyStableAppearance(to view: NSView) {
        guard let stableAppearance = NSAppearance(named: .aqua) else { return }
        view.appearance = stableAppearance
    }
}
#endif
