#!/usr/bin/env bash
# collect_zstd_diagnostics.sh
#
# Enumerate all test and other executables in the build tree that depend on zstd
# and collect detailed loader + symbol provenance information.
#
# Output:
#   zstd_diagnostics/summary.txt                Human-readable consolidated summary
#   zstd_diagnostics/executables.list           List of examined executables
#   zstd_diagnostics/<exe>/ldd.txt              ldd output
#   zstd_diagnostics/<exe>/objdump-needed.txt   Needed shared objects (objdump -p)
#   zstd_diagnostics/<exe>/nm-zstd-version.txt  nm search for ZSTD_versionNumber/ZSTD_versionString
#   zstd_diagnostics/<exe>/proc-maps.txt        Filtered /proc/self/maps captured by a helper run
#   zstd_diagnostics/<exe>/dladdr.txt           dladdr output captured via helper
#   zstd_diagnostics/lib/libzstd.*.sha256       SHA256 checksums of detected zstd libraries
#   zstd_diagnostics/lib/libzstd.*.fileinfo     file type information (file)
#
# Strategy:
#   1. Find executables: anything under build/ with ELF header (file magic) or no extension and executable bit.
#   2. Use ldd to list dynamic dependencies and identify any zstd-related .so.
#   3. For each executable referencing zstd via ldd or containing string 'ZSTD_' in nm output, gather objdump -p.
#   4. Spawn a small helper that prints dladdr() info and filtered /proc/self/maps for the zstd symbol.
#   5. Compute checksums of unique libzstd artifacts discovered.
#   6. Summarize which path variant is used (system vs project) and potential mismatch with expected version 1.5.7.
#
# Expected working directory: repository root OR build directory; script auto-detects build/.

set -euo pipefail

EXPECTED_NUMERIC=10507
EXPECTED_STRING="1.5.7"

ROOT_DIR=$(pwd)
if [ -d "$ROOT_DIR/build" ]; then
  BUILD_DIR="$ROOT_DIR/build"
elif [ -d "$ROOT_DIR/../build" ]; then
  BUILD_DIR="$ROOT_DIR/../build"
else
  echo "ERROR: Could not locate build directory" >&2
  exit 1
fi

OUT_DIR="$BUILD_DIR/zstd_diagnostics"
mkdir -p "$OUT_DIR"

ZSTD_STATIC_LIB="${THIRDPARTY_INSTALL_DIR:-}"  # may be empty if not sourced through CMake environment
# Attempt to discover libzstd.a and include dir heuristically
DISCOVERED_LIB=$(find "$BUILD_DIR" -type f -name libzstd.a -print -quit 2>/dev/null || true)
if [ -z "$DISCOVERED_LIB" ]; then
  DISCOVERED_LIB=$(find "$ROOT_DIR/thirdparty/installed/zstd/lib" -type f -name libzstd.a -print -quit 2>/dev/null || true)
fi
ZSTD_LIB_PATH="$DISCOVERED_LIB"

ZSTD_INC_PATH=""
if [ -d "$ROOT_DIR/thirdparty/installed/zstd/include" ]; then
  ZSTD_INC_PATH="$ROOT_DIR/thirdparty/installed/zstd/include"
elif [ -d "$BUILD_DIR/thirdparty/installed/zstd/include" ]; then
  ZSTD_INC_PATH="$BUILD_DIR/thirdparty/installed/zstd/include"
fi

HELPER_SRC="$OUT_DIR/helper_dladdr.c"
cat > "$HELPER_SRC" <<'EOF'
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <zstd.h>
#include <string.h>
int main(int argc, char** argv){
  Dl_info info; unsigned ver = ZSTD_versionNumber(); const char* vs = ZSTD_versionString();
  printf("ZSTD_versionNumber=%u\n", ver);
  printf("ZSTD_versionString=%s\n", vs?vs:"<null>");
  if(dladdr((void*)ZSTD_versionNumber, &info)){
    printf("dladdr.dli_fname=%s\n", info.dli_fname?info.dli_fname:"<null>");
  } else { printf("dladdr.failed=1\n"); }
  FILE* f = fopen("/proc/self/maps","r"); if(f){
    char line[4096]; printf("[proc_self_maps_filtered]\n");
    while(fgets(line,sizeof(line),f)){
      if(strstr(line,"zstd")) fputs(line, stdout);
    }
    fclose(f);
  }
  return 0;
}
EOF

