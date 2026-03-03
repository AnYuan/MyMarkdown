#!/usr/bin/env bash

set -u
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

WITH_BENCHMARKS=0

usage() {
  cat <<'EOF'
Usage: bash scripts/verify_all.sh [--with-benchmarks|-b]

Runs the deterministic verification suites used for daily regression checks.
Use --with-benchmarks to include heavier benchmark suites.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --with-benchmarks|-b)
      WITH_BENCHMARKS=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      usage
      exit 2
      ;;
  esac
done

declare -a FAILURES=()

run_suite() {
  local name="$1"
  local filter="$2"

  echo
  echo "============================================================"
  echo "[START] $name"
  echo "Command: swift test --filter \"$filter\""
  echo "============================================================"

  if swift test --filter "$filter"; then
    echo "[PASS] $name"
  else
    echo "[FAIL] $name"
    FAILURES+=("$name")
  fi
}

run_suite "Syntax Matrix" "SyntaxMatrixTests"
run_suite "Critical Plugins" "DetailsExtractionPluginTests|DiagramExtractionPluginTests|MathExtractionPluginTests|GitHubAutolinkPluginTests"
run_suite "Layout Regressions" "LayoutSolverExtendedTests|InlineFormattingLayoutTests|CrossPlatformLayoutTests|iOSTableLayoutTests"
run_suite "Security Hardening" "URLSanitizerTests|DepthLimitTests|FuzzTests"
run_suite "CommonMark Semantics" "CommonMarkSpecTests|ParserInlineFormattingTests|ParserLinkListTableTests"

if [[ "$WITH_BENCHMARKS" -eq 1 ]]; then
  run_suite "Benchmark Full Report" "MarkdownKitBenchmarkTests/testBenchmarkFullReport"
  run_suite "Benchmark Node Deep Report" "BenchmarkNodeTypeTests/testDeepBenchmarkFullReport"
  run_suite "Benchmark Syntax Tiered" "BenchmarkNodeTypeTests/testPerSyntaxTieredBenchmark"
  run_suite "Benchmark Cache" "BenchmarkCacheTests"
else
  echo
  echo "[SKIP] Benchmark suites (pass --with-benchmarks to include them)."
fi

echo
if (( ${#FAILURES[@]} > 0 )); then
  echo "Verification failed. Failed suites:"
  for suite in "${FAILURES[@]}"; do
    echo " - $suite"
  done
  exit 1
fi

echo "Verification passed: all suites completed successfully."
