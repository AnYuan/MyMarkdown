#if canImport(SwiftUI)
import SwiftUI

#if canImport(UIKit)
import UIKit

@available(iOS 14.0, *)
struct MarkdownViewRepresentable: UIViewRepresentable {
    let layouts: [LayoutResult]
    let onToggleDetails: (Int, DetailsNode) -> Void
    
    func makeUIView(context: Context) -> MarkdownCollectionView {
        let view = MarkdownCollectionView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: MarkdownCollectionView, context: Context) {
        uiView.layouts = layouts
        uiView.onToggleDetails = onToggleDetails
    }
}

#elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

@available(macOS 11.0, *)
struct MarkdownViewRepresentable: NSViewRepresentable {
    let layouts: [LayoutResult]
    let onToggleDetails: (Int, DetailsNode) -> Void
    
    func makeNSView(context: Context) -> MarkdownCollectionView {
        let view = MarkdownCollectionView()
        return view
    }
    
    func updateNSView(_ nsView: MarkdownCollectionView, context: Context) {
        nsView.layouts = layouts
        nsView.onToggleDetails = onToggleDetails
    }
}
#endif
#endif