if [ -n "$ZSTD_LIB_PATH" ] && [ -f "$ZSTD_LIB_PATH" ]; then
  # Use explicit static linking to internal libzstd
  INC_FLAG=""
  [ -n "$ZSTD_INC_PATH" ] && INC_FLAG="-I$ZSTD_INC_PATH"
  if command -v clang >/dev/null 2>&1; then
    clang "$HELPER_SRC" $INC_FLAG "$ZSTD_LIB_PATH" -ldl -o "$OUT_DIR/helper_dladdr" 2>/dev/null || true
  elif command -v gcc >/dev/null 2>&1; then
    gcc "$HELPER_SRC" $INC_FLAG "$ZSTD_LIB_PATH" -ldl -o "$OUT_DIR/helper_dladdr" 2>/dev/null || true
  fi
fi
if [ ! -x "$OUT_DIR/helper_dladdr" ]; then
  echo "[warn] helper_dladdr not built (missing compiler or libzstd); dladdr diagnostics will be skipped" >&2
fi

EXEC_LIST_FILE="$OUT_DIR/executables.list"
> "$EXEC_LIST_FILE"

# Discover executables (ELF) inside build. Skip directories & object files.
while IFS= read -r -d '' f; do
  if file "$f" 2>/dev/null | grep -q "ELF"; then
    echo "$f" >> "$EXEC_LIST_FILE"
  fi
done < <(find "$BUILD_DIR" -type f -perm -u+x -print0)

SUMMARY="$OUT_DIR/summary.txt"
> "$SUMMARY"
echo "ExpectedNumeric=$EXPECTED_NUMERIC" >> "$SUMMARY"
echo "ExpectedString=$EXPECTED_STRING" >> "$SUMMARY"
echo "BuildDir=$BUILD_DIR" >> "$SUMMARY"
echo "ExecutableCount=$(wc -l < "$EXEC_LIST_FILE")" >> "$SUMMARY"
echo "Timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$SUMMARY"
echo "Hostname=$(hostname || echo unknown)" >> "$SUMMARY"
echo >> "$SUMMARY"

declare -A ZSTD_LIB_PATHS

while read -r exe; do
  [ -n "$exe" ] || continue
  REL=$(realpath --relative-to "$BUILD_DIR" "$exe" 2>/dev/null || echo "$exe")
  EXE_DIR="$OUT_DIR/$(echo "$REL" | tr '/' '_')"
  mkdir -p "$EXE_DIR"
  echo "== $REL ==" >> "$SUMMARY"
  if ldd "$exe" > "$EXE_DIR/ldd.txt" 2>&1; then
    grep -i 'zstd' "$EXE_DIR/ldd.txt" >> "$SUMMARY" || echo "(no zstd in ldd)" >> "$SUMMARY"
  else
    echo "(ldd failed)" >> "$SUMMARY"
  fi
  objdump -p "$exe" 2>/dev/null | grep -E 'NEEDED|RUNPATH|RPATH' > "$EXE_DIR/objdump-needed.txt" || true
  nm -D "$exe" 2>/dev/null | grep -E 'ZSTD_version(Number|String)' > "$EXE_DIR/nm-zstd-version.txt" || true
  # Run helper only if executable likely links zstd
  if grep -q 'zstd' "$EXE_DIR/ldd.txt" 2>/dev/null || [ -s "$EXE_DIR/nm-zstd-version.txt" ]; then
    if [ -x "$OUT_DIR/helper_dladdr" ]; then
      "$OUT_DIR/helper_dladdr" > "$EXE_DIR/dladdr.txt" 2>&1 || true
      if grep -q 'dladdr.dli_fname=' "$EXE_DIR/dladdr.txt"; then
        LIBPATH=$(grep 'dladdr.dli_fname=' "$EXE_DIR/dladdr.txt" | head -1 | cut -d= -f2)
        if [ -f "$LIBPATH" ]; then
          ZSTD_LIB_PATHS[$LIBPATH]=1
        fi
      fi
      # Extract maps subset
      grep -i zstd "$EXE_DIR/dladdr.txt" > "$EXE_DIR/proc-maps.txt" || true
    fi
  fi
  echo >> "$SUMMARY"
