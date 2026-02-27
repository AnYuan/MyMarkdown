import Foundation
import Markdown

/// A visitor that traverses the `swift-markdown` syntax tree and converts Apple's C-backed
/// syntax structures into our highly stabilized, thread-safe, and asynchronous-ready `MarkdownNode` models.
public struct MarkdownKitVisitor: MarkupVisitor {
    public typealias Result = [MarkdownNode]
    
    public init() {}
    
    // MARK: - Core Entry Point
    
    public mutating func defaultVisit(_ markup: Markup) -> [MarkdownNode] {
        var children: [MarkdownNode] = []
        for child in markup.children {
            children.append(contentsOf: visit(child))
        }
        return children
    }
    
    public mutating func visitDocument(_ document: Document) -> [MarkdownNode] {
        let children = defaultVisit(document)
        let node = DocumentNode(range: document.range, children: children)
        return [node]
    }
    
    // MARK: - Basic Nodes
    
    public mutating func visitHeading(_ heading: Heading) -> [MarkdownNode] {
        let children = defaultVisit(heading)
        let node = HeaderNode(range: heading.range, level: heading.level, children: children)
        return [node]
    }
    
    public mutating func visitParagraph(_ paragraph: Paragraph) -> [MarkdownNode] {
        let children = defaultVisit(paragraph)
        let node = ParagraphNode(range: paragraph.range, children: children)
        return [node]
    }
    
    public mutating func visitText(_ text: Text) -> [MarkdownNode] {
        let node = TextNode(range: text.range, text: text.string)
        return [node]
    }
    
    // MARK: - Complex Nodes
    
    public mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> [MarkdownNode] {
        let node = CodeBlockNode(range: codeBlock.range,
                                 language: codeBlock.language,
                                 code: codeBlock.code)
        return [node]
    }
    
    public mutating func visitInlineCode(_ inlineCode: InlineCode) -> [MarkdownNode] {
        let node = InlineCodeNode(range: inlineCode.range, code: inlineCode.code)
        return [node]
    }
    
    public mutating func visitImage(_ image: Image) -> [MarkdownNode] {
        let node = ImageNode(range: image.range,
                             source: image.source,
                             altText: image.plainText,
                             title: image.title)
        return [node]
    }
    
    public mutating func visitLink(_ link: Link) -> [MarkdownNode] {
        let children = defaultVisit(link)
        let node = LinkNode(range: link.range,
                            destination: link.destination,
                            title: link.title,
                            children: children)
        return [node]
    }
    
    // MARK: - Lists
    
    public mutating func visitOrderedList(_ orderedList: OrderedList) -> [MarkdownNode] {
        let children = defaultVisit(orderedList)
        let node = ListNode(range: orderedList.range, isOrdered: true, children: children)
        return [node]
    }
    
    public mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> [MarkdownNode] {
        let children = defaultVisit(unorderedList)
        let node = ListNode(range: unorderedList.range, isOrdered: false, children: children)
        return [node]
    }
    
    public mutating func visitListItem(_ listItem: ListItem) -> [MarkdownNode] {
        let children = defaultVisit(listItem)
        let checkboxState: CheckboxState
        switch listItem.checkbox {
        case .checked: checkboxState = .checked
        case .unchecked: checkboxState = .unchecked
        case .none: checkboxState = .none
        }
        let node = ListItemNode(range: listItem.range, checkbox: checkboxState, children: children)
        return [node]
    }
    
    // MARK: - Tables (GFM)
    
    public mutating func visitTable(_ table: Table) -> [MarkdownNode] {
        let children = defaultVisit(table)
        let alignments = table.columnAlignments.map { alignment -> TableAlignment? in
            switch alignment {
            case .left: return .left
            case .right: return .right
            case .center: return .center
            case .none: return .none
            @unknown default: return .none
            }
        }
        let node = TableNode(range: table.range, columnAlignments: alignments, children: children)
        return [node]
    }
    
    public mutating func visitTableHead(_ tableHead: Table.Head) -> [MarkdownNode] {
        let children = defaultVisit(tableHead)
        let node = TableHeadNode(range: tableHead.range, children: children)
        return [node]
    }
    
    public mutating func visitTableBody(_ tableBody: Table.Body) -> [MarkdownNode] {
        let children = defaultVisit(tableBody)
        let node = TableBodyNode(range: tableBody.range, children: children)
        return [node]
    }
    
    public mutating func visitTableRow(_ tableRow: Table.Row) -> [MarkdownNode] {
        let children = defaultVisit(tableRow)
        let node = TableRowNode(range: tableRow.range, children: children)
        return [node]
    }
    
    public mutating func visitTableCell(_ tableCell: Table.Cell) -> [MarkdownNode] {
        let children = defaultVisit(tableCell)
        let node = TableCellNode(range: tableCell.range, children: children)
        return [node]
    }
    
    // MARK: - Inline Formatting

    public mutating func visitEmphasis(_ emphasis: Emphasis) -> [MarkdownNode] {
        let children = defaultVisit(emphasis)
        let node = EmphasisNode(range: emphasis.range, children: children)
        return [node]
    }

    public mutating func visitStrong(_ strong: Strong) -> [MarkdownNode] {
        let children = defaultVisit(strong)
        let node = StrongNode(range: strong.range, children: children)
        return [node]
    }

    public mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> [MarkdownNode] {
        let children = defaultVisit(strikethrough)
        let node = StrikethroughNode(range: strikethrough.range, children: children)
        return [node]
    }

    // MARK: - Block Elements

    public mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> [MarkdownNode] {
        let children = defaultVisit(blockQuote)
        let node = BlockQuoteNode(range: blockQuote.range, children: children)
        return [node]
    }

    public mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> [MarkdownNode] {
        let node = ThematicBreakNode(range: thematicBreak.range)
        return [node]
    }

    public mutating func visitHTMLBlock(_ html: HTMLBlock) -> [MarkdownNode] {
        let node = TextNode(range: html.range, text: html.rawHTML)
        return [node]
    }

    public mutating func visitSoftBreak(_ softBreak: SoftBreak) -> [MarkdownNode] {
        return [TextNode(range: softBreak.range, text: " ")]
    }

    public mutating func visitLineBreak(_ lineBreak: LineBreak) -> [MarkdownNode] {
        return [TextNode(range: lineBreak.range, text: "\n")]
    }

    // MARK: - Math (Extensions)
    
    /// swift-markdown does not support native `Math` elements by default in standard CommonMark.
    /// To support ChatGPT parity (`$$` and `$`), our Custom AST Middleware will usually attach these later by finding specific `TextNode` string patterns.
    /// However, if an extension is added to `swift-markdown` or inline HTML block evaluates to math, we intercept it here.
    public mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> [MarkdownNode] {
        // Simple fallback to convert raw HTML into a Text Node for now.
        // In a complete implementation, this would look for `<math>` tags or `$$` markers.
        let node = TextNode(range: inlineHTML.range, text: inlineHTML.rawHTML)
        return [node]
    }
}
