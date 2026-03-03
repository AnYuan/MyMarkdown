#!/usr/bin/env python3
"""Generate docs/TestCoverage.md from repository state and test outputs."""

from __future__ import annotations

import argparse
import datetime as dt
import re
import subprocess
from pathlib import Path

TEST_FUNC_RE = re.compile(r"\bfunc\s+test\w*\s*\(")
DISCOVERED_TEST_RE = re.compile(r"^MarkdownKitTests\.")
SUMMARY_RE = re.compile(
    r"Executed\s+(?P<executed>\d+)\s+tests,\s+with\s+(?:(?P<skipped>\d+)\s+test\s+skipped\s+and\s+)?(?P<failures>\d+)\s+failures"
)


def run(cmd: list[str], cwd: Path) -> str:
    proc = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\nstdout:\n{proc.stdout}\nstderr:\n{proc.stderr}"
        )
    return proc.stdout + proc.stderr


def parse_test_summary(text: str) -> tuple[int, int, int] | None:
    matches = list(SUMMARY_RE.finditer(text))
    if not matches:
        return None
    m = matches[-1]
    executed = int(m.group("executed"))
    skipped = int(m.group("skipped") or 0)
    failures = int(m.group("failures"))
    return executed, skipped, failures


def count_test_functions(file_path: Path) -> int:
    text = file_path.read_text(encoding="utf-8")
    return sum(1 for line in text.splitlines() if TEST_FUNC_RE.search(line))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--run-tests",
        action="store_true",
        help="Run `swift test` and use its output for execution summary.",
    )
    parser.add_argument(
        "--from-log",
        type=Path,
        help="Read `swift test` output from an existing log file.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("docs/TestCoverage.md"),
        help="Output markdown file path (default: docs/TestCoverage.md)",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    source_files = sorted((repo_root / "Sources/MarkdownKit").rglob("*.swift"))
    test_files = sorted((repo_root / "Tests/MarkdownKitTests").glob("*.swift"))

    per_file_counts: list[tuple[str, int]] = []
    helper_files: list[str] = []
    total_test_methods = 0
    files_with_tests = 0

    for file in test_files:
        count = count_test_functions(file)
        per_file_counts.append((file.name, count))
        total_test_methods += count
        if count > 0:
            files_with_tests += 1
        else:
            helper_files.append(file.name)

    discover_output = run(["swift", "test", "list"], repo_root)
    discovered_tests = sum(
        1 for line in discover_output.splitlines() if DISCOVERED_TEST_RE.match(line)
    )

    executed = skipped = failures = None
    if args.from_log:
        summary = parse_test_summary(args.from_log.read_text(encoding="utf-8"))
        if summary:
            executed, skipped, failures = summary
    elif args.run_tests:
        test_output = run(["swift", "test"], repo_root)
        summary = parse_test_summary(test_output)
        if summary:
            executed, skipped, failures = summary

    generated_time = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    summary_status = "未提供"
    summary_note = ""
    if executed is not None and skipped is not None and failures is not None:
        summary_status = f"{executed} 执行 / {skipped} 跳过 / {failures} 失败"
        summary_note = "当前基线已通过" if failures == 0 else "存在失败，需处理"

    lines: list[str] = []
    lines.append("# MarkdownKit 测试覆盖与执行快照")
    lines.append("")
    lines.append(f"> 最近更新: {dt.date.today().isoformat()}")
    lines.append(
        "> 生成方式: `python3 scripts/generate_test_coverage_report.py [--run-tests|--from-log <path>]`"
    )
    lines.append(f"> 生成时间: {generated_time}")
    lines.append("")
    lines.append("## 1. 总览")
    lines.append("")
    lines.append("| 指标 | 当前值 | 说明 |")
    lines.append("| --- | ---: | --- |")
    lines.append(
        f"| 源码文件数 (`Sources/MarkdownKit/*.swift`) | {len(source_files)} | 不含 Demo target |"
    )
    lines.append(
        f"| 测试文件数 (`Tests/MarkdownKitTests/*.swift`) | {len(test_files)} | 含基准/夹具/辅助文件 |"
    )
    lines.append(f"| 含 `test*` 方法的测试文件 | {files_with_tests} | 静态扫描结果 |")
    lines.append(
        f"| 静态扫描 `test*` 方法总数 | {total_test_methods} | 受编译条件影响，可能高于可执行测试数 |"
    )
    lines.append(
        f"| 可发现测试数 (`swift test list`) | {discovered_tests} | 当前平台可执行测试 |"
    )
    lines.append(
        f"| 全量执行结果 (`swift test`) | {summary_status} | {summary_note if summary_note else '未执行或未提供日志'} |"
    )
    lines.append("")

    if executed is not None:
        lines.append("## 2. 本次执行状态")
        lines.append("")
        lines.append("- 执行命令: `swift test`")
        lines.append(f"- 执行: {executed}")
        lines.append(f"- 跳过: {skipped}")
        lines.append(f"- 失败: {failures}")
        lines.append("")
    else:
        lines.append("## 2. 本次执行状态")
        lines.append("")
        lines.append("- 未提供 `swift test` 执行结果；可用 `--run-tests` 或 `--from-log` 补充。")
        lines.append("")

    lines.append("## 3. 测试文件明细")
    lines.append("")
    lines.append("| 文件 | `test*` 方法数 |")
    lines.append("| --- | ---: |")
    for name, count in per_file_counts:
        lines.append(f"| `{name}` | {count} |")
    lines.append("")

    lines.append("## 4. 辅助/夹具文件（无 `test*` 方法）")
    lines.append("")
    if helper_files:
        for name in helper_files:
            lines.append(f"- `{name}`")
    else:
        lines.append("- 无")
    lines.append("")

    lines.append("## 5. 建议")
    lines.append("")
    lines.append("1. 日常开发优先使用快速验证入口，减少完整 benchmark 负担。")
    lines.append("2. 每次变更后用该脚本刷新覆盖快照，避免手工统计漂移。")

    output_path = repo_root / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
