## FindLinker.cmake
# Purpose:
#   Provide a single entry point to configure which ELF/Mach-O linker the build uses.
#   Supports (a) fully custom user supplied linker path + args, or (b) intelligent
#   auto selection on Linux (mold -> lld) with graceful fallback to system linker.
#
# Requirements (as per latest spec):
#   * Supports external override only via HALO_CUSTOM_LINKER (path). HALO_LINKER itself is INTERNAL.
#       - User supplies: -DHALO_CUSTOM_LINKER=/abs/path/to/ld
#       - We validate existence and then collapse to internal HALO_LINKER.
#       - Direct attempts to set HALO_LINKER are ignored (we always reset it first).
#   * macOS: Do NOT attempt automatic alternative linker selection. Only honor custom.
#   * Linux: If no custom linker:
#       - Try to find mold first; if found use it.
#       - Else try lld (prefer ld.lld over bare lld); if found use it.
#       - Else emit WARNING and use default system linker (do not set HALO_LINKER).
#   * Export variable (CACHE for external visibility):
#       HALO_LINKER : full path to selected linker (may be empty for default)
#
#   Third-party flag propagation should now consult HALO_LINKER only.
#
# Public function:
#   linker_configure()
# Optional diagnostic helper (still kept):
#   linker_add_selfcheck()

include_guard(GLOBAL)

function(_halo_find_program _out_var)
    # Wrapper with consistent hints; caller provides candidate list via ARGN
    find_program(_cand NAMES ${ARGN}
        HINTS /usr/bin /usr/local/bin /usr/local/opt/llvm/bin)
    set(${_out_var} "${_cand}" PARENT_SCOPE)
endfunction()

