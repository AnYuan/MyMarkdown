import Foundation

/// An ASTPlugin that scans TextNode content for LaTeX math patterns
/// (`$...$` for inline, `$$...$$` for block) and replaces them with MathNode instances.
public struct MathExtractionPlugin: ASTPlugin {

    public init() {}

    public func visit(_ nodes: [MarkdownNode]) -> [MarkdownNode] {
        // First pass: merge block math ($$..$$) that spans multiple nodes
        let merged = mergeBlockMath(nodes)

        // Second pass: extract inline math ($...$) within paragraphs
        var result: [MarkdownNode] = []
        for node in merged {
            if let paragraph = node as? ParagraphNode {
                let newChildren = processInlineChildren(paragraph.children)
                result.append(ParagraphNode(range: paragraph.range, children: newChildren))
            } else if let header = node as? HeaderNode {
                let newChildren = processInlineChildren(header.children)
                result.append(HeaderNode(range: header.range, level: header.level, children: newChildren))
            } else {
                result.append(node)
            }
        }
        return result
    }

    /// Scans top-level nodes for $$ patterns that span across paragraphs.
    /// e.g., Paragraph("$$"), Paragraph("\frac{1}{2}"), Paragraph("$$") → MathNode(.block)
    private func mergeBlockMath(_ nodes: [MarkdownNode]) -> [MarkdownNode] {
        var result: [MarkdownNode] = []
        var index = 0

        while index < nodes.count {
            let node = nodes[index]

            // Check if this paragraph starts with $$
            if let text = extractPlainText(from: node), text.trimmingCharacters(in: .whitespaces).hasPrefix("$$") {
                let fullText = text.trimmingCharacters(in: .whitespacesAndNewlines)

                // Case 1: $$ equation $$ all in one paragraph
                if fullText.hasPrefix("$$") && fullText.hasSuffix("$$") && fullText.count > 4 {
                    let equation = String(fullText.dropFirst(2).dropLast(2))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    result.append(MathNode(range: nil, style: .block, equation: equation))
                    index += 1
                    continue
                }

                // Case 2: $$ on its own line, equation on next line(s), $$ closing
                if fullText == "$$" {
                    var equationParts: [String] = []
                    var searchIdx = index + 1
                    var found = false

                    while searchIdx < nodes.count {
                        let nextText = extractPlainText(from: nodes[searchIdx])?
                            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                        if nextText == "$$" {
                            let equation = equationParts.joined(separator: "\n")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            result.append(MathNode(range: nil, style: .block, equation: equation))
                            index = searchIdx + 1
                            found = true
                            break
                        }
                        equationParts.append(nextText)
                        searchIdx += 1
                    }

                    if found { continue }
                }
            }

            result.append(node)
            index += 1
        }
        return result
    }

    /// Extracts all plain text from a node's inline children.
    private func extractPlainText(from node: MarkdownNode) -> String? {
        if let para = node as? ParagraphNode {
            return para.children.compactMap { child -> String? in
                if let text = child as? TextNode { return text.text }
                return nil
            }.joined()
        }
        return nil
    }

    private func processInlineChildren(_ children: [MarkdownNode]) -> [MarkdownNode] {
        var result: [MarkdownNode] = []
        for child in children {
            if let text = child as? TextNode {
                result.append(contentsOf: extractInlineMath(from: text))
            } else {
                result.append(child)
            }
        }
        return result
    }

    private func extractInlineMath(from textNode: TextNode) -> [MarkdownNode] {
        let text = textNode.text
        var result: [MarkdownNode] = []
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            // Look for inline math ($...$) — skip $$ which is block
            if let dollarRange = remaining.range(of: "$") {
                // Skip if this is $$ (block delimiter)
                let afterDollar = remaining[dollarRange.upperBound...]
                if afterDollar.hasPrefix("$") {
                    result.append(TextNode(range: nil, text: String(remaining)))
                    return result
                }

                let prefix = remaining[remaining.startIndex..<dollarRange.lowerBound]
                if !prefix.isEmpty {
                    result.append(TextNode(range: nil, text: String(prefix)))
                }

                if let closeRange = afterDollar.range(of: "$") {
                    let equation = String(afterDollar[afterDollar.startIndex..<closeRange.lowerBound])
                    if !equation.isEmpty && !equation.contains("\n") {
                        result.append(MathNode(range: nil, style: .inline, equation: equation))
                        remaining = afterDollar[closeRange.upperBound...]
                        continue
                    }
                }

                // No valid closing $
                result.append(TextNode(range: nil, text: String(remaining)))
                return result
            }

            result.append(TextNode(range: nil, text: String(remaining)))
            return result
        }

        return result
    }
}
