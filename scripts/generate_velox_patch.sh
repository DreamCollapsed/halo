#!/bin/bash

# Script to generate Velox patch file for the project
# Usage: ./scripts/generate_velox_patch.sh

set -e

# Function to find project root by looking for characteristic files
find_project_root() {
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Look for project root indicators (CMakeLists.txt, .git directory, velox subdirectory)
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/CMakeLists.txt" ] && [ -d "$current_dir/velox" ] && [ -d "$current_dir/cmake" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    
    # If not found, try current working directory
    if [ -f "CMakeLists.txt" ] && [ -d "velox" ] && [ -d "cmake" ]; then
        pwd
        return 0
    fi
    
    echo "Error: Could not find project root. Please run from project directory or ensure the script can locate CMakeLists.txt, velox/, and cmake/ directories." >&2
    exit 1
}

# Define paths
PROJECT_ROOT="$(find_project_root)"
PATCH_DIR="$PROJECT_ROOT/cmake/patches"
PATCH_FILE="$PATCH_DIR/velox.patch"

echo "=== Velox Patch Generator ==="
echo "Project root: $PROJECT_ROOT"
echo "Patch file: $PATCH_FILE"

# Remove existing patch file if it exists
if [ -f "$PATCH_FILE" ]; then
    rm -f "$PATCH_FILE"
fi

# Check if there are unstaged changes and untracked files in velox directory
# Since velox is a submodule with ignore=all, we need to check inside the submodule
cd "$PROJECT_ROOT/velox"
VELOX_UNSTAGED_FILES=$(git diff --name-only | grep -v '\.velox_patched$' || true)
VELOX_UNTRACKED_FILES=$(git ls-files --others --exclude-standard | grep -v '\.velox_patched$' || true)
VELOX_STAGED_FILES=$(git diff --cached --name-only | grep -v '\.velox_patched$' || true)
cd "$PROJECT_ROOT"

if [ -n "$VELOX_UNSTAGED_FILES" ] || [ -n "$VELOX_UNTRACKED_FILES" ]; then
    if [ -n "$VELOX_UNSTAGED_FILES" ]; then
        echo "Found unstaged changes in velox directory:"
        echo "$VELOX_UNSTAGED_FILES" | sed 's/^/  velox\//'
    fi
    
    if [ -n "$VELOX_UNTRACKED_FILES" ]; then
        echo "Found untracked files in velox directory:"
        echo "$VELOX_UNTRACKED_FILES" | sed 's/^/  velox\//'
    fi
    
    echo "Auto-staging velox changes (excluding .velox_patched files)..."
    
    # Stage all velox changes except .velox_patched files
    cd "$PROJECT_ROOT/velox"
    
    # Stage modified files
    if [ -n "$VELOX_UNSTAGED_FILES" ]; then
        echo "$VELOX_UNSTAGED_FILES" | while IFS= read -r file; do
            if [ -n "$file" ]; then
                echo "  Staging modified: velox/$file"
                git add "$file"
            fi
        done
    fi
    
    # Stage untracked files
    if [ -n "$VELOX_UNTRACKED_FILES" ]; then
        echo "$VELOX_UNTRACKED_FILES" | while IFS= read -r file; do
            if [ -n "$file" ]; then
                echo "  Staging new file: velox/$file"
                git add "$file"
            fi
        done
    fi
    
    cd "$PROJECT_ROOT"
    
    echo "✅ Velox changes have been staged"
    echo ""
fi

# Check if there are any staged changes (after potential auto-staging)
cd "$PROJECT_ROOT/velox"
VELOX_STAGED_FILES=$(git diff --cached --name-only | grep -v '\.velox_patched$' || true)
cd "$PROJECT_ROOT"

if [ -n "$VELOX_STAGED_FILES" ]; then
    echo "Found staged Velox changes:"
    echo "$VELOX_STAGED_FILES" | sed 's/^/  velox\//'
    echo ""
    echo "Generating patch from staged changes..."
    
    # Generate patch from velox submodule excluding .velox_patched files
    cd "$PROJECT_ROOT/velox"
    git diff --cached --binary -- ':!*.velox_patched' ':!**/.velox_patched' > "$PATCH_FILE"
    cd "$PROJECT_ROOT"
    
    # Verify patch file was created and is not empty
    if [ -f "$PATCH_FILE" ] && [ -s "$PATCH_FILE" ]; then
        echo "Successfully generated patch: $PATCH_FILE"
        echo "   Patch file size: $(wc -c < "$PATCH_FILE") bytes"
        echo "   Lines in patch: $(wc -l < "$PATCH_FILE")"
        echo "   Staged files count: $(echo "$VELOX_STAGED_FILES" | wc -l)"
    else
        echo "Error: Patch file was not created or is empty"
        rm -f "$PATCH_FILE"
        exit 1
    fi
fi
echo "=== Patch generation completed ==="
