#!/bin/bash
# Comment Style Checker (CI/CD Mode)
# Usage: ./scripts/check_comments.sh [path] (defaults to lib)
# Exit code 0: All comments are correctly styled
# Exit code 1: Comment style issues found

PATH_TO_CHECK=${1:-lib}

echo "🔍 Comment Style Checker (CI/CD Mode)"
echo "Checking comment style in: $PATH_TO_CHECK"
echo ""

dart run comment_lint:comment_lint --set-exit-if-changed -v "$PATH_TO_CHECK"

# The exit code is already set by the Dart tool
# 0 = all good, 1 = issues found