@echo off
REM Comment Style Fixer (FIX MODE) - Windows
REM Usage: scripts\fix_comments_wrapper.bat [path] (defaults to lib)
REM This script WILL modify your files to fix comment style

set "PATH_TO_FIX=%~1"
if "%PATH_TO_FIX%"=="" set "PATH_TO_FIX=lib"

echo 🔧 Comment Style Fixer (FIX MODE)
echo Fixing comment style in: %PATH_TO_FIX%
echo ⚠️  This will modify your files!
echo.

dart run comment_lint:comment_lint -v "%PATH_TO_FIX%"

echo.
echo ✅ Comment style fixing complete!