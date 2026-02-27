//
//  AsyncTextView.swift
//  MarkdownKit
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A Texture-inspired asynchronous native view.
/// This view does NOT use `UITextView` or `UILabel` internally. Instead, it maintains a lightweight `CALayer`.
/// Upon receiving a `LayoutResult`, it dispatches text drawing to a background GCD queue, 
/// generating a `CGImage` of the text pixel-perfectly, and then sets the `layer.contents` on the main thread.
/// This utterly eliminates main-thread blocking when scrolling millions of words.
public class AsyncTextView: UIView {
    
    private var currentDrawTask: Task<Void, Never>?
    private let textLayoutManager = NSTextLayoutManager()
    private let textContainer = NSTextContainer(size: .zero)
    private let textContentStorage = NSTextContentStorage()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.backgroundColor = .clear
        self.layer.drawsAsynchronously = true // CoreAnimation hint to draw content to a separate backing store
        
        // Wire up TextKit 2 local instances for background drawing
        textContentStorage.addTextLayoutManager(textLayoutManager)
        textLayoutManager.textContainer = textContainer
        textContentStorage.textStorage = NSTextStorage()
        textContainer.lineFragmentPadding = 0
    }
    
    /// Binds the `LayoutResult` constraint to the view, launching an asynchronous drawing operation.
    public func configure(with layout: LayoutResult) {
        // Cancel any pending draw operation if this view was recycled quickly
        currentDrawTask?.cancel()
        
        self.frame.size = layout.size
        
        guard let string = layout.attributedString, string.length > 0 else {
            self.layer.contents = nil
            return
        }
        
        // Start Texture's exact Display State process
        currentDrawTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            // Re-render strings to a CGContext on a background CPU vector
            let width = layout.size.width
            let height = layout.size.height
            
            // Cooperative yielding before heavy CoreGraphics work
            await Task.yield()
            if Task.isCancelled { return }
            
            // Create CoreGraphics graphics context isolated from main UI loop
            let format = UIGraphicsImageRendererFormat()
            format.scale = await UIScreen.main.scale // Thread-safe fetch or caching can be optimized later
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            
            let renderedImage = renderer.image { ctx in
                // Set constraints purely on background queue local vars
                self.textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
                self.textContentStorage.textStorage?.setAttributedString(string)
                self.textLayoutManager.ensureLayout(for: self.textLayoutManager.documentRange)
                
                // Draw precisely 
                self.textLayoutManager.draw(self.textLayoutManager.documentRange, in: ctx.cgContext, origin: .zero)
            }
            
            if Task.isCancelled { return }
            
            // Mount the rasterized texture to the main thread's layer.contents (Instantaneous)
            await MainActor.run {
                self.layer.contents = renderedImage.cgImage
            }
        }
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Light/Dark mode transitions trigger re-draws in Phase 4
    }
}
#endif
