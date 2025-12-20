#!/bin/bash
set -e

# Configuration
BUILD_DIR="build_coverage"
COVERAGE_DIR="${BUILD_DIR}/coverage_report"
PROFILE_DATA="${BUILD_DIR}/coverage.profdata"

# Check if llvm-profdata and llvm-cov are installed
if ! command -v llvm-profdata &> /dev/null; then
    echo "Error: llvm-profdata not found. Please install LLVM/Clang tools."
    exit 1
fi

if ! command -v llvm-cov &> /dev/null; then
    echo "Error: llvm-cov not found. Please install LLVM/Clang tools."
    exit 1
fi

echo "=== 0. Building Project ==="
# Disable ccache to prevent stale object files causing "mismatched data" warnings in coverage
export CCACHE_DISABLE=1

# Optional: Clean build directory if CLEAN=1 is set
if [ "$CLEAN" = "1" ]; then
    echo "Cleaning build directory ($BUILD_DIR)..."
    rm -rf "$BUILD_DIR"
fi

# Detect cores
CORES=$(command -v nproc >/dev/null 2>&1 && nproc || sysctl -n hw.ncpu)
echo "Using $CORES cores for building and testing..."

if [ ! -d "$BUILD_DIR" ]; then
    cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Coverage -GNinja
fi
cmake --build "$BUILD_DIR" -j "$CORES"

echo "=== 1. Cleaning up old coverage data ==="
find . -name "*.profraw" -type f -delete
rm -f "$PROFILE_DATA"
rm -rf "$COVERAGE_DIR"

echo "=== 2. Running Tests ==="
# Set LLVM_PROFILE_FILE to generate unique .profraw files for each process
# %m expands to the binary signature, %p to PID
export LLVM_PROFILE_FILE="coverage-%m-%p.profraw"

# Run tests via CTest
# Assuming we are in the project root and build directory is 'build'
if [ -d "$BUILD_DIR" ]; then
    cd "$BUILD_DIR"
    ctest --output-on-failure -j "$CORES"
    cd ..
else
    echo "Error: Build directory '$BUILD_DIR' not found. Please build with -DCMAKE_BUILD_TYPE=Coverage first."
    exit 1
fi

echo "=== 3. Merging Profile Data ==="
# Merge all generated .profraw files into one .profdata file
# We look for profraw files in the build directory where tests were run
find "$BUILD_DIR" -name "*.profraw" -print0 | xargs -0 llvm-profdata merge -sparse -o "$PROFILE_DATA"

echo "=== 4. Generating Coverage Report ==="

# Find all test executables to pass to llvm-cov
# We use ctest to get the list of ACTUAL test executables to avoid stale binaries
cd "$BUILD_DIR"
TEST_EXECUTABLES_LIST=$(ctest --show-only=json-v1 | python3 -c "
import sys, json, os
try:
    data = json.load(sys.stdin)
    cmds = set()
    for test in data['tests']:
        if 'command' in test:
            cmd = test['command'][0]
            cmds.add(cmd)
    for cmd in cmds:
        print(cmd)
except Exception as e:
    pass
")
cd ..

TEST_EXECUTABLES=()
while IFS= read -r cmd; do
    if [ -n "$cmd" ]; then
        # Handle relative paths (ctest might return ./test_name)
        if [[ "$cmd" != /* ]]; then
            # Remove leading ./ if present
            cmd="${cmd#./}"
            cmd="$BUILD_DIR/$cmd"
        fi
        
        # Only add if it's a valid file
        if [ -f "$cmd" ]; then
            TEST_EXECUTABLES+=("$cmd")
        fi
    fi
done <<< "$TEST_EXECUTABLES_LIST"

if [ ${#TEST_EXECUTABLES[@]} -eq 0 ]; then
    echo "Error: No test executables found via ctest."
    exit 1
fi

echo "Found test executables: ${TEST_EXECUTABLES[*]}"

# Construct the llvm-cov command
# The first executable is the main argument, others are passed with -object
MAIN_EXECUTABLE="${TEST_EXECUTABLES[0]}"
OBJECT_ARGS=""

for ((i=1; i<${#TEST_EXECUTABLES[@]}; i++)); do
    OBJECT_ARGS="$OBJECT_ARGS -object ${TEST_EXECUTABLES[i]}"
done

# Generate HTML report
# We filter to only show coverage for the 'src' directory and exclude main.cpp
# We also filter out "mismatched data" warnings which can occur with static libraries linked into multiple test executables
llvm-cov show "$MAIN_EXECUTABLE" $OBJECT_ARGS -instr-profile="$PROFILE_DATA" -format=html -output-dir="$COVERAGE_DIR" -ignore-filename-regex="main.cpp|${BUILD_DIR}/|velox/|duckdb/|thirdparty/" src/ 2>&1 | grep -v "mismatched data" || true

# Also print a summary to the terminal
echo "=== Coverage Summary ==="
llvm-cov report "$MAIN_EXECUTABLE" $OBJECT_ARGS -instr-profile="$PROFILE_DATA" -ignore-filename-regex="main.cpp|${BUILD_DIR}/|velox/|duckdb/|thirdparty/" src/ 2>&1 | grep -v "mismatched data" || true

echo ""
echo "✅ Coverage report generated in: $COVERAGE_DIR/index.html"
