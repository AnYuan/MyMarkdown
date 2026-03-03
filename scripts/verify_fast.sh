#!/usr/bin/env bash

set -u
set -o pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

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
run_suite "Critical Plugins" "DetailsExtractionPluginTests|DiagramExtractionPluginTests|MathExtractionPluginTests|GitHubAutolinkPluginTests|MermaidDiagramAdapterTests"
run_suite "Layout Regressions" "LayoutSolverExtendedTests|InlineFormattingLayoutTests|CrossPlatformLayoutTests|iOSTableLayoutTests"
run_suite "Security Hardening" "URLSanitizerTests|DepthLimitTests|FuzzTests"
run_suite "CommonMark Semantics" "CommonMarkSpecTests|ParserInlineFormattingTests|ParserLinkListTableTests"
run_suite "Snapshot Stability" "SnapshotTests|iOSSnapshotTests"

if (( ${#FAILURES[@]} > 0 )); then
  echo
  echo "Fast verification failed. Failed suites:"
  for suite in "${FAILURES[@]}"; do
    echo " - $suite"
  done
  exit 1
fi

echo

echo "Fast verification passed."