function(linker_configure)
    # Reset internal storage (ignore any externally provided HALO_LINKER attempts)
    set(HALO_LINKER "" CACHE INTERNAL "(internal) selected linker executable (empty => use default)" FORCE)
    # Accept external custom linker request
    set(HALO_CUSTOM_LINKER "${HALO_CUSTOM_LINKER}" CACHE FILEPATH "User provided custom linker path (validated then copied into internal HALO_LINKER)")
    if(HALO_CUSTOM_LINKER)
        if(NOT IS_ABSOLUTE "${HALO_CUSTOM_LINKER}")
            get_filename_component(_abs_custom "${HALO_CUSTOM_LINKER}" ABSOLUTE)
        else()
            set(_abs_custom "${HALO_CUSTOM_LINKER}")
        endif()
        if(NOT EXISTS "${_abs_custom}")
            message(FATAL_ERROR "HALO_CUSTOM_LINKER path does not exist: ${_abs_custom}")
        endif()
        set(HALO_LINKER "${_abs_custom}" CACHE INTERNAL "(internal) selected linker executable (empty => use default)" FORCE)
        set(CMAKE_LINKER "${_abs_custom}" CACHE FILEPATH "Explicit custom linker" FORCE)
        message(STATUS "linker: using user custom linker '${_abs_custom}'")
        return()
    endif()

    # 2. Platform specific auto detection (no forcing – informational only)
    if(APPLE)
        message(STATUS "linker: macOS using system default linker")
        return()
    endif()

    if(UNIX)
        # Linux auto detection: mold -> lld else default
        # Actually set the linker when found
        _halo_find_program(_mold mold)
        if(_mold)
            set(HALO_LINKER "${_mold}" CACHE INTERNAL "(internal) selected linker executable (empty => use default)" FORCE)
            set(CMAKE_LINKER "${_mold}" CACHE FILEPATH "Auto-selected mold linker" FORCE)
            # Set linker flags for compiler invocation (needed for some third-party libraries)
            # Use both CMAKE_LINKER and -fuse-ld for maximum compatibility
            # Check and avoid duplicate -fuse-ld flags
            if(NOT CMAKE_EXE_LINKER_FLAGS MATCHES "-fuse-ld=mold")
                set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=mold" CACHE STRING "Linker flags" FORCE)
            endif()
            if(NOT CMAKE_SHARED_LINKER_FLAGS MATCHES "-fuse-ld=mold")
                set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=mold" CACHE STRING "Shared linker flags" FORCE)
            endif()
            if(NOT CMAKE_MODULE_LINKER_FLAGS MATCHES "-fuse-ld=mold")
                set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -fuse-ld=mold" CACHE STRING "Module linker flags" FORCE)
            endif()
            # Note: CMAKE_STATIC_LINKER_FLAGS is for ar/ranlib, not for linking, so we don't set it
            message(STATUS "linker: using mold linker '${_mold}' with -fuse-ld=mold flags")
        else()
            _halo_find_program(_lld ld.lld lld)
            if(_lld)
                set(HALO_LINKER "${_lld}" CACHE INTERNAL "(internal) selected linker executable (empty => use default)" FORCE)
                set(CMAKE_LINKER "${_lld}" CACHE FILEPATH "Auto-selected lld linker" FORCE)
                # Set linker flags for compiler invocation
                # Check and avoid duplicate -fuse-ld flags
                if(NOT CMAKE_EXE_LINKER_FLAGS MATCHES "-fuse-ld=lld")
                    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=lld" CACHE STRING "Linker flags" FORCE)
                endif()
                if(NOT CMAKE_SHARED_LINKER_FLAGS MATCHES "-fuse-ld=lld")
                    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=lld" CACHE STRING "Shared linker flags" FORCE)
                endif()
                if(NOT CMAKE_MODULE_LINKER_FLAGS MATCHES "-fuse-ld=lld")
                    set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -fuse-ld=lld" CACHE STRING "Module linker flags" FORCE)
                endif()
                message(STATUS "linker: using lld linker '${_lld}' with -fuse-ld=lld flags")
            else()
                message(STATUS "linker: no mold/lld found; using system default")
            endif()
        endif()
        # --- Enforce clang + libc++ policy (Linux only) ---
        if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            message(FATAL_ERROR "HALO policy: Only clang is supported on Linux. Detected compiler ID='${CMAKE_CXX_COMPILER_ID}'.")
        endif()
        # Ensure -stdlib=libc++ present in C++ flags (idempotent append)
        # Use string(FIND) instead of regex MATCHES to avoid portability issues with '+' meta handling.
        string(FIND "${CMAKE_CXX_FLAGS}" "-stdlib=libc++" _have_libcxx_flag)
        if(_have_libcxx_flag EQUAL -1)
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++" CACHE STRING "Global C++ compile flags" FORCE)
            message(STATUS "linker: enforcing -stdlib=libc++ in CMAKE_CXX_FLAGS")
        endif()
        # Append libc++ runtime libs once to linker flags if missing
        string(FIND "${CMAKE_EXE_LINKER_FLAGS}" "-lc++abi" _have_cxxabi)
        string(FIND "${CMAKE_EXE_LINKER_FLAGS}" "-lc++" _have_cxx)
        if(_have_cxxabi EQUAL -1 AND _have_cxx EQUAL -1)
            set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lc++ -lc++abi" CACHE STRING "Linker flags" FORCE)
            set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -lc++ -lc++abi" CACHE STRING "Shared linker flags" FORCE)
            set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -lc++ -lc++abi" CACHE STRING "Module linker flags" FORCE)
            message(STATUS "linker: appended libc++ runtime libraries (-lc++ -lc++abi)")
        endif()
        return()
    endif()
endfunction()

function(linker_add_selfcheck)
    if(NOT CMAKE_CXX_COMPILER)
        message(WARNING "linker_add_selfcheck called before CXX compiler enabled")
        return()
    endif()
    if(TARGET linker-selfcheck)
        return()
    endif()
    file(WRITE ${CMAKE_BINARY_DIR}/linker_probe.cpp "int main(){return 0;}")
    add_custom_target(linker-selfcheck
        COMMAND ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_FLAGS} -c ${CMAKE_BINARY_DIR}/linker_probe.cpp -o ${CMAKE_BINARY_DIR}/linker_probe.o
        COMMAND ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_FLAGS} ${CMAKE_BINARY_DIR}/linker_probe.o -o ${CMAKE_BINARY_DIR}/linker_probe -Wl,-v
        COMMENT "[linker] Display linker invocation (-Wl,-v)"
        VERBATIM)
endfunction()
