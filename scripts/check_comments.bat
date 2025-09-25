@echo off
REM Comment Style Checker (CI/CD Mode) - Windows
REM Usage: scripts\check_comments.bat [path] (defaults to lib)
REM Exit code 0: All comments are correctly styled
REM Exit code 1: Comment style issues found

set "PATH_TO_CHECK=%~1"
if "%PATH_TO_CHECK%"=="" set "PATH_TO_CHECK=lib"

echo 🔍 Comment Style Checker (CI/CD Mode)
echo Checking comment style in: %PATH_TO_CHECK%
echo.

dart run comment_lint:comment_lint --set-exit-if-changed -v "%PATH_TO_CHECK%"

REM The exit code is already set by the Dart tool
REM 0 = all good, 1 = issues found