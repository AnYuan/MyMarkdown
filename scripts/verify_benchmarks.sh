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

run_suite "Benchmark Full Report" "MarkdownKitBenchmarkTests/testBenchmarkFullReport"
run_suite "Benchmark Node Deep Report" "BenchmarkNodeTypeTests/testDeepBenchmarkFullReport"
run_suite "Benchmark Syntax Tiered" "BenchmarkNodeTypeTests/testPerSyntaxTieredBenchmark"
run_suite "Benchmark Cache" "BenchmarkCacheTests"

if (( ${#FAILURES[@]} > 0 )); then
  echo
  echo "Benchmark verification failed. Failed suites:"
  for suite in "${FAILURES[@]}"; do
    echo " - $suite"
  done
  exit 1
fi

echo

echo "Benchmark verification passed."
