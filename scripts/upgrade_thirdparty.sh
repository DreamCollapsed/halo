#!/bin/bash

# scripts/check_thirdparty_updates.sh
# Checks for updates for third-party libraries defined in thirdparty/ComponentsInfo.cmake

# 1. Path Independence
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPONENTS_FILE="$PROJECT_ROOT/thirdparty/ComponentsInfo.cmake"
DOWNLOAD_DIR="/tmp"
OLD_DOWNLOAD_DIR="$PROJECT_ROOT/thirdparty/downloads"

# Ignored components
IGNORED_COMPONENTS=("OPENSSL" "GEOS")

# Track updated components
UPDATED_COMPONENTS=()

# Ensure download directory exists
mkdir -p "$DOWNLOAD_DIR"

if [ ! -f "$COMPONENTS_FILE" ]; then
    echo "Error: Cannot find $COMPONENTS_FILE"
    exit 1
fi

echo "Checking for updates in $COMPONENTS_FILE..."
echo "Downloads will be cached in $DOWNLOAD_DIR"

# Function to clean version string
clean_version() {
    local v=$1
    v=${v#v}
    v=${v#release-}
    v=${v#boost-}
    v=${v#zstd-}
    v=${v#llvmorg-}
    v=${v#bzip2-}
    v=${v%-stable}
    v=${v%-RELEASE}
    echo "$v"
}

# Function to check if new version is greater than current
is_newer() {
    local new_raw="$1"
    local current_raw="$2"
    local new=$(clean_version "$new_raw")
    local current=$(clean_version "$current_raw")
    
    if [ "$new" = "$current" ]; then
        return 1
    fi
    
    # Basic sanity check: version must start with a digit
    if [[ ! "$new" =~ ^[0-9] ]]; then
        return 1
    fi

    # Use sort -V for version comparison
    local sorted=$(printf "%s\n%s" "$new" "$current" | sort -V | tail -n 1)
    if [ "$sorted" = "$new" ]; then
        return 0
    else
        return 1
    fi
}

# Function to get latest version from GitHub
get_latest_github_version() {
    local repo=$1
    local current_version=$2
    local token_header=""
    if [ -n "$GITHUB_TOKEN" ]; then
        token_header="Authorization: token $GITHUB_TOKEN"
    fi
    
    # 1. Try Releases (List) - Prefer official releases
    local response=$(curl -s -H "$token_header" "https://api.github.com/repos/$repo/releases?per_page=5")
    
    # Check if response is a list (starts with [)
    if [[ "$response" =~ ^\[ ]]; then
        # Filter out drafts and prereleases, pick the first tag_name
        local latest_release=$(echo "$response" | jq -r '.[] | select(.draft == false and .prerelease == false) | .tag_name' 2>/dev/null | head -n 1)
        
        if [ -n "$latest_release" ] && [ "$latest_release" != "null" ]; then
             if is_newer "$latest_release" "$current_version"; then
                echo "$latest_release"
                return
             fi
             # If we found releases but none are newer, we assume we are up to date relative to releases.
             return
        fi
    fi
    
    # 2. Fallback to Tags if no releases found or API failed/returned empty list
    response=$(curl -s -H "$token_header" "https://api.github.com/repos/$repo/tags?per_page=20")
    
    if echo "$response" | jq -e .message >/dev/null 2>&1; then
         # Error or Not Found
         return
    fi
    
    local tags=$(echo "$response" | jq -r '.[].name' 2>/dev/null)
    
    for tag in $tags; do
        if [ "$tag" != "null" ] && [ -n "$tag" ]; then
             # Filter bad tags
             if [[ ! "$tag" =~ "tools" ]] && [[ ! "$tag" =~ "old" ]]; then
                 if is_newer "$tag" "$current_version"; then
                    echo "$tag"
                    return
                 fi
             fi
        fi
    done
}

# Function to verify archive integrity
verify_archive() {
    local file=$1
    local filename=$(basename "$file")
    
    if [[ "$filename" =~ \.tar\.gz$ ]] || [[ "$filename" =~ \.tgz$ ]]; then
        tar -tzf "$file" > /dev/null 2>&1
    elif [[ "$filename" =~ \.tar\.bz2$ ]]; then
        tar -tjf "$file" > /dev/null 2>&1
    elif [[ "$filename" =~ \.tar\.xz$ ]]; then
        tar -tJf "$file" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
             xz -t "$file" > /dev/null 2>&1
        fi
    elif [[ "$filename" =~ \.zip$ ]]; then
        unzip -tq "$file" > /dev/null 2>&1
    else
        [ -s "$file" ]
    fi
}

# Function to download and calculate hash
download_and_hash() {
    local url=$1
    local name=$2
    local version=$3
    
    local filename=$(basename "$url")
    local filepath="$DOWNLOAD_DIR/$filename"
    
    # Always download (overwrite if exists)
    # echo "  Downloading $url..." >&2
    
    local temp_file="${filepath}.tmp"
    if curl -f -sL -o "$temp_file" "$url"; then
        if [ ! -s "$temp_file" ]; then
            rm "$temp_file"
            return 1
        fi
        
        mv "$temp_file" "$filepath"
        
        if verify_archive "$filepath"; then
            local hash=$(sha256sum "$filepath" | awk '{print $1}')
            echo "$hash"
            return 0
        else
            echo "  Downloaded file corrupted." >&2
            rm "$filepath"
            return 1
        fi
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Get list of components
components=$(grep -E '^\s*set\([A-Z0-9_]+_VERSION' "$COMPONENTS_FILE" | sed -E 's/^\s*set\((.*)_VERSION "(.*)"\)/\1/')

for name in $components; do
    # Get current version
    version_line=$(grep -E "^\s*set\(${name}_VERSION" "$COMPONENTS_FILE")
    current_version=$(echo "$version_line" | sed -E 's/^\s*set\(.*_VERSION "(.*)"\)/\1/')
    
    # Get URL pattern
    url_line=$(grep -E "^\s*set\(${name}_URL" "$COMPONENTS_FILE")
    url_pattern=$(echo "$url_line" | sed -E 's/^\s*set\(.*_URL "(.*)"\)/\1/')
    
    # Check if it's a git repo
    use_git_line=$(grep -E "^\s*set\(${name}_USE_GIT" "$COMPONENTS_FILE")
    is_git="OFF"
    if [[ "$use_git_line" =~ "ON" ]]; then
        is_git="ON"
    fi
    
    # 1. Skip Git components
    if [ "$is_git" == "ON" ]; then
        continue
    fi
    
    # 2. Skip Ignored components
    if [[ " ${IGNORED_COMPONENTS[@]} " =~ " ${name} " ]]; then
        # echo "Skipping $name (Ignored)..."
        continue
    fi
    
    repo=""
    latest_tag=""
    
    # 3. Identify Repo
    if [ "$name" == "BOOST" ]; then
        repo="boostorg/boost"
        echo "Checking $name ($repo)... Current: $current_version"
        latest_tag=$(get_latest_github_version "$repo" "$current_version")
    elif [ "$name" == "BISON" ]; then
        repo="akimd/bison"
        echo "Checking $name ($repo)... Current: $current_version"
        latest_tag=$(get_latest_github_version "$repo" "$current_version")
    elif [ "$name" == "BZIP2" ]; then
        repo="libarchive/bzip2"
        echo "Checking $name ($repo)... Current: $current_version"
        latest_tag=$(get_latest_github_version "$repo" "$current_version")
    elif [ "$name" == "GEOS" ]; then
        repo="libgeos/geos"
        echo "Checking $name ($repo)... Current: $current_version"
        latest_tag=$(get_latest_github_version "$repo" "$current_version")
    elif [ "$name" == "LIBSTEMMER" ]; then
        repo="snowballstem/snowball"
        echo "Checking $name ($repo)... Current: $current_version"
        latest_tag=$(get_latest_github_version "$repo" "$current_version")
    elif [[ "$url_pattern" =~ "github.com" ]]; then
        if [[ "$url_pattern" =~ github.com/([^/]+/[^/]+) ]]; then
            repo="${BASH_REMATCH[1]}"
            repo=${repo%.git}
            repo=${repo%/archive}
        fi
        
        if [ -n "$repo" ]; then
            echo "Checking $name ($repo)... Current: $current_version"
            latest_tag=$(get_latest_github_version "$repo" "$current_version")
        fi
    fi
    
    if [ -n "$repo" ]; then
        if [ -z "$latest_tag" ]; then
            echo "  Up to date or not found."
            continue
        fi
        
        clean_latest=$(clean_version "$latest_tag")
        echo "  New version found: $clean_latest (Tag: $latest_tag)"
        
        new_url=""
        
        if [ "$name" == "BOOST" ]; then
            clean_latest_underscore=${clean_latest//./_}
            new_url="https://archives.boost.io/release/${clean_latest}/source/boost_${clean_latest_underscore}.tar.gz"
        elif [ "$name" == "BISON" ] || [ "$name" == "BZIP2" ] || [ "$name" == "GEOS" ] || [ "$name" == "LIBSTEMMER" ]; then
            # Use existing URL pattern for these, assuming mirrors/upstream follow versioning
            clean_latest_underscore=${clean_latest//./_}
            new_url="$url_pattern"
            new_url=${new_url//\$\{$name\_VERSION\}/$clean_latest}
            new_url=${new_url//\$\{$name\_VERSION_UNDERSCORE\}/$clean_latest_underscore}
        else
            clean_latest_underscore=${clean_latest//./_}
            new_url="$url_pattern"
            new_url=${new_url//\$\{$name\_VERSION\}/$clean_latest}
            new_url=${new_url//\$\{$name\_VERSION_UNDERSCORE\}/$clean_latest_underscore}
        fi
        
        echo "  Downloading and calculating hash for $new_url..."
        
        new_hash=$(download_and_hash "$new_url" "$name" "$clean_latest")
        
        # Fallback URL if download fails
        if [ -z "$new_hash" ] && [ "$name" != "BOOST" ] && [ "$name" != "BISON" ] && [ "$name" != "BZIP2" ] && [ "$name" != "GEOS" ] && [ "$name" != "LIBSTEMMER" ]; then
             echo "  Primary URL failed. Trying fallback to GitHub Archive..."
             fallback_url="https://github.com/${repo}/archive/refs/tags/${latest_tag}.tar.gz"
             echo "  Downloading fallback: $fallback_url..."
             new_hash=$(download_and_hash "$fallback_url" "$name" "$clean_latest")
             if [ -n "$new_hash" ]; then
                 new_url="$fallback_url"
             fi
        fi
        
        if [ -n "$new_hash" ]; then
            echo "  Updating $name to $clean_latest (Hash: $new_hash)"
            
            # Add to summary
            UPDATED_COMPONENTS+=("[$name]: $current_version -> $clean_latest")
            
            escaped_current=${current_version//./\\.}
            
            # Update Version
            sed -i '' "s/set(${name}_VERSION \"$escaped_current\")/set(${name}_VERSION \"$clean_latest\")/" "$COMPONENTS_FILE"
            
            # Update Hash
            hash_line=$(grep -E "^\s*set\(${name}_SHA256" "$COMPONENTS_FILE")
            current_hash=$(echo "$hash_line" | sed -E 's/^\s*set\(.*_SHA256 "(.*)"\)/\1/')
            
            if [ -n "$current_hash" ]; then
                sed -i '' "s/set(${name}_SHA256 \"$current_hash\")/set(${name}_SHA256 \"$new_hash\")/" "$COMPONENTS_FILE"
            fi
            
            if [[ "$new_url" == *"archive/refs/tags"* ]] && [[ "$url_pattern" != *"archive/refs/tags"* ]]; then
                 echo "  Warning: Used fallback URL. You might need to update ${name}_URL manually in CMake file."
                 echo "  New URL: $new_url"
            fi
            
            # Cleanup old file from thirdparty/downloads
            # 1. Try to deduce old filename from old URL pattern
            old_url_constructed="$url_pattern"
            old_url_constructed=${old_url_constructed//\$\{$name\_VERSION\}/$current_version}
            # Handle underscore version if needed
            current_version_underscore=${current_version//./_}
            old_url_constructed=${old_url_constructed//\$\{$name\_VERSION_UNDERSCORE\}/$current_version_underscore}
            
            old_filename=$(basename "$old_url_constructed")
            
            if [ -f "$OLD_DOWNLOAD_DIR/$old_filename" ]; then
                echo "  Removing old file: $OLD_DOWNLOAD_DIR/$old_filename"
                rm "$OLD_DOWNLOAD_DIR/$old_filename"
            else
                # 2. Try to find file with name prefix if not found (e.g. abseil-20250814.1.tar.gz)
                # Convert name to lowercase
                name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
                
                repo_project=""
                if [ -n "$repo" ]; then
                    repo_project=$(basename "$repo")
                fi
                
                # Try pattern: name_lower-current_version.* or repo_project-current_version.*
                if [ -n "$repo_project" ] && [ "$repo_project" != "$name_lower" ]; then
                    found_files=$(find "$OLD_DOWNLOAD_DIR" -maxdepth 1 \( -name "${name_lower}-${current_version}.*" -o -name "${name_lower}-v${current_version}.*" -o -name "${repo_project}-${current_version}.*" -o -name "${repo_project}-v${current_version}.*" \))
                else
                    found_files=$(find "$OLD_DOWNLOAD_DIR" -maxdepth 1 \( -name "${name_lower}-${current_version}.*" -o -name "${name_lower}-v${current_version}.*" \))
                fi
                
                for f in $found_files; do
                    echo "  Removing old file: $f"
                    rm "$f"
                done
            fi
        fi
    fi
done

# Print Summary
echo ""
echo "========================================"
if [ ${#UPDATED_COMPONENTS[@]} -gt 0 ]; then
    echo "Summary of Updates:"
    for update in "${UPDATED_COMPONENTS[@]}"; do
        echo "$update"
    done
else
    echo "No updates found."
fi
echo "========================================"
