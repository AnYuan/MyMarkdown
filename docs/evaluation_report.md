# MarkdownKit 生产级别评估报告

基于先前定义的 6 个核心维度，我对 `MarkdownKit` 当前的代码库（包括 `Sources` 和 `Tests`）进行了盘点。总体而言，`MarkdownKit` 的底子**非常优秀**（特别是架构设计、性能测试和基于 `swift-markdown` / `TextKit` 的核心逻辑）。

但如果要完全对标“绝对安全、零崩溃”的极致 Production 级别，目前仍有以下几个可以重点提升的地方：

## 1. 安全性 (Security) - 🚨 优先级最高
目前代码库中缺乏对恶意负载的防御机制，主要体现在两个方面：

*   **URL/URI 净化 (Sanitization)**
    *   **现状**：在 `LayoutSolver.swift` 的第 452 行和 599 行，处理 `LinkNode` 和 `ImageNode` 时，代码只是简单地通过 `URL(string: dest)` 来构造链接，**没有过滤 `javascript:`、`vbscript:` 等危险协议**。
    *   **风险**：虽然在原生 iOS/macOS 的 `UITextView/NSTextView` 中直接点击 `javascript:` 链接默认不会执行代码，但如果上层业务拦截了点击事件并通过 WebView 处理，或者对图片触发了危险的网络请求，就可能产生漏洞。
    *   **改进**：引入一个专门的 `Sanitizer` 组件或者默认拒绝非 HTTP/HTTPS/Mailto 等安全协议的策略。
*   **最大嵌套深度限制 (Nesting Limits / Stack Overflow 防御)**
    *   **现状**：`swift-markdown` 底层 (cmark) 能防住大部分正则回溯，但在 `MarkdownKit` 自己的 AST Plugin（如 `DetailsExtractionPlugin`）和 `LayoutSolver` 中的递归遍历时，并没有设置最大深度阈值（如 maxDepth = 100）。
    *   **风险**：如果攻击者输入数万层嵌套的 `[[[[...` 或引用区块 `>>>>...`，你的 Swift 递归函数会耗尽调用栈从而导致线程 Crash (Stack Overflow)。

## 2. 鲁棒性与工程质量 (Robustness)
*   **缺乏模糊测试 (Fuzz Testing)**
    *   **现状**：测试目录（`Tests/MarkdownKitTests`）非常丰富，包含了大量的基准测试 (`Benchmark`) / 边界测试（`EdgeCaseTests`），这说明工程质量已经很高。但并未发现 Fuzz 测试的身影。
    *   **改进**：可以引入 `libFuzzer` 或类似工具，不断扔随机乱码和极端符号组合给 `MarkdownKitVisitor` 和 `LayoutSolver`。只要长时间跑不出一例 Panic/Crash，才能真正向业务方拍胸脯保证“随便输，绝不崩”。

## 3. 规范兼容性落地 (Visual Spec Compliance)
*   **缺乏 UI 渲染层的快照测试 (Snapshot Testing)**
    *   **现状**：由于你底层使用了 `swift-markdown`，你的 AST 解析（分词层面）是 100% 兼容 CommonMark/GFM 的。但是，在 `UIComponentsPlatformTests` 和 `LayoutTests` 中，主要测试的是 Attributes（字体、颜色、排版属性）是否正确生成。
    *   **风险**：复杂的排版组合（如：表格里面嵌一个含有 Math 块的任务列表），你的 `LayoutSolver` 可能计算出来的排版是错乱的。
    *   **改进**：引入 `swift-snapshot-testing` 库。基于 CommonMark 的官方测试集，把渲染出来的最终 `UIView`/`NSView` 保存成参考图片。只要后续改动导致像素级差异，CI 当场报错。

## 4. 架构扩展性 (Architecture)
架构（AST分离 -> 插件 -> Layout）已经做得很完美了。唯一可以更进一步的是：
*   **Renderer 抽象层**：目前 `LayoutSolver` 貌似深度绑定了 `NSAttributedString`（TextKit）。如果在未来你的雄心不满足于 TextKit，还想输出到原生的 SwiftUI `Text` 或直接输出为 HTML，可能需要在 `LayoutSolver` 之上再抽象一层 `Renderer` 协议。

---
**总结下一步（Todo 建议）**：
1. **[Quick Win]** 在处理 Link 和 Image 的 URL 构造时，加个安全前缀过滤：如果是含有 `javascript:` 闭包或其它脏数据的 URI，直接处理为 `nil` 或 `#`。
2. **[Quick Win]** 在 `MarkdownKitVisitor.defaultVisit` 以及布局递归求解中抛出一个内部计数器，查过深度阀值（如 50 层）直接截断，丢弃深层级子树。
3. 把快照测试和 Fuzz 测试提上未来日程。
