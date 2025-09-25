# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-30

### Added
- Initial release of comment_lint package
- Core comment style linting functionality
- Auto-fixing capabilities for comment violations
- Support for intelligent comment rules:
  - Comments should end with periods
  - Uppercase headers should not have periods
  - No periods after colons/commas
  - Multi-line continuation comment handling
- Blank line enforcement between comments and code
- Cross-platform support (Windows, macOS, Linux)
- CI/CD integration with proper exit codes
- Comprehensive CLI with options:
  - `--check` for CI/CD mode
  - `--dry-run` for preview mode
  - `--verbose` for detailed output
- Smart pattern ignoring:
  - Generated files (*.g.dart)
  - License headers
  - TODOs, FIXMEs, URLs
  - Analyzer ignore directives
- Example files and documentation
- Bash script core with Dart CLI wrapper