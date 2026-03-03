//
//  ColorToken.swift
//  MarkdownKit
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias Color = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias Color = NSColor
#endif

extension Color {
    /// Cross-platform secondary label color.
    static var platformSecondaryLabel: Color {
        #if canImport(UIKit)
        return .secondaryLabel
        #elseif canImport(AppKit)
        return .secondaryLabelColor
        #endif
    }
}

/// A token defining the color characteristics for a specific Markdown element.
/// Fully supports Light/Dark mode transitions on both iOS and macOS natively.
public struct ColorToken {
    /// The text foreground color.
    public let foreground: Color
    
    /// The background color (e.g. for code blocks).
    public let background: Color
    
    public init(foreground: Color, background: Color = .clear) {
        self.foreground = foreground
        self.background = background
    }
}
