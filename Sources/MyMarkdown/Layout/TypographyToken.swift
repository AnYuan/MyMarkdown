//
//  TypographyToken.swift
//  MyMarkdown
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias Font = UIFont
#elseif canImport(AppKit)
import AppKit
public typealias Font = NSFont
#endif

/// A token defining the typographic characteristics for a specific Markdown element.
public struct TypographyToken {
    /// The exact font to use, supporting dynamic type scaling out of the box.
    public let font: Font
    
    /// The line height multiplier.
    public let lineHeightMultiple: CGFloat
    
    /// The paragraph spacing after the element.
    public let paragraphSpacing: CGFloat
    
    public init(font: Font, lineHeightMultiple: CGFloat = 1.2, paragraphSpacing: CGFloat = 16.0) {
        self.font = font
        self.lineHeightMultiple = lineHeightMultiple
        self.paragraphSpacing = paragraphSpacing
    }
}