done < "$EXEC_LIST_FILE"

# Collect link command lines referencing zstd
LINK_LINES_FILE="$OUT_DIR/link-lines.txt"
> "$LINK_LINES_FILE"
find "$BUILD_DIR" -type f -name link.txt -print0 2>/dev/null | while IFS= read -r -d '' lf; do
  if grep -q 'zstd' "$lf"; then
    echo "# $lf" >> "$LINK_LINES_FILE"
    grep -i 'zstd' "$lf" >> "$LINK_LINES_FILE" || true
    echo >> "$LINK_LINES_FILE"
  fi
done
if [ -s "$LINK_LINES_FILE" ]; then
  echo "[link.txt with zstd collected]" >> "$SUMMARY"
  COUNT_LZSTD_LINK=$(grep -o '\-lzstd' "$LINK_LINES_FILE" | wc -l | tr -d ' ')
  echo "RawDashLzstdCount=$COUNT_LZSTD_LINK" >> "$SUMMARY"
else
  echo "[no link.txt contained zstd]" >> "$SUMMARY"
  echo "RawDashLzstdCount=0" >> "$SUMMARY"
fi

# Capture build.ninja zstd lines (first 200 to avoid bloat)
if [ -f "$BUILD_DIR/build.ninja" ]; then
  grep -i 'zstd' "$BUILD_DIR/build.ninja" | head -200 > "$OUT_DIR/build_ninja_zstd_snippet.txt" || true
  SNIPPET_LINES=$(wc -l < "$OUT_DIR/build_ninja_zstd_snippet.txt" | tr -d ' ')
  echo "BuildNinjaZstdLines=$SNIPPET_LINES" >> "$SUMMARY"
fi

# Capture CMakeCache zstd-related variables
if [ -f "$BUILD_DIR/CMakeCache.txt" ]; then
  grep -E '^ZSTD_' "$BUILD_DIR/CMakeCache.txt" > "$OUT_DIR/cmakecache_zstd.txt" || true
  CACHE_LINES=$(wc -l < "$OUT_DIR/cmakecache_zstd.txt" | tr -d ' ')
  echo "CMakeCacheZstdLines=$CACHE_LINES" >> "$SUMMARY"
fi

# Run halo executable with LD_DEBUG=libs to observe loader decisions
HALO_EXE="$BUILD_DIR/halo"
if [ -x "$HALO_EXE" ]; then
  (cd "$BUILD_DIR" && env LD_DEBUG=libs "$HALO_EXE" > "$OUT_DIR/halo_ld_debug.txt" 2>&1 || true)
  head -100 "$OUT_DIR/halo_ld_debug.txt" > "$OUT_DIR/halo_ld_debug_head.txt" || true
  echo "HaloLdDebugCollected=1" >> "$SUMMARY"
else
  echo "HaloLdDebugCollected=0" >> "$SUMMARY"
fi

LIB_OUT_DIR="$OUT_DIR/lib"
mkdir -p "$LIB_OUT_DIR"
for lib in "${!ZSTD_LIB_PATHS[@]}"; do
  base=$(basename "$lib")
  sha256sum "$lib" > "$LIB_OUT_DIR/${base}.sha256" 2>/dev/null || true
  file "$lib" > "$LIB_OUT_DIR/${base}.fileinfo" 2>/dev/null || true
  echo "LibraryCaptured=$lib" >> "$SUMMARY"
done

echo >> "$SUMMARY"
echo "UniqueZstdLibrariesCount=${#ZSTD_LIB_PATHS[@]}" >> "$SUMMARY"

# Detect if any captured library path appears to be from a system location.
SYSTEM_DETECTED=0
for lib in "${!ZSTD_LIB_PATHS[@]}"; do
  case "$lib" in
    /usr/lib/*|/lib/*|/lib64/*|/usr/lib64/*)
      SYSTEM_DETECTED=1
      ;;
  esac
done
echo "SystemZstdDetected=$SYSTEM_DETECTED" >> "$SUMMARY"

if [ $SYSTEM_DETECTED -eq 1 ]; then
  echo "[warn] System zstd library detected among captured paths" >&2
fi

echo "Diagnostics complete: $OUT_DIR"