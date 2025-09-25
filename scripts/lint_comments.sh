#!/bin/bash
# Comment Linter Core Script
# This script is called by the Dart CLI but contains the core linting logic

target="${1:-lib/}"
violations=0
files_checked=0
verbose=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose)
            verbose=true
            ;;
    esac
done

# Clean header
echo "Comment Lint (Check Mode)"
if [[ "$verbose" == true ]]; then
    echo "========================="
    echo "Target: $target"
fi
echo ""

should_ignore_line() {
    local line="$1"

    # Skip empty comments (/// or // with no content)
    [[ "$line" =~ ^[[:space:]]*///[[:space:]]*$ ]] && return 0
    [[ "$line" =~ ^[[:space:]]*//[[:space:]]*$ ]] && return 0

    # Check if this is an uppercase header comment (e.g., "// MOVIE METHODS")
    local content="${line#*//}"
    [[ "$content" =~ ^/ ]] && content="${content#/}"
    content="${content# }"
    content="${content%$'\r'}"  # Strip Windows line endings

    # Skip if content is all uppercase letters and spaces (section headers)
    if [[ -n "$content" ]] && [[ "$content" =~ ^[A-Z][A-Z\ ]+$ ]]; then
        return 0
    fi

    case "$line" in
        *"// ignore:"*) return 0 ;;  # Skip Dart analyzer ignore directives
        *"TODO:"*|*"FIXME:"*|*"NOTE:"*|*"Time-stamp:"*|*"https://"*|*"http://"*) return 0 ;;
        *"This program is free software"*|*"the terms of the GNU General Public License"*) return 0 ;;
        *"Foundation, either version"*|*"This program is distributed in the hope"*) return 0 ;;
        *"ANY WARRANTY; without even the implied warranty"*|*"FOR A PARTICULAR PURPOSE"*) return 0 ;;
        *"You should have received a copy of the GNU General Public License"*) return 0 ;;
        *"version."*|*"details."*) return 0 ;;
        *"Copyright (C)"*|*"Licensed under the GNU General Public License"*|*"Authors:"*) return 0 ;;
        *"License:"*|*"this program"*|*"see <https://www.gnu.org/licenses/"*) return 0 ;;
    esac
    return 1
}

