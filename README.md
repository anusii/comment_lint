[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub License](https://img.shields.io/github/license/anusii/comment_lint)](https://raw.githubusercontent.com/anusii/comment_lint/main/LICENSE)
[![Pub Version](https://img.shields.io/pub/v/comment_lint?label=pub.dev&labelColor=333940&logo=flutter)](https://pub.dev/packages/comment_lint)

# Comment Lint

A comment style linting and auto-fixing tool for Dart and Flutter projects that enforces consistent comment formatting across your codebase.

The package is published on [pub.dev](https://pub.dev/packages/comment_lint).

## Features

- 🔧 **Enforces consistent comment style** across your Dart/Flutter project
- 📝 **Intelligent comment rules**:
  - Comments should end with periods (for readability)
  - Uppercase headers (e.g., `// MOVIE METHODS`) should not have periods
  - No periods after colons or commas in comments
  - Smart handling of multi-line continuation comments
- 📏 **Proper spacing** - Ensures blank lines between comments and code
- 🎯 **Smart ignoring** - Skips generated files, license headers, TODOs, and URLs
- 🔍 **Auto-fixing** - Can automatically fix violations or just report them
- ✅ **CI/CD ready** - Exit codes for automated pipelines
- 🚀 **Cross-platform** - Works on Windows, macOS, and Linux

## Installation

Install as a global executable:

```bash
dart pub global activate comment_lint
```

Or add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  comment_lint: ^0.1.0
```

## 🎯 Quick Start

### Check comment style (CI/CD mode):
```bash
# Check lib directory
dart run comment_lint --check

# Check specific directories
dart run comment_lint --check lib test

# For CI/CD (returns exit code 1 if issues found)
dart run comment_lint --set-exit-if-changed lib
```

### Fix comment style:
```bash
# Fix lib directory
dart run comment_lint

# Fix specific directories
dart run comment_lint lib test

# Preview changes without applying them
dart run comment_lint --dry-run
```

### Global installation usage:
```bash
# After: dart pub global activate comment_lint
comment_lint --check lib
comment_lint lib  # to fix
```

## Comment Style Rules

### ✅ Good Examples:
```dart
// This is a proper comment with a period.

// MOVIE METHODS  (uppercase headers don't need periods)

// This is a list item:
// - First item
// - Second item

// Multi-line comments are handled intelligently,
// where continuation lines don't need periods.

/// Documentation comments work too.
```

### ❌ Bad Examples:
```dart
// Missing period

// UPPERCASE HEADER.  (should not have period)

// Wrong after colon:.

// No blank line before code
void someFunction() {}
```

## CLI Options

| Option | Description |
|--------|-------------|
| `--check`, `-c` | Check comment style without fixing |
| `--set-exit-if-changed` | Return exit code 1 if changes needed (for CI/CD) |
| `--dry-run` | Preview what would be changed without applying |
| `--verbose`, `-v` | Show detailed output |
| `--help`, `-h` | Show help information |

## CI/CD Integration

Add to your GitHub Actions workflow:

```yaml
- name: Check comment style
  run: dart run comment_lint --set-exit-if-changed
```

Or in your `Makefile`:

```makefile
lint-comments:
	dart run comment_lint --set-exit-if-changed lib test

fix-comments:
	dart run comment_lint lib test
```

## How It Works

The tool uses a hybrid approach:
- **Dart CLI** for cross-platform compatibility and argument parsing
- **Bash scripts** for the core text processing logic (fast and reliable)
- **Smart detection** for various comment patterns and edge cases

### Ignored Patterns

The linter automatically ignores:
- Generated files (`*.g.dart`)
- License headers and copyright notices
- Analyzer ignore directives (`// ignore:`)
- TODOs, FIXMEs, and NOTEs
- URLs and hyperlinks
- Empty comments

### Multi-line Comment Handling

The tool intelligently detects continuation comments:

```dart
// This is a multi-line comment that explains something complex,
// and this line doesn't need a period because it continues.
// But this final line does need a period.

void someCode() {}  // Blank line added automatically
```

## Examples

### Basic Usage:
```bash
# Check comment style in default lib directory
dart run comment_lint --check

# Fix comment style in lib and test directories
dart run comment_lint lib test

# Preview changes without applying
dart run comment_lint --dry-run lib
```

### Advanced Usage:
```bash
# Verbose output for debugging
dart run comment_lint --verbose --check lib

# Use in CI/CD pipeline
dart run comment_lint --set-exit-if-changed lib test
if [ $? -ne 0 ]; then
    echo "Comment style issues found!"
    exit 1
fi
```

## Development

### Running Tests:
```bash
cd comment_lint
dart test
```

### Contributing:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Related Projects

- [import_order_lint](https://pub.dev/packages/import_order_lint) - Import ordering linter
- [dart format](https://dart.dev/tools/dart-format) - Official Dart formatter

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.