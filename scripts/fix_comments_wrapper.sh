#!/bin/bash
# Comment Style Fixer (FIX MODE)
# Usage: ./scripts/fix_comments_wrapper.sh [path] (defaults to lib)
# This script WILL modify your files to fix comment style

PATH_TO_FIX=${1:-lib}

echo "🔧 Comment Style Fixer (FIX MODE)"
echo "Fixing comment style in: $PATH_TO_FIX"
echo "⚠️  This will modify your files!"
echo ""

dart run comment_lint:comment_lint -v "$PATH_TO_FIX"

echo ""
echo "✅ Comment style fixing complete!"