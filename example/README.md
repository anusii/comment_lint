# Comment Lint Examples

This directory contains example files demonstrating proper and improper comment formatting.

## Files

- `lib/good_comments.dart` - Examples of properly formatted comments
- `lib/bad_comments.dart` - Examples that will be flagged by the linter

## Testing the Linter

### Check comment style:
```bash
# From the example directory
dart run comment_lint --check lib

# Or from the parent directory
dart run comment_lint --check example/lib
```

### Fix comment style:
```bash
# Preview changes
dart run comment_lint --dry-run lib

# Apply fixes
dart run comment_lint lib
```

## Expected Output

Running the linter on `bad_comments.dart` should find several violations:
- Uppercase header with period
- Missing periods on comments
- Missing blank lines after comments
- Incorrect periods after colons

Running the linter on `good_comments.dart` should find no violations.