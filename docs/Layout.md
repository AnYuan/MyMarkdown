# Asynchronous Layout Engine

## Overview
The `MarkdownKit` Layout Engine strictly adheres to the architectural philosophies of Pinterest's Texture (AsyncDisplayKit). Its sole responsibility is measuring text bounds and calculating layout frames entirely off the main thread.

## Components

### `LayoutResult` 
An immutable, tree-structured model holding:
1. The exact bounding box (`CGSize`) for an element relative to a parent width constrain.
2. The pre-styled `NSAttributedString` generated from the `Theme`.
3. An array of children `LayoutResult` objects.

By keeping `LayoutResult` completely detached from UI layers (like `UIView` or `CALayer`), we can traverse millions of nodes in the background safely.

### `TextKitCalculator`
At its core, `TextKitCalculator` wraps Apple's new `TextKit 2` engine (using `NSTextLayoutManager`).
We inject the styled string and a mathematical width boundary `(e.g. 400pt wide)`, and `TextKit 2` generates the precise `usageBoundsForTextContainer` which corresponds to the exact pixel footprint the text will consume when rendered.

### `LayoutSolver`
A recursive tree solver. It visits an AST root (`DocumentNode`), applies the central `Theme` to create attributed strings, relies on `TextKitCalculator` to measure those strings, and packages them into `LayoutResult` trees.

### `LayoutCache`
An `NSCache`-backed memoization utility. 
Because measuring text mathematically is still slightly expensive, we cache the resulting `LayoutResult` models using a composite key of:
`[NodeUUID] + [ViewportWidth]`.
This means resizing the device window or rotating an iPad will trigger a fresh layout, but scrolling up and down is effectively free O(1) instantaneous lookups.
