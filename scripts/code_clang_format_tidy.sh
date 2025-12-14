#!/bin/bash
set -euo pipefail

# Ensure we are running from the repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Script to check uncommitted C++ code for formatting and linting issues.
# - Runs clang-format -i to fix formatting.
# - Runs clang-tidy to check for linting errors.

# Define ignored directories (regex for grep -E)
IGNORE_PATTERN="^(thirdparty/|build/|velox/|duckdb/)"

# Check for required tools
if ! command -v clang-format &> /dev/null; then
    echo "Error: clang-format is not installed."
    exit 1
fi

if ! command -v clang-tidy &> /dev/null; then
    echo "Error: clang-tidy is not installed."
    exit 1
fi

# Check for compile_commands.json
if [ ! -f "build/compile_commands.json" ]; then
    echo "Warning: build/compile_commands.json not found. clang-tidy requires a compilation database."
    echo "Please run cmake to generate it (e.g., cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON)."
    echo "Skipping clang-tidy check."
    RUN_TIDY=false
else
    RUN_TIDY=true
fi

# Get list of uncommitted C/C++ files (staged and unstaged)
echo "Detecting uncommitted C/C++ files..."
FILES=$(git diff --name-only HEAD 2>/dev/null || true)
STAGED_FILES=$(git diff --name-only --cached 2>/dev/null || true)
ALL_FILES=$(echo -e "$FILES\n$STAGED_FILES" | sort -u)

# Filter files
FILES_TO_CHECK=()
while IFS= read -r f; do
    [ -z "$f" ] && continue
    
    # Check if file exists (it might have been deleted)
    if [ ! -f "$f" ]; then
        continue
    fi

    # Check ignore pattern
    if [[ "$f" =~ $IGNORE_PATTERN ]]; then
        continue
    fi

    # Check extension
    case "$f" in
        *.c|*.cc|*.cpp|*.cppm|*.cxx|*.h|*.hpp|*.hh|*.hxx)
            FILES_TO_CHECK+=("$f")
            ;;
    esac
done <<< "$ALL_FILES"

if [ ${#FILES_TO_CHECK[@]} -eq 0 ]; then
    echo "No uncommitted C/C++ files to check."
    exit 0
fi

echo "Files to check:"
for f in "${FILES_TO_CHECK[@]}"; do
    echo "  $f"
done

# Run clang-format
echo "--------------------------------------------------"
echo "Running clang-format..."
FORMAT_ISSUES=0
for f in "${FILES_TO_CHECK[@]}"; do
    # Check if formatting changes anything
    if ! clang-format -style=file -output-replacements-xml "$f" | grep -q "<replacement "; then
        # No changes needed
        continue
    else
        echo "Formatting $f..."
        clang-format -i -style=file "$f"
        FORMAT_ISSUES=1
    fi
done

if [ $FORMAT_ISSUES -eq 1 ]; then
    echo "Formatting fixed."
else
    echo "Formatting OK."
fi

# Run clang-tidy
if [ "$RUN_TIDY" = true ]; then
    echo "--------------------------------------------------"
    echo "Running clang-tidy..."
    
    if command -v run-clang-tidy &> /dev/null; then
        # Use run-clang-tidy for parallel execution
        # Note: run-clang-tidy takes regexes as arguments. We escape dots to be safe, 
        # though usually file paths work fine as regexes.
        # We do not pass -header-filter here, relying on .clang-tidy configuration.
        
        # Construct regex for files
        # We can pass each file as a separate argument, run-clang-tidy handles them.
        echo "Using run-clang-tidy..."
        if ! run-clang-tidy -p build -quiet "${FILES_TO_CHECK[@]}"; then
             echo "clang-tidy reported issues."
             exit 1
        fi
    else
        # Fallback to sequential execution
        TIDY_FAILED=0
        for f in "${FILES_TO_CHECK[@]}"; do
            echo "Checking $f..."
            # We do not pass -header-filter here, relying on .clang-tidy configuration.
            if ! clang-tidy -p build -quiet "$f"; then
                echo "Error: clang-tidy reported issues in $f"
                TIDY_FAILED=1
            fi
        done

        if [ $TIDY_FAILED -eq 1 ]; then
            echo "--------------------------------------------------"
            echo "clang-tidy check FAILED. Please fix the reported issues."
            exit 1
        else
            echo "clang-tidy check PASSED."
        fi
    fi
fi

exit 0