lint_file() {
    local file_path="$1"
    [[ "$file_path" =~ \.g\.dart$ ]] && return 0
    [[ ! -f "$file_path" ]] && return 0

    local file_violations=0
    local line_num=1
    local prev_line=""
    local prev_was_comment=false
    local prev_was_ignore=false
    local next_line=""

    # Read file into array for lookahead capability
    mapfile -t lines < "$file_path"
    local total_lines=${#lines[@]}

    for ((i=0; i<total_lines; i++)); do
        local line="${lines[$i]}"
        line_num=$((i+1))
        local is_comment=false

        # Get next line for continuation check (if exists)
        if [[ $((i+1)) -lt $total_lines ]]; then
            next_line="${lines[$((i+1))]}"
        else
            next_line=""
        fi

        # Get previous line for current-line-is-continuation check (if exists)
        local prev_line_for_continuation=""
        if [[ $i -gt 0 ]]; then
            prev_line_for_continuation="${lines[$((i-1))]}"
        fi

        # Optimized comment detection - check // first, then ///
        if [[ "$line" =~ ^[[:space:]]*// ]]; then
            is_comment=true

            # Check if this is an ignore directive
            if [[ "$line" =~ "// ignore:" ]]; then
                prev_was_ignore=true
            else
                prev_was_ignore=false
            fi

            # Extract comment content for checking
            local content="${line#*//}"
            [[ "$content" =~ ^/ ]] && content="${content#/}"
            content="${content# }"
            # Strip Windows line endings for consistent checking
            content="${content%$'\r'}"

            # Check if this is an uppercase header (with or without period)
            # Must be ALL uppercase letters and spaces, no lowercase allowed
            # Require at least 2 characters total
            if [[ -n "$content" ]] && [[ ${#content} -ge 2 ]] && [[ "$content" =~ ^[A-Z][A-Z\ ]*[.]?$ ]] && [[ "$content" == "${content^^}" ]]; then
                # For uppercase headers, check they DON'T have a period
                if [[ "$content" =~ [.]$ ]]; then
                    echo "  Line $line_num: Uppercase header should not have period: $line"
                    ((file_violations++))
                fi
            elif ! should_ignore_line "$line"; then
                # Check if comment ends with : or , followed by period (incorrect)
                # But skip docstring patterns like "/// Parameters:" or "/// Returns:"
                if [[ "$content" =~ [,:]\.$  ]] && [[ ! "$content" =~ ^(Parameters|Returns|Usage\ examples): ]]; then
                    echo "  Line $line_num: Comment should not have period after colon/comma: $line"
                    ((file_violations++))
                # Check if comment ends with : or , (list/continuation indicators)
                elif [[ "$content" =~ [,:]$ ]]; then
                    # Don't require period for comments ending in : or ,
                    :
                # Check if current line is a continuation of previous comment
                elif [[ -n "$prev_line_for_continuation" ]] && [[ "$prev_line_for_continuation" =~ ^[[:space:]]*// ]] && [[ "$content" =~ ^[a-z0-9-] ]]; then
                    # Don't require period for continuation comments (current line starts with lowercase)
                    :
                # Check if next line is a continuation comment (starts with lowercase or number)
                elif [[ -n "$next_line" ]] && [[ "$next_line" =~ ^[[:space:]]*// ]]; then
                    local next_content="${next_line#*//}"
                    [[ "$next_content" =~ ^/ ]] && next_content="${next_content#/}"
                    next_content="${next_content# }"
                    # If next comment starts with lowercase, number, or dash (list item), this is a multi-line comment
                    if [[ "$next_content" =~ ^[a-z0-9-] ]]; then
                        # Don't require period for continuation comments
                        :
                    elif [[ -n "$content" ]] && [[ ! "$content" =~ [.!?]$ ]]; then
                        echo "  Line $line_num: Comment missing period: $line"
                        ((file_violations++))
                    fi
                # For regular single-line comments, check for missing period
                elif [[ -n "$content" ]] && [[ ! "$content" =~ [.!?]$ ]]; then
                    echo "  Line $line_num: Comment missing period: $line"
                    ((file_violations++))
                fi
            fi
            prev_was_comment=true
        else
            # Check for missing blank line after comment (but NOT after ignore directives)
            if [[ "$prev_was_comment" == true ]] && [[ "$prev_was_ignore" == false ]] &&
               [[ -n "$line" ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]] &&
               [[ ! "$line" =~ ^[[:space:]]*// ]]; then
                if [[ -n "$prev_line" ]] && [[ ! "$prev_line" =~ ^[[:space:]]*$ ]]; then
                    echo "  Line $line_num: Missing blank line after comment"
                    ((file_violations++))
                fi
            fi
            prev_was_comment=false
            prev_was_ignore=false
        fi

        prev_line="$line"
    done

    violations=$((violations + file_violations))
    ((files_checked++))

    # Only show output if violations found or in verbose mode
    if [[ $file_violations -gt 0 ]]; then
        echo "FAIL: $file_path"
        echo "  Found $file_violations violation(s)"
    elif [[ "$verbose" == true ]]; then
        echo "PASS: $file_path"
        echo "  No violations found"
    fi
}

# Process target - use faster for loop instead of pipeline
if [[ -f "$target" ]]; then
    lint_file "$target"
elif [[ -d "$target" ]]; then
    [[ "$verbose" == true ]] && echo "Scanning: $target"
    for dart_file in $(find "$target" -name "*.dart" ! -name "*.g.dart" 2>/dev/null); do
        [[ -f "$dart_file" ]] && lint_file "$dart_file"
    done
else
    echo "Error: Target '$target' not found"
    exit 1
fi

echo ""
echo "Summary:"
echo "========"
if [[ "$verbose" == true ]]; then
    echo "Files checked: $files_checked"
fi
if [[ $violations -eq 0 ]]; then
    echo "No comment style violations found!"
else
    echo "Found $violations violation(s) in $files_checked file(s)"
    echo ""
    echo "Run 'dart run comment_lint --fix' to automatically fix these issues"
fi

[[ $violations -eq 0 ]] && exit 0 || exit 1