# MarkdownKit 测试覆盖与执行快照

> 最近更新: 2026-03-04
> 生成方式: `python3 scripts/generate_test_coverage_report.py [--run-tests|--from-log <path>]`
> 生成时间: 2026-03-04 07:04:04

## 1. 总览

| 指标 | 当前值 | 说明 |
| --- | ---: | --- |
| 源码文件数 (`Sources/MarkdownKit/*.swift`) | 54 | 不含 Demo target |
| 测试文件数 (`Tests/MarkdownKitTests/*.swift`) | 48 | 含基准/夹具/辅助文件 |
| 含 `test*` 方法的测试文件 | 42 | 静态扫描结果 |
| 静态扫描 `test*` 方法总数 | 273 | 受编译条件影响，可能高于可执行测试数 |
| 可发现测试数 (`swift test list`) | 218 | 当前平台可执行测试 |
| 全量执行结果 (`swift test`) | 218 执行 / 0 跳过 / 0 失败 | 当前基线已通过 |

## 2. 本次执行状态

- 执行命令: `swift test`
- 执行: 218
- 跳过: 0
- 失败: 0

## 3. 测试文件明细

| 文件 | `test*` 方法数 |
| --- | ---: |
| `ASTPluginTests.swift` | 13 |
| `AsyncCodeViewCopyTests.swift` | 6 |
| `AsyncImageViewLoadingTests.swift` | 5 |
| `AsyncTextViewRenderTests.swift` | 5 |
| `BenchmarkCacheTests.swift` | 2 |
| `BenchmarkFixtures.swift` | 0 |
| `BenchmarkHarness.swift` | 0 |
| `BenchmarkNodeTypeTests.swift` | 7 |
| `BenchmarkRegressionGuard.swift` | 0 |
| `BenchmarkReportFormatter.swift` | 0 |
| `BenchmarkTieredFixtures.swift` | 0 |
| `CommonMarkSpecTests.swift` | 2 |
| `CrossPlatformLayoutTests.swift` | 9 |
| `DepthLimitTests.swift` | 1 |
| `DetailsExtractionPluginTests.swift` | 4 |
| `DiagramExtractionPluginTests.swift` | 3 |
| `DiagramLayoutTests.swift` | 8 |
| `DiagramSnapshotTests.swift` | 1 |
| `EdgeCaseTests.swift` | 13 |
| `FuzzTests.swift` | 1 |
| `GitHubAutolinkPluginTests.swift` | 4 |
| `HighlighterAndProfilerTests.swift` | 7 |
| `InlineFormattingLayoutTests.swift` | 16 |
| `IntegrationPipelineTests.swift` | 10 |
| `LayoutCacheEdgeCaseTests.swift` | 8 |
| `LayoutSolverExtendedTests.swift` | 14 |
| `LayoutTests.swift` | 3 |
| `MacOSUIComponentsTests.swift` | 8 |
| `MarkdownKitBenchmarkTests.swift` | 4 |
| `MarkdownKitTests.swift` | 5 |
| `MathExtractionPluginTests.swift` | 6 |
| `MermaidDiagramAdapterTests.swift` | 3 |
| `NodeModelTests.swift` | 18 |
| `ParserInlineFormattingTests.swift` | 12 |
| `ParserLinkListTableTests.swift` | 11 |
| `SnapshotTests.swift` | 4 |
| `SyntaxMatrixTests.swift` | 1 |
| `TestHelper.swift` | 0 |
| `TextKitCalculatorTests.swift` | 4 |
| `ThemeAndTokenTests.swift` | 8 |
| `UIComponentsPlatformTests.swift` | 11 |
| `UIComponentsTests.swift` | 1 |
| `URLSanitizerTests.swift` | 8 |
| `VirtualizationTests.swift` | 1 |
| `iOSAccessibilityTests.swift` | 8 |
| `iOSSnapshotTests.swift` | 6 |
| `iOSTableLayoutTests.swift` | 7 |
| `iOSThemeDelegateTests.swift` | 5 |

## 4. 辅助/夹具文件（无 `test*` 方法）

- `BenchmarkFixtures.swift`
- `BenchmarkHarness.swift`
- `BenchmarkRegressionGuard.swift`
- `BenchmarkReportFormatter.swift`
- `BenchmarkTieredFixtures.swift`
- `TestHelper.swift`

## 5. 建议

1. 日常开发优先使用快速验证入口，减少完整 benchmark 负担。
2. 每次变更后用该脚本刷新覆盖快照，避免手工统计漂移。
