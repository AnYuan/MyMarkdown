//
//  TextKitCalculator.swift
//  MarkdownKit
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import os

/// A strictly background-queue-only utility class that uses Apple's native TextKit 2
/// (via `NSTextLayoutManager`) to precisely calculate the bounding sizes of
/// `NSAttributedString` blocks before they are ever mounted to the main thread UI.
public final class TextKitCalculator {
    
    // CoreText's internal glyph fallback dictionaries randomly fail under high concurrency
    // so we serialize the actual layout fragment pipeline to maintain safety.
    private static nonisolated(unsafe) var layoutLock = os_unfair_lock_s()
    
    public init() {}
    
    /// Calculates the exact bounding size for a given attributed string constrained to a width.
    ///
    /// - Important: Must only be called on a background thread.
    ///
    /// - Parameters:
    ///   - attributedString: The dynamically typed and themed string to measure.
    ///   - maxWidth: The maximum width of the containing viewport (e.g., the device screen width).
    /// - Returns: The precise `CGSize` necessary to display the text without clipping.
    public func calculateSize(for attributedString: NSAttributedString, constrainedToWidth maxWidth: CGFloat) -> CGSize {
        guard attributedString.length > 0 else { return .zero }
        
        // 1. Core TextKit 2 components internally instantiated to guarantee thread-safety
        let textStorage = NSTextStorage()
        let textContainer = NSTextContainer(size: CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        let layoutManager = NSTextLayoutManager()
        let textContentStorage = NSTextContentStorage()
        
        textContentStorage.addTextLayoutManager(layoutManager)
        layoutManager.textContainer = textContainer
        textContentStorage.textStorage = textStorage
        textContainer.lineFragmentPadding = 0
        
        // 2. Inject the text into the TextKit 2 engine
        textStorage.setAttributedString(attributedString)
        
        // 3. Force layout resolution inside a safety lock to avoid CoreText NSFont proxy crashes
        os_unfair_lock_lock(&Self.layoutLock)
        defer { os_unfair_lock_unlock(&Self.layoutLock) }
        layoutManager.ensureLayout(for: layoutManager.documentRange)
        
        // 4. Extract the exact computed frame
        guard let _ = layoutManager.textLayoutFragment(for: layoutManager.documentRange.location) else {
            return .zero
        }
        
        // Depending on whether it's a single fragment or multiple (wrapping),
        // we take the entire bounding rect of the layout manager.
        let rect = layoutManager.usageBoundsForTextContainer
        
        // We ensure we ceil the values so we never clip half-pixels on Retina screens
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }
}
