# MarkdownKit 测试覆盖与执行快照

> 最近更新: 2026-03-04
> 统计口径: 本地仓库静态扫描 + `swift test list` + `swift test`

## 1. 总览

| 指标 | 当前值 | 说明 |
| --- | ---: | --- |
| 源码文件数 (`Sources/MarkdownKit/*.swift`) | 54 | 不含 Demo target |
| 测试文件数 (`Tests/MarkdownKitTests/*.swift`) | 48 | 含基准/夹具/辅助文件 |
| 含 `test*` 方法的测试文件 | 42 | 其余为夹具或辅助代码 |
| 可发现测试数 (`swift test list`) | 218 | 当前平台可执行测试 |
| 全量执行结果 (`swift test`) | 218 执行 / 0 跳过 / 0 失败 | 当前基线已通过 |

补充说明:
- 通过文本扫描统计到的 `test*` 方法数量为 273；该值高于 `swift test list` 的 218，原因是部分方法受平台/编译条件限制，不会在当前运行环境被发现。

## 2. 本次执行状态（2026-03-04）

执行命令:

```bash
swift test
```

汇总结果（修复后复跑）:
- 执行: 218
- 跳过: 0
- 失败: 0
- 总耗时: 约 82.7 秒

历史修复说明:
- 先前失败用例（`SnapshotTests` 下 4 项）已修复。
- 修复方式: 在 macOS 快照测试中固定 `NSAppearance(.aqua)`，消除动态系统外观导致的快照漂移。

## 3. 测试结构分布（按职责）

| 类别 | 文件数 | 代表文件 |
| --- | ---: | --- |
| 解析与 AST | 5 | `MarkdownKitTests.swift`, `ParserInlineFormattingTests.swift`, `CommonMarkSpecTests.swift` |
| 插件链路 | 5 | `ASTPluginTests.swift`, `DetailsExtractionPluginTests.swift`, `GitHubAutolinkPluginTests.swift` |
| 布局与主题 | 8 | `LayoutSolverExtendedTests.swift`, `InlineFormattingLayoutTests.swift`, `ThemeAndTokenTests.swift` |
| UI 与可访问性 | 9 | `UIComponentsPlatformTests.swift`, `MacOSUIComponentsTests.swift`, `iOSAccessibilityTests.swift` |
| 安全与稳健性 | 4 | `URLSanitizerTests.swift`, `DepthLimitTests.swift`, `FuzzTests.swift` |
| 快照回归 | 3 | `SnapshotTests.swift`, `iOSSnapshotTests.swift`, `DiagramSnapshotTests.swift` |
| 性能基准 | 3 | `MarkdownKitBenchmarkTests.swift`, `BenchmarkNodeTypeTests.swift`, `BenchmarkCacheTests.swift` |
| 集成与矩阵 | 5 | `IntegrationPipelineTests.swift`, `SyntaxMatrixTests.swift`, `DiagramLayoutTests.swift` |

非测试用例文件（辅助/夹具）:
- `BenchmarkFixtures.swift`
- `BenchmarkHarness.swift`
- `BenchmarkRegressionGuard.swift`
- `BenchmarkReportFormatter.swift`
- `BenchmarkTieredFixtures.swift`
- `TestHelper.swift`

## 4. 关键结论

1. 测试版图已覆盖解析、插件、布局、UI、安全、基准与集成主链路，结构完整。
2. 当前主链路测试已全绿；快照稳定性问题已收敛。
3. 基准与全量测试默认同跑导致 `swift test` 耗时较长；日常开发建议优先用 `bash scripts/verify_all.sh` 做分组验证。

## 5. 建议后续动作

1. 保持快照环境固定化（外观/字体/尺寸）并在新增快照测试时复用相同约束。
2. 将覆盖文档改为半自动生成: 由 `swift test list` + 文件扫描脚本产出，减少手工维护漂移。
3. 在 CI 中区分“快速回归”与“重基准”两类流水线，避免每次提交都跑完整基准套件。
