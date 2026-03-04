#!/usr/bin/env bash
# Compares actual test count from `swift test list` against documented values.
# Emits a warning if they differ. Non-destructive; exits 0 even on mismatch.

set -euo pipefail

ACTUAL=$(swift test list 2>/dev/null | grep -c "^MarkdownKitTests\." || true)

KNOWLEDGE_FILE="docs/CodebaseKnowledge.md"
if [[ -f "$KNOWLEDGE_FILE" ]]; then
    DOCUMENTED=$(grep -oP '\*\*\K[0-9]+(?=\*\* discoverable tests)' "$KNOWLEDGE_FILE" 2>/dev/null || echo "?")
    if [[ "$DOCUMENTED" != "?" && "$DOCUMENTED" != "$ACTUAL" ]]; then
        echo "WARNING: $KNOWLEDGE_FILE says $DOCUMENTED tests, actual is $ACTUAL"
    else
        echo "OK: $KNOWLEDGE_FILE test count ($ACTUAL) is current"
    fi
fi

COVERAGE_FILE="docs/TestCoverage.md"
if [[ -f "$COVERAGE_FILE" ]]; then
    DOCUMENTED_COV=$(grep -oP '可发现测试数.*\| \K[0-9]+' "$COVERAGE_FILE" 2>/dev/null || echo "?")
    if [[ "$DOCUMENTED_COV" != "?" && "$DOCUMENTED_COV" != "$ACTUAL" ]]; then
        echo "WARNING: $COVERAGE_FILE says $DOCUMENTED_COV tests, actual is $ACTUAL"
    else
        echo "OK: $COVERAGE_FILE test count ($ACTUAL) is current"
    fi
fi
