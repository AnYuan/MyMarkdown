//
//  LayoutResult.swift
//  MarkdownKit
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A strictly immutable struct carrying the pre-calculated bounding box, sizing, and
/// rendering instructions for a specific Markdown Node.
///
/// This is heavily inspired by Texture's (AsyncDisplayKit) `ASLayout` node models.
/// By calculating this solely on a background thread, our Collection Views (iOS/macOS)
/// can query `.frame` instantaneously in `sizeForItem` without triggering TextKit
/// layout passes on the Main Thread.
public struct LayoutResult {
    /// The specific node this layout represents.
    public let node: MarkdownNode

    /// The exact, calculated dimensions `(width, height)`.
    public let size: CGSize

    /// The pre-calculated string properties if applicable (already styled with Themes).
    /// Rendering this string asynchronously off the main thread is Phase 3.
    public let attributedString: NSAttributedString?

    /// Any children layouts (e.g. nested lists).
    public let children: [LayoutResult]

    /// Optional custom drawing closure for nodes that bypass TextKit rendering
    /// (e.g. table cards drawn directly via CGContext). When present, `AsyncTextView`
    /// calls this instead of the default `NSLayoutManager` draw path.
    public let customDraw: (@Sendable (CGContext, CGSize) -> Void)?

    public init(
        node: MarkdownNode,
        size: CGSize,
        attributedString: NSAttributedString? = nil,
        children: [LayoutResult] = [],
        customDraw: (@Sendable (CGContext, CGSize) -> Void)? = nil
    ) {
        self.node = node
        self.size = size
        self.attributedString = attributedString
        self.children = children
        self.customDraw = customDraw
    }
}
