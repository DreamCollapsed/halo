
# --- MAP_IMPORTED_CONFIG Utility Macro ---
# This macro maps Debug and other build configurations to use the Release library
# for IMPORTED targets that only export IMPORTED_LOCATION_RELEASE.
#
# Background:
#   All third-party libraries are built in Release mode (see line 988 below),
#   so they only export IMPORTED_LOCATION_RELEASE in their *Targets-release.cmake files.
#   Without this mapping, when the main project builds in Debug mode, CMake cannot find
#   IMPORTED_LOCATION_DEBUG and falls back to searching system paths, which may lead to
#   linking against system libraries instead of our built static libraries.
#
# Usage:
#   thirdparty_map_imported_config(<target_name> [<target_name2> ...])
#
# CMake Documentation:
#   https://cmake.org/cmake/help/latest/prop_tgt/MAP_IMPORTED_CONFIG_CONFIG.html
#
# CRITICAL FIX: When third-party packages only define IMPORTED_CONFIGURATIONS=RELEASE,
# CMake treats the target as unavailable in Debug builds, causing linker to fall back
# to system libraries. We must:
# 1. Add Debug/RelWithDebInfo/MinSizeRel to IMPORTED_CONFIGURATIONS
# 2. Set IMPORTED_LOCATION_* for all configurations
# 3. Set MAP_IMPORTED_CONFIG_* as fallback
#
macro(thirdparty_map_imported_config)
    foreach(_target IN ITEMS ${ARGN})
        if(TARGET ${_target})
            # Step 1: Ensure IMPORTED_CONFIGURATIONS includes all build types
            get_target_property(_existing_configs ${_target} IMPORTED_CONFIGURATIONS)
            if(_existing_configs)
                list(APPEND _existing_configs DEBUG RELWITHDEBINFO MINSIZEREL)
                list(REMOVE_DUPLICATES _existing_configs)
            else()
                set(_existing_configs "RELEASE;DEBUG;RELWITHDEBINFO;MINSIZEREL")
            endif()
            set_target_properties(${_target} PROPERTIES
                IMPORTED_CONFIGURATIONS "${_existing_configs}"
            )
            
            # Step 2: Set fallback mapping
            set_target_properties(${_target} PROPERTIES
                MAP_IMPORTED_CONFIG_DEBUG Release
                MAP_IMPORTED_CONFIG_RELWITHDEBINFO Release
                MAP_IMPORTED_CONFIG_MINSIZEREL Release
            )
            
            # Step 3: Explicitly copy IMPORTED_LOCATION_RELEASE to other configs
            get_target_property(_release_loc ${_target} IMPORTED_LOCATION_RELEASE)
            if(_release_loc)
                set_target_properties(${_target} PROPERTIES
                    IMPORTED_LOCATION_DEBUG "${_release_loc}"
                    IMPORTED_LOCATION_RELWITHDEBINFO "${_release_loc}"
                    IMPORTED_LOCATION_MINSIZEREL "${_release_loc}"
                )
                message(DEBUG "[thirdparty] Mapped ${_target}: configs=${_existing_configs}, location=${_release_loc}")
            else()
                message(DEBUG "[thirdparty] Mapped ${_target}: configs=${_existing_configs} (no RELEASE location)")
            endif()
            unset(_existing_configs)
        else()
            message(FATAL_ERROR "[thirdparty] Cannot map configs for ${_target}: target does not exist")
        endif()
    endforeach()
endmacro()

# --- CMAKE_PREFIX_PATH Registration Utility ---
# This function adds a path to CMAKE_PREFIX_PATH for dependency resolution.
# It now deduplicates and writes to the cache to make find_package() work
# immediately in the caller directory without needing explicit *_DIR.
function(thirdparty_register_to_cmake_prefix_path install_path)
    get_filename_component(_abs_path "${install_path}" ABSOLUTE)
    message(DEBUG "[thirdparty] Searching for CMake config directories in: ${_abs_path}")
    # Search for CMake config directories under lib/cmake/* and lib/*
    file(GLOB _cmake_lib_dirs "${_abs_path}/lib/cmake/*" "${_abs_path}/lib/*")
    set(_config_dir "")
    foreach(_dir IN LISTS _cmake_lib_dirs)
        file(GLOB _cfg "${_dir}/*[Cc]onfig.cmake")
        if(_cfg)
            set(_config_dir "${_dir}")
            message(DEBUG "[thirdparty] Found CMake config directory: ${_config_dir}")
            break()
        endif()
    endforeach()
    # Search for CMake config directories under share/cmake/* and share/*
    if(NOT _config_dir)
        file(GLOB _cmake_share_dirs "${_abs_path}/share/cmake/*" "${_abs_path}/share/*")
        foreach(_dir IN LISTS _cmake_share_dirs)
            file(GLOB _cfg "${_dir}/*[Cc]onfig.cmake")
            if(_cfg)
                set(_config_dir "${_dir}")
                break()
            endif()
        endforeach()
    endif()
    set(_merged_prefix_path "${_abs_path}")
    if(_config_dir)
        list(INSERT _merged_prefix_path 0 "${_config_dir}")
    endif()

    # Include cached value if present
    get_property(_cache_prefix CACHE CMAKE_PREFIX_PATH PROPERTY VALUE)
    if(_cache_prefix)
        list(APPEND _merged_prefix_path ${_cache_prefix})
    endif()

    # Remove empty entries and duplicates while preserving order
    list(REMOVE_ITEM _merged_prefix_path "")
    list(REMOVE_DUPLICATES _merged_prefix_path)

    # Cache-only update; do not touch directory or parent scopes
    set(CMAKE_PREFIX_PATH "${_merged_prefix_path}" CACHE STRING "Search prefixes for find_package()" FORCE)

    # Also prepend pkg-config search paths so FindPkgConfig prefers third-party installs
    set(_pc_candidates)
    list(APPEND _pc_candidates "${_abs_path}/lib/pkgconfig")
    list(APPEND _pc_candidates "${_abs_path}/share/pkgconfig")
    set(_new_pc_paths)
    foreach(_pc ${_pc_candidates})
        if(EXISTS "${_pc}")
            list(APPEND _new_pc_paths "${_pc}")
        endif()
    endforeach()
    if(_new_pc_paths)
        # Compose new PKG_CONFIG_PATH with third-party paths first
        if(DEFINED ENV{PKG_CONFIG_PATH} AND NOT "$ENV{PKG_CONFIG_PATH}" STREQUAL "")
            string(JOIN ":" _pc_joined ${_new_pc_paths} "$ENV{PKG_CONFIG_PATH}")
        else()
            string(JOIN ":" _pc_joined ${_new_pc_paths})
        endif()
        # De-dup crudely by splitting and rejoining while skipping repeats
        string(REPLACE ":" ";" _pc_list "${_pc_joined}")
        set(_pc_dedup)
        foreach(_p IN LISTS _pc_list)
            if(NOT _p STREQUAL "")
                list(FIND _pc_dedup "${_p}" _idx)
                if(_idx EQUAL -1)
                    list(APPEND _pc_dedup "${_p}")
                endif()
            endif()
        endforeach()
        string(JOIN ":" _pc_final ${_pc_dedup})
        set(ENV{PKG_CONFIG_PATH} "${_pc_final}")
    endif()

    list(LENGTH _merged_prefix_path _pp_len)
    message(DEBUG "[thirdparty] Registered ${_abs_path} to CMAKE_PREFIX_PATH (cache size=${_pp_len})")
endfunction()

function(halo_find_package _pkg)
    # Quick idempotency: if _pkg_FOUND is TRUE and either no COMPONENTS requested
    # in this call or previously recorded components cover requested ones, skip.
    # We store requested components in a cache variable HALO_FP_<PKG>_COMPONENTS.
    set(_original_args "${ARGN}")
    # Extract components from ARGN (very lightweight parser; stops after OPTIONAL_COMPONENTS list end)
    set(_want_components)
    set(_collect FALSE)
    foreach(_a IN LISTS ARGN)
        if(_a STREQUAL "COMPONENTS")
            set(_collect TRUE)
            continue()
        elseif(_a STREQUAL "OPTIONAL_COMPONENTS")
            # treat optional components the same for coverage purposes
            set(_collect TRUE)
            continue()
        elseif(_a MATCHES "^(REQUIRED|QUIET|CONFIG|MODULE|EXACT)$")
            # control tokens ignored
        else()
            if(_collect)
                if(_a MATCHES "^[A-Za-z0-9_+-]+$")
                    list(APPEND _want_components "${_a}")
                else()
                    # Probably version or something unexpected; stop collecting to avoid false captures
                    set(_collect FALSE)
                endif()
            endif()
        endif()
    endforeach()
    string(TOUPPER "${_pkg}" _pkg_upper)
    set(_stored_var "HALO_FP_${_pkg_upper}_COMPONENTS")
    if(DEFINED ${_pkg}_FOUND AND ${_pkg}_FOUND)
        if(DEFINED ${_stored_var})
            set(_prev_components ${${_stored_var}})
        else()
            set(_prev_components)
        endif()
        set(_subset TRUE)
        foreach(_wc IN LISTS _want_components)
            list(FIND _prev_components "${_wc}" _idx)
            if(_idx EQUAL -1)
                set(_subset FALSE)
                break()
            endif()
        endforeach()
        if(_subset)
            message(DEBUG "[halo_find_package] Skip repeat find_package(${_pkg}) (components already satisfied)")
            return()
        endif()
    endif()
    if(DEFINED CMAKE_MESSAGE_LOG_LEVEL)
        set(_halo_prev_message_level "${CMAKE_MESSAGE_LOG_LEVEL}")
        set(_halo_had_prev TRUE)
    else()
        set(_halo_prev_message_level "")
        set(_halo_had_prev FALSE)
    endif()

    if(DEFINED HALO_THIRDPARTY_VERBOSE_SUPPRESS AND NOT HALO_THIRDPARTY_VERBOSE_SUPPRESS)
        set(CMAKE_MESSAGE_LOG_LEVEL STATUS)
    else()
        set(CMAKE_MESSAGE_LOG_LEVEL NOTICE)
    endif()

    if(DEFINED HALO_THIRDPARTY_VERBOSE_SUPPRESS AND NOT HALO_THIRDPARTY_VERBOSE_SUPPRESS)
        set(_halo_mode "STATUS")
    else()
        set(_halo_mode "NOTICE")
    endif()
    message(DEBUG "[halo_find_package] level=${_halo_mode} -> find_package(${_pkg} ${ARGN})")

    # Forward to actual find_package
    find_package(${_pkg} ${ARGN})

    # Record components we successfully asked for (append & unique)
    if(DEFINED ${_pkg}_FOUND AND ${_pkg}_FOUND AND _want_components)
        if(DEFINED ${_stored_var})
            set(_merged_list ${${_stored_var}})
        else()
            set(_merged_list)
        endif()
        list(APPEND _merged_list ${_want_components})
        list(REMOVE_DUPLICATES _merged_list)
        set(${_stored_var} "${_merged_list}" CACHE INTERNAL "halo_find_package recorded components for ${_pkg}")
    endif()

    # Emit debug if not found (non-REQUIRED case only)
    if(DEFINED ${_pkg}_FOUND AND NOT ${_pkg}_FOUND)
        message(DEBUG "[halo_find_package] Package '${_pkg}' not found (args='${ARGN}')")
    endif()

    # Restore previous state
    if(_halo_had_prev)
        set(CMAKE_MESSAGE_LOG_LEVEL "${_halo_prev_message_level}")
    else()
        unset(CMAKE_MESSAGE_LOG_LEVEL)
    endif()
endfunction()

function(thirdparty_get_build_jobs)
    # Parse optional parameters for different build systems
    set(options "")
    set(oneValueArgs "OUTPUT_COMPILE_JOBS;OUTPUT_LINK_JOBS;OUTPUT_MAKE_JOBS;BUILD_TYPE")
    set(multiValueArgs "")
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
    include(ProcessorCount)
    ProcessorCount(_cpu_count)
    
    if(NOT _cpu_count OR _cpu_count EQUAL 0)
        set(_cpu_count 4)
        message(STATUS "[thirdparty] CPU count detection failed, using fallback: ${_cpu_count}")
    endif()
    
    set(_compile_jobs ${_cpu_count})
    set(_link_jobs 2)
    set(_make_jobs ${_cpu_count})
    
    if(_cpu_count GREATER 8)
        set(_link_jobs 4)
    elseif(_cpu_count GREATER 16)
        set(_link_jobs 6)
    endif()
    
    if(ARG_BUILD_TYPE AND ARG_BUILD_TYPE STREQUAL "Debug")
        math(EXPR _compile_jobs "${_cpu_count} / 2")
        math(EXPR _link_jobs "2")
        if(_compile_jobs LESS 2)
            set(_compile_jobs 2)
        endif()
        message(STATUS "[thirdparty] Debug build detected, using conservative job counts")
    endif()
    
    if(ARG_OUTPUT_COMPILE_JOBS)
        set(${ARG_OUTPUT_COMPILE_JOBS} ${_compile_jobs} PARENT_SCOPE)
    endif()
    if(ARG_OUTPUT_LINK_JOBS)
        set(${ARG_OUTPUT_LINK_JOBS} ${_link_jobs} PARENT_SCOPE)
    endif()
    if(ARG_OUTPUT_MAKE_JOBS)
        set(${ARG_OUTPUT_MAKE_JOBS} ${_make_jobs} PARENT_SCOPE)
    endif()
    
    message(STATUS "[thirdparty] Build job configuration: compile=${_compile_jobs}, link=${_link_jobs}, make=${_make_jobs} (${_cpu_count} CPUs available)")
endfunction()

function(thirdparty_download_and_check url file hash)
    set(_need_download TRUE)
    if(EXISTS "${file}")
        file(SHA256 "${file}" _file_hash)
        if(_file_hash STREQUAL "${hash}")
            set(_need_download FALSE)
        else()
            file(REMOVE "${file}")
        endif()
    endif()
    
    if(_need_download)
        set(_max_retries 3)
        set(_retry_count 0)
        set(_download_success FALSE)

        while(NOT _download_success AND _retry_count LESS _max_retries)
            math(EXPR _retry_count "${_retry_count} + 1")

            if(_retry_count GREATER 1)
                if(EXISTS "${file}")
                    file(REMOVE "${file}")
                endif()
            endif()

            file(DOWNLOAD "${url}" "${file}"
                SHOW_PROGRESS
                STATUS _download_status
            )

            # Check download status
            list(GET _download_status 0 _status_code)
            list(GET _download_status 1 _status_message)

            if(_status_code EQUAL 0)
                # Download succeeded, verify file exists and has correct hash
                if(EXISTS "${file}")
                    file(SHA256 "${file}" _actual_hash)
                    if(_actual_hash STREQUAL "${hash}")
                        set(_download_success TRUE)
                    else()
                        file(REMOVE "${file}")
                    endif()
                endif()
            else()
                if(EXISTS "${file}")
                    file(REMOVE "${file}")
                endif()
            endif()
        endwhile()

        if(NOT _download_success)
            message(FATAL_ERROR "[thirdparty_download] Failed to download after ${_max_retries} attempts: ${url}")
        endif()
    endif()
endfunction()

# -----------------------------------------------------------------------------
# Unified source acquisition helper
# Usage:
#   thirdparty_acquire_source(<lib_lower_name> <out_source_dir_var>)
# Expected variables (case-insensitive mapping handled inside):
#   <UPPER>_URL        : If *_USE_GIT is OFF/undefined -> archive URL; if ON -> git repo URL
#   <UPPER>_SHA256     : If archive mode -> archive SHA256; if git mode -> commit hash
#   <UPPER>_VERSION    : Optional version (used in archive naming)
#   <UPPER>_USE_GIT    : Boolean (ON/TRUE/1) to enable git path
# Behavior:
#   * Archive mode: download (with hash check) + extract (renaming to canonical src dir)
#   * Git mode: clone (with retries) + checkout commit; reuse existing directory if already at commit
# Result:
#   Sets given out variable to canonical source directory path.
# -----------------------------------------------------------------------------
function(thirdparty_acquire_source lib_name out_src_var)
    string(TOUPPER "${lib_name}" _upper)
    string(REPLACE "-" "_" _upper "${_upper}")

    set(_url     "${${_upper}_URL}")
    set(_sha256  "${${_upper}_SHA256}")
    set(_version "${${_upper}_VERSION}")
    set(_use_git FALSE)
    if(DEFINED ${_upper}_USE_GIT AND ${_upper}_USE_GIT)
        set(_use_git TRUE)
    endif()

    set(_src_dir "${THIRDPARTY_SRC_DIR}/${lib_name}")
    set(_source_fresh FALSE)

    if(_use_git)
        # Pre-check if existing clone is already at requested commit -> not fresh
        set(_existing_match FALSE)
        if(EXISTS "${_src_dir}/.git")
            find_program(GIT_EXECUTABLE git)
            if(GIT_EXECUTABLE)
                execute_process(
                    COMMAND ${GIT_EXECUTABLE} -C "${_src_dir}" rev-parse HEAD
                    OUTPUT_VARIABLE _current_commit
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    RESULT_VARIABLE _rev_parse_result
                )
                if(_rev_parse_result EQUAL 0 AND _current_commit STREQUAL "${_sha256}")
                    set(_existing_match TRUE)
                endif()
            endif()
        endif()
        # Additional optional flags: <UPPER>_GIT_SHALLOW (default ON) <UPPER>_GIT_RECURSE_SUBMODULES (default OFF)
        set(_git_flags)
        if(DEFINED ${_upper}_GIT_SHALLOW AND NOT ${_upper}_GIT_SHALLOW)
            list(APPEND _git_flags GIT_SHALLOW OFF)
        endif()
        if(DEFINED ${_upper}_GIT_RECURSE_SUBMODULES AND ${_upper}_GIT_RECURSE_SUBMODULES)
            list(APPEND _git_flags GIT_RECURSE_SUBMODULES ON)
        endif()
        message(DEBUG "[thirdparty] ${lib_name}: acquiring via git repo=${_url} commit=${_sha256} ${_git_flags}")
        thirdparty_git_clone_and_checkout("${_url}" "${_src_dir}" "${_sha256}")
        if(_existing_match)
            set(_source_fresh FALSE)
        else()
            set(_source_fresh TRUE)
        endif()
    else()
        # Derive archive extension
        get_filename_component(_url_filename "${_url}" NAME)
        string(REGEX MATCH "(\\.tar\\.gz|\\.tgz|\\.tar\\.bz2|\\.tbz2|\\.tar\\.xz|\\.txz|\\.zip)$" _extension "${_url_filename}")
        if(NOT _extension)
            if(_url MATCHES "\\.zip")
                set(_extension ".zip")
            else()
                set(_extension ".tar.gz")
            endif()
        endif()
        if(NOT _version)
            # Attempt to guess a short version fragment from URL path segment if missing
            string(REGEX MATCH "([0-9]+\\.[0-9]+(\\.[0-9]+)?)" _guessed_ver "${_url}")
            if(_guessed_ver)
                set(_version "${CMAKE_MATCH_1}")
            else()
                set(_version "src")
            endif()
        endif()
        set(_download_file "${THIRDPARTY_DOWNLOAD_DIR}/${lib_name}-${_version}${_extension}")
        set(_extract_pattern "${THIRDPARTY_SRC_DIR}/${lib_name}-*")
        # Determine if source already extracted by checking a SHA256 marker
        set(_marker "${_src_dir}/.thirdparty_sha256")
        set(_already_extracted FALSE)
        if(EXISTS "${_marker}")
            file(READ "${_marker}" _prev_sha)
            string(STRIP "${_prev_sha}" _prev_sha)
            if(_prev_sha STREQUAL "${_sha256}")
                set(_already_extracted TRUE)
            endif()
        endif()

        # Fallback: if srcdir exists and is non-empty, assume already extracted (boost has no top-level CMakeLists.txt)
        if(NOT _already_extracted AND EXISTS "${_src_dir}")
            file(GLOB _existing_entries "${_src_dir}/*")
            list(LENGTH _existing_entries _existing_len)
            set(_signature_good FALSE)
            if(EXISTS "${_src_dir}/CMakeLists.txt" OR EXISTS "${_src_dir}/configure" OR EXISTS "${_src_dir}/bootstrap.sh" OR EXISTS "${_src_dir}/Jamroot")
                set(_signature_good TRUE)
            endif()
            if(_existing_len GREATER 0 AND _signature_good)
                set(_already_extracted TRUE)
                file(WRITE "${_marker}" "${_sha256}\n")
            endif()
        endif()

        if(_already_extracted)
            # Fast path: reuse existing extracted source, skip re-download and re-extract
            message(DEBUG "[thirdparty] ${lib_name}: reusing existing source at ${_src_dir}; skip download and extract")
            set(_source_fresh FALSE)
        else()
            message(STATUS "[thirdparty] ${lib_name}: downloading and extracting archive")
            thirdparty_download_and_check("${_url}" "${_download_file}" "${_sha256}")
            thirdparty_extract_and_rename("${_download_file}" "${_src_dir}" "${_extract_pattern}")
            # Write/update the SHA256 marker to identify the extracted content
            file(WRITE "${_marker}" "${_sha256}\n")
            set(_source_fresh TRUE)
        endif()
    endif()

    set(${out_src_var} "${_src_dir}" PARENT_SCOPE)
    # Export freshness flag for callers to decide whether to patch
    set(${_upper}_SOURCE_FRESH ${_source_fresh} PARENT_SCOPE)
endfunction()

    # --- Git clone utility (supports checkout of specific commit with retries) ---
    # Usage:
    #   thirdparty_git_clone_and_checkout(<repo_url> <dest_dir> <commit_hash>)
    # Behavior:
    #   * If dest_dir exists and already at the requested commit, it's reused.
    #   * Otherwise dest_dir is removed and re-cloned.
    #   * Retries clone+checkout up to 3 times.
    #   * Fails the configure ONLY if all retries fail.
    function(thirdparty_git_clone_and_checkout repo_url dest_dir commit_hash)
        # Optional behavior controlled by cache vars for per-library customization:
        #   <UPPER>_GIT_SHALLOW (default ON) -> try shallow clone limited to needed commit
        #   <UPPER>_GIT_RECURSE_SUBMODULES (default OFF) -> initialize submodules
        if(NOT repo_url OR NOT dest_dir OR NOT commit_hash)
            message(FATAL_ERROR "[thirdparty_git] Missing arguments: repo_url='${repo_url}' dest_dir='${dest_dir}' commit='${commit_hash}'")
        endif()

        find_program(GIT_EXECUTABLE git)
        if(NOT GIT_EXECUTABLE)
            message(FATAL_ERROR "[thirdparty_git] git executable not found in PATH")
        endif()

        # Derive upper name from dest_dir basename (best effort) to read feature flags
        get_filename_component(_basename "${dest_dir}" NAME)
        string(TOUPPER "${_basename}" _lib_upper1)
        string(REPLACE "-" "_" _lib_upper "${_lib_upper1}")
        set(_shallow_default ON)
        if(DEFINED ${_lib_upper}_GIT_SHALLOW AND NOT ${_lib_upper}_GIT_SHALLOW)
            set(_shallow_default OFF)
        endif()
        set(_recurse_default OFF)
        if(DEFINED ${_lib_upper}_GIT_RECURSE_SUBMODULES AND ${_lib_upper}_GIT_RECURSE_SUBMODULES)
            set(_recurse_default ON)
        endif()

        # Fast path: existing repo at correct commit
        if(EXISTS "${dest_dir}/.git")
            execute_process(
                COMMAND ${GIT_EXECUTABLE} -C "${dest_dir}" rev-parse HEAD
                OUTPUT_VARIABLE _current_commit
                OUTPUT_STRIP_TRAILING_WHITESPACE
                RESULT_VARIABLE _rev_parse_result
            )
            if(_rev_parse_result EQUAL 0 AND _current_commit STREQUAL "${commit_hash}")
                message(DEBUG "[thirdparty_git] Reusing existing clone ${dest_dir} at commit ${commit_hash}")
                # Optionally ensure submodules if requested
                if(_recurse_default)
                    execute_process(COMMAND ${GIT_EXECUTABLE} -C "${dest_dir}" submodule update --init --recursive)
                endif()
                return()
            endif()
            message(DEBUG "[thirdparty_git] Existing directory ${dest_dir} not at desired commit (have='${_current_commit}', want='${commit_hash}'), removing")
            file(REMOVE_RECURSE "${dest_dir}")
        endif()

        set(_max_retries 3)
        set(_attempt 1)
        set(_success FALSE)
        while(_attempt LESS_EQUAL _max_retries AND NOT _success)
            if(_attempt GREATER 1)
                message(STATUS "[thirdparty_git] Retry ${_attempt}/${_max_retries} cloning ${repo_url}")
            else()
                message(STATUS "[thirdparty_git] Cloning ${repo_url} (commit ${commit_hash}) to ${dest_dir}")
            endif()

            get_filename_component(_parent "${dest_dir}" DIRECTORY)
            file(MAKE_DIRECTORY "${_parent}")

            set(_clone_result 1)
            # Try shallow first if enabled
            if(_shallow_default)
                execute_process(
                    COMMAND ${GIT_EXECUTABLE} clone --no-checkout --filter=blob:none --depth 1 ${repo_url} "${dest_dir}"
                    RESULT_VARIABLE _clone_result
                    OUTPUT_QUIET ERROR_QUIET
                )
                if(NOT _clone_result EQUAL 0)
                    message(WARNING "[thirdparty_git] shallow clone failed, will retry full clone (attempt ${_attempt})")
                    if(EXISTS "${dest_dir}")
                        file(REMOVE_RECURSE "${dest_dir}")
                    endif()
                endif()
            endif()

            if(NOT _shallow_default OR NOT _clone_result EQUAL 0)
                execute_process(
                    COMMAND ${GIT_EXECUTABLE} clone ${repo_url} "${dest_dir}"
                    RESULT_VARIABLE _clone_result_full
                    OUTPUT_QUIET ERROR_QUIET
                )
                set(_clone_result ${_clone_result_full})
            endif()

            if(NOT _clone_result EQUAL 0)
                message(WARNING "[thirdparty_git] git clone failed (attempt ${_attempt}) for ${repo_url}")
                if(EXISTS "${dest_dir}")
                    file(REMOVE_RECURSE "${dest_dir}")
                endif()
                math(EXPR _attempt "${_attempt} + 1")
                continue()
            endif()

            # For shallow clone we may need to fetch the commit if not in initial depth
            execute_process(
                COMMAND ${GIT_EXECUTABLE} -C "${dest_dir}" rev-parse --verify ${commit_hash}^{commit}
                RESULT_VARIABLE _have_commit
                OUTPUT_QUIET ERROR_QUIET
            )
            if(NOT _have_commit EQUAL 0)
                execute_process(
                    COMMAND ${GIT_EXECUTABLE} -C "${dest_dir}" fetch --depth 1 origin ${commit_hash}
                    OUTPUT_QUIET ERROR_QUIET
                )
            endif()

            # Checkout specific commit
            execute_process(
                COMMAND ${GIT_EXECUTABLE} -C "${dest_dir}" checkout --detach ${commit_hash}
                RESULT_VARIABLE _checkout_result
                OUTPUT_QUIET ERROR_QUIET
            )
            if(_checkout_result EQUAL 0)
                if(_recurse_default)
                    execute_process(COMMAND ${GIT_EXECUTABLE} -C "${dest_dir}" submodule update --init --recursive)
                endif()
                message(STATUS "[thirdparty_git] Checked out commit ${commit_hash} in ${dest_dir}")
                set(_success TRUE)
            else()
                message(WARNING "[thirdparty_git] git checkout ${commit_hash} failed (attempt ${_attempt}) in ${dest_dir}")
                file(REMOVE_RECURSE "${dest_dir}")
                math(EXPR _attempt "${_attempt} + 1")
            endif()
        endwhile()

        if(NOT _success)
            message(FATAL_ERROR "[thirdparty_git] Failed to obtain ${repo_url} at commit ${commit_hash} after ${_max_retries} attempts")
        endif()
    endfunction()

function(thirdparty_extract_and_rename tarfile srcdir pattern)
    file(GLOB _old_dirs "${pattern}")
    foreach(_d ${_old_dirs})
        if(EXISTS "${_d}")
            file(REMOVE_RECURSE "${_d}")
        endif()
    endforeach()

    get_filename_component(_workdir "${srcdir}" DIRECTORY)
    file(MAKE_DIRECTORY "${_workdir}")
    string(RANDOM LENGTH 8 ALPHABET 0123456789abcdef _rand)
    set(_tmp_extract_dir "${_workdir}/.extract_${_rand}")
    file(MAKE_DIRECTORY "${_tmp_extract_dir}")

    # Try to use GNU tar for progress dots; otherwise use system tar without unsupported flags; fall back to cmake -E tar
    set(_extract_failed 1)
    find_program(GNU_TAR gtar)
    if(GNU_TAR)
        execute_process(
            COMMAND ${GNU_TAR} --extract --file "${tarfile}" --checkpoint=1000 --checkpoint-action=dot
            WORKING_DIRECTORY "${_tmp_extract_dir}"
            RESULT_VARIABLE _extract_failed
        )
    else()
        find_program(SYS_TAR tar)
        if(SYS_TAR)
            execute_process(
                COMMAND ${SYS_TAR} --version
                OUTPUT_VARIABLE _tar_ver_out
                ERROR_VARIABLE _tar_ver_err
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_STRIP_TRAILING_WHITESPACE
                RESULT_VARIABLE _tar_ver_res
            )
            set(_use_checkpoint FALSE)
            if(_tar_ver_res EQUAL 0)
                if(_tar_ver_out MATCHES "GNU tar" OR _tar_ver_err MATCHES "GNU tar")
                    set(_use_checkpoint TRUE)
                endif()
            endif()
            if(_use_checkpoint)
                execute_process(
                    COMMAND ${SYS_TAR} --extract --file "${tarfile}" --checkpoint=1000 --checkpoint-action=dot
                    WORKING_DIRECTORY "${_tmp_extract_dir}"
                    RESULT_VARIABLE _extract_failed
                )
            else()
                execute_process(
                    COMMAND ${SYS_TAR} -xf "${tarfile}"
                    WORKING_DIRECTORY "${_tmp_extract_dir}"
                    RESULT_VARIABLE _extract_failed
                    OUTPUT_QUIET ERROR_QUIET
                )
            endif()
        endif()
    endif()
    if(_extract_failed)
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xf "${tarfile}"
            WORKING_DIRECTORY "${_tmp_extract_dir}"
            RESULT_VARIABLE _extract_failed
        )
    endif()
    if(_extract_failed)
        file(REMOVE_RECURSE "${_tmp_extract_dir}")
        message(FATAL_ERROR "Failed to extract ${tarfile}")
    endif()

    file(GLOB _top_entries "${_tmp_extract_dir}/*")
    set(_dirs)
    set(_files)
    foreach(_e ${_top_entries})
        if(IS_DIRECTORY "${_e}")
            list(APPEND _dirs "${_e}")
        else()
            list(APPEND _files "${_e}")
        endif()
    endforeach()

    if(EXISTS "${srcdir}")
        file(REMOVE_RECURSE "${srcdir}")
    endif()

    list(LENGTH _dirs _dir_count)
    list(LENGTH _files _file_count)

    if(_dir_count EQUAL 1 AND _file_count EQUAL 0)
        list(GET _dirs 0 _only_dir)
        file(RENAME "${_only_dir}" "${srcdir}")
        file(REMOVE_RECURSE "${_tmp_extract_dir}")
    else()
        file(RENAME "${_tmp_extract_dir}" "${srcdir}")
    endif()
endfunction()

function(thirdparty_cmake_configure srcdir builddir)
    cmake_parse_arguments(PARSE_ARGV 2
        ARG
        "FORCE_CONFIGURE"
        "VALIDATION_PATTERN;SOURCE_SUBDIR;VALIDATION_MODE"
        "VALIDATION_FILES;CMAKE_ARGS")

    set(_actual_src_dir "${srcdir}")
    if(ARG_SOURCE_SUBDIR)
        set(_actual_src_dir "${srcdir}/${ARG_SOURCE_SUBDIR}")
    endif()

    if(NOT EXISTS "${_actual_src_dir}/CMakeLists.txt")
        message(WARNING "[thirdparty_cmake_configure] ${_actual_src_dir}/CMakeLists.txt not found, skip configure.")
        set(CMAKE_CURRENT_FUNCTION_RESULT 1 PARENT_SCOPE)
        return()
    endif()

    if(NOT ARG_FORCE_CONFIGURE)
        set(need_configure TRUE)
        set(_mode ANY)
        if(ARG_VALIDATION_MODE)
            string(TOUPPER "${ARG_VALIDATION_MODE}" _mode)
        endif()
        if(ARG_VALIDATION_FILES)
            if(_mode STREQUAL "ALL")
                set(need_configure FALSE)
                foreach(file IN LISTS ARG_VALIDATION_FILES)
                    if(NOT EXISTS "${file}")
                        set(need_configure TRUE)
                        break()
                    endif()
                endforeach()
                if(NOT need_configure)
                    message(DEBUG "[thirdparty_cmake_configure] Skip: validation mode=ALL and all files exist.")
                endif()
            elseif(_mode STREQUAL "ANY")
                foreach(file IN LISTS ARG_VALIDATION_FILES)
                    if(EXISTS "${file}")
                        set(need_configure FALSE)
                        message(DEBUG "[thirdparty_cmake_configure] Skip: validation mode=ANY and file '${file}' exists.")
                        break()
                    endif()
                endforeach()
            else()
                message(WARNING "[thirdparty_cmake_configure] Unknown VALIDATION_MODE='${_mode}', defaulting to ALL")
                # fall back to ALL semantics: already handled by initial logic, so re-run
                set(need_configure FALSE)
                foreach(file IN LISTS ARG_VALIDATION_FILES)
                    if(NOT EXISTS "${file}")
                        set(need_configure TRUE)
                        break()
                    endif()
                endforeach()
            endif()
        elseif(ARG_VALIDATION_PATTERN)
            file(GLOB _matched_files "${ARG_VALIDATION_PATTERN}")
            if(_matched_files)
                set(need_configure FALSE)
                message(STATUS "[thirdparty_cmake_configure] Skip: pattern '${ARG_VALIDATION_PATTERN}' matched.")
            endif()
        endif()

        if(NOT need_configure)
            set(CMAKE_CURRENT_FUNCTION_RESULT 0 PARENT_SCOPE)
            return()
        endif()
    endif()

    # Argument hash based skip (after validation logic but before actual configure)
    set(_cmake_args ${ARG_CMAKE_ARGS})
    set(_arg_fingerprint "${_actual_src_dir};${_cmake_args};${THIRDPARTY_CMAKE_PREFIX_PATH_STRING}")
    string(SHA1 _arg_hash "${_arg_fingerprint}")
    set(_hash_file "${builddir}/.thirdparty_cmake_arg_hash")
    if(EXISTS "${builddir}/CMakeCache.txt" AND EXISTS "${_hash_file}")
        file(READ "${_hash_file}" _prev_hash)
        string(STRIP "${_prev_hash}" _prev_hash)
        if(_prev_hash STREQUAL "${_arg_hash}")
            message(DEBUG "[thirdparty_cmake_configure] Skip: argument hash unchanged (${_arg_hash}).")
            set(CMAKE_CURRENT_FUNCTION_RESULT 0 PARENT_SCOPE)
            return()
        endif()
    endif()

    message(STATUS "[thirdparty_cmake_configure] Configuring ${_actual_src_dir} to ${builddir}")

    thirdparty_configure_ninja_optimization(_cmake_args)

    set(_cmake_cmd_str "${CMAKE_COMMAND} -S \"${_actual_src_dir}\" -B \"${builddir}\"")
    foreach(_arg ${_cmake_args})
        set(_cmake_cmd_str "${_cmake_cmd_str} ${_arg}")
    endforeach()
    if(THIRDPARTY_CMAKE_PREFIX_PATH_STRING)
        set(_cmake_cmd_str "${_cmake_cmd_str} -DCMAKE_PREFIX_PATH=${THIRDPARTY_CMAKE_PREFIX_PATH_STRING}")
    endif()
    message(DEBUG "[thirdparty_cmake_configure] CMake command: ${_cmake_cmd_str}")

    if(THIRDPARTY_CMAKE_PREFIX_PATH_STRING)
        execute_process(
            COMMAND ${CMAKE_COMMAND} -S "${_actual_src_dir}" -B "${builddir}" 
                    ${_cmake_args} "-DCMAKE_PREFIX_PATH=${THIRDPARTY_CMAKE_PREFIX_PATH_STRING}"
            RESULT_VARIABLE result
        )
    else()
        execute_process(
            COMMAND ${CMAKE_COMMAND} -S "${_actual_src_dir}" -B "${builddir}" ${_cmake_args}
            RESULT_VARIABLE result
        )
    endif()

    if(NOT result EQUAL 0)
        message(FATAL_ERROR "[thirdparty_cmake_configure] CMake configure failed for ${_actual_src_dir} with exit code ${result}")
    else()
        message(STATUS "[thirdparty_cmake_configure] Successfully configured ${_actual_src_dir}")
        file(WRITE "${_hash_file}" "${_arg_hash}\n")
    endif()

    set(CMAKE_CURRENT_FUNCTION_RESULT "${result}" PARENT_SCOPE)
endfunction()

function(thirdparty_cmake_install builddir installdir)
    # Add optional parameters: check file list (to verify if component is already installed)
    # Parameter format: VALIDATION_FILES file1 [file2 ...] or VALIDATION_PATTERN pattern
    # NO_REGISTER_PREFIX_PATH: skip registering to CMAKE_PREFIX_PATH (useful for compiler-only installs)
    set(options NO_REGISTER_PREFIX_PATH)
    set(oneValueArgs VALIDATION_PATTERN)
    set(multiValueArgs VALIDATION_FILES)
    cmake_parse_arguments(PARSE_ARGV 2 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

    # Normalize validation file paths to absolute (avoid relative path surprises)
    set(_normalized_validation_files)
    if(ARG_VALIDATION_FILES)
        foreach(_vf IN LISTS ARG_VALIDATION_FILES)
            set(_raw_vf "${_vf}")
            get_filename_component(_abs_vf "${_vf}" ABSOLUTE)
            # Defensive heuristic: if the raw path collapses to /lib/... or /include/... and
            # the expected install prefix is known, prepend installdir (probable undefined var earlier)
            if(_abs_vf MATCHES "^/lib/" OR _abs_vf MATCHES "^/include/")
                # Only adjust if installdir exists (or will exist) and not already represented
                if(NOT "${installdir}" STREQUAL "")
                    set(_candidate "${installdir}${_abs_vf}")
                    # If candidate exists OR raw looked suspicious, adopt candidate
                    if(EXISTS "${_candidate}" OR NOT EXISTS "${_abs_vf}")
                        message(WARNING "[thirdparty_cmake_install] Suspicious validation path '${_raw_vf}' -> adjusting to '${_candidate}' (likely undefined *_INSTALL_DIR at call site)")
                        set(_abs_vf "${_candidate}")
                    endif()
                endif()
            endif()
            list(APPEND _normalized_validation_files "${_abs_vf}")
        endforeach()
    endif()

    if(DEFINED HALO_THIRDPARTY_VERBOSE_SUPPRESS AND NOT HALO_THIRDPARTY_VERBOSE_SUPPRESS)
        if(ARG_VALIDATION_FILES)
            message(STATUS "[thirdparty_cmake_install] Raw validation files for ${installdir}:")
            foreach(_rv IN LISTS ARG_VALIDATION_FILES)
                message(STATUS "  RAW: ${_rv}")
            endforeach()
            message(STATUS "[thirdparty_cmake_install] Normalized validation files for ${installdir}:")
            foreach(_nv IN LISTS _normalized_validation_files)
                message(STATUS "  NORM: ${_nv}")
            endforeach()
        endif()
    endif()

    # Optional force reinstall (overrides skip logic)
    if(DEFINED HALO_FORCE_THIRDPARTY_REINSTALL AND HALO_FORCE_THIRDPARTY_REINSTALL)
        set(_force_reinstall TRUE)
    else()
        set(_force_reinstall FALSE)
    endif()

    # Decide message level for skip related diagnostics
    set(_skip_msg_mode DEBUG)
    if(DEFINED HALO_THIRDPARTY_VERBOSE_SUPPRESS AND NOT HALO_THIRDPARTY_VERBOSE_SUPPRESS)
        set(_skip_msg_mode STATUS)
    endif()

    # Install stamp captures: list of validation files + their mtimes + a hash of their paths
    set(_stamp_file "${installdir}/.halo_thirdparty_install_stamp")
    set(_need_install TRUE)
    set(_missing_files)
    if(NOT _force_reinstall)
        if(_normalized_validation_files)
            set(_all_exist TRUE)
            foreach(_file IN LISTS _normalized_validation_files)
                if(NOT EXISTS "${_file}")
                    list(APPEND _missing_files "${_file}")
                    set(_all_exist FALSE)
                endif()
            endforeach()
            if(_all_exist AND EXISTS "${_stamp_file}")
                # Basic stamp validation: ensure stamp references same set hash
                file(READ "${_stamp_file}" _stamp_content)
                string(REGEX MATCH "^PATH_HASH=([A-Fa-f0-9]+)" _ph_line "${_stamp_content}")
                if(_ph_line)
                    string(SHA1 _current_path_hash "${_normalized_validation_files}")
                    string(REGEX REPLACE "^PATH_HASH=([A-Fa-f0-9]+).*" "\\1" _stamp_path_hash "${_stamp_content}")
                    if(_current_path_hash STREQUAL "${_stamp_path_hash}")
                        # Assume valid -> skip install
                        set(_need_install FALSE)
                        if(_skip_msg_mode STREQUAL "STATUS")
                            message(STATUS "[thirdparty_cmake_install] Skip install (stamp valid) for ${installdir}")
                        else()
                            message(DEBUG "[thirdparty_cmake_install] Skip install (stamp valid) for ${installdir}")
                        endif()
                    endif()
                endif()
            endif()
        elseif(ARG_VALIDATION_PATTERN)
            file(GLOB _matched_files "${ARG_VALIDATION_PATTERN}")
            if(_matched_files AND EXISTS "${_stamp_file}")
                set(_need_install FALSE)
                if(_skip_msg_mode STREQUAL "STATUS")
                    message(STATUS "[thirdparty_cmake_install] Skip install (pattern+stamp) for ${installdir}")
                else()
                    message(DEBUG "[thirdparty_cmake_install] Skip install (pattern+stamp) for ${installdir}")
                endif()
            endif()
        endif()
    else()
        message(STATUS "[thirdparty_cmake_install] Force reinstall enabled for ${installdir}")
    endif()

    if(NOT _need_install AND _missing_files)
        # Safety: if skip decided but missing list not empty (shouldn't happen), override
        set(_need_install TRUE)
    endif()

    if(NOT _need_install)
        set(_build_result 0)
    else()
        if(_missing_files)
            message(STATUS "[thirdparty_cmake_install] Missing validation files triggering install for ${installdir}:")
            foreach(_mf IN LISTS _missing_files)
                message(STATUS "  * ${_mf}")
            endforeach()
        elseif(_force_reinstall)
            message(STATUS "[thirdparty_cmake_install] Reinstalling despite existing files (force enabled)")
        else()
            message(STATUS "[thirdparty_cmake_install] Proceeding with install for ${installdir} (no valid stamp)")
        endif()
        # Build and install logic follows
        if(NOT EXISTS "${builddir}")
            message(WARNING "[thirdparty_cmake_install] Build directory ${builddir} not found, skip install.")
            set(_build_result 1)
        else()
            # Proceed with build and install
            message(DEBUG "[thirdparty_cmake_install] Building and installing from ${builddir} to ${installdir}")

            # Use optimized build command based on generator
            find_program(NINJA_EXECUTABLE ninja)
            if(NINJA_EXECUTABLE AND EXISTS "${builddir}/build.ninja")
                # Use Ninja directly for better performance
                message(DEBUG "[thirdparty_cmake_install] Using Ninja for optimized build")
                execute_process(
                    COMMAND ${NINJA_EXECUTABLE} -C "${builddir}"
                    RESULT_VARIABLE _build_result
                )
            else()
                # Fallback to standard CMake build with centralized job configuration
                thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _parallel_jobs)

                message(STATUS "[thirdparty_cmake_install] Build command: ${CMAKE_COMMAND} --build \"${builddir}\" --parallel ${_parallel_jobs}")

                execute_process(
                    COMMAND ${CMAKE_COMMAND} --build "${builddir}" --parallel ${_parallel_jobs}
                    RESULT_VARIABLE _build_result
                )
            endif()

            if(_build_result EQUAL 0)
                # Create install directory if it doesn't exist
                file(MAKE_DIRECTORY "${installdir}")

                message(STATUS "[thirdparty_cmake_install] Install command: ${CMAKE_COMMAND} --install \"${builddir}\" --prefix \"${installdir}\"")

                # Install to the specified directory
                execute_process(
                    COMMAND ${CMAKE_COMMAND} --install "${builddir}" --prefix "${installdir}"
                    RESULT_VARIABLE _install_result
                )
                if(NOT _install_result EQUAL 0)
                    message(WARNING "[thirdparty_cmake_install] Install failed for ${builddir} to ${installdir}")
                    set(_build_result ${_install_result})
                else()
                    message(STATUS "[thirdparty_cmake_install] Successfully installed to ${installdir}")
                    # Write/update stamp file capturing validation file list hash & timestamps
                    if(_normalized_validation_files)
                        string(SHA1 _path_hash "${_normalized_validation_files}")
                        file(WRITE "${_stamp_file}" "PATH_HASH=${_path_hash}\n")
                        foreach(_vf IN LISTS _normalized_validation_files)
                            if(EXISTS "${_vf}")
                                file(TIMESTAMP "${_vf}" _ts UTC)
                                file(APPEND "${_stamp_file}" "FILE=${_vf}|${_ts}\n")
                            endif()
                        endforeach()
                        message(DEBUG "[thirdparty_cmake_install] Wrote stamp ${_stamp_file}")
                    elseif(ARG_VALIDATION_PATTERN)
                        file(WRITE "${_stamp_file}" "PATTERN=${ARG_VALIDATION_PATTERN}\n")
                        message(DEBUG "[thirdparty_cmake_install] Wrote pattern stamp ${_stamp_file}")
                    endif()
                    # Registration is handled at the end of this function to avoid duplication
                endif()
            else()
                message(WARNING "[thirdparty_cmake_install] Build failed for ${builddir}, skip install.")
            endif()
        endif() # Close the builddir exists check
    endif() # Close the _need_install check

    # Register to CMAKE_PREFIX_PATH unless explicitly disabled
    # - If we needed to install: register the newly installed component
    # - If we skipped install: register the existing component (ensures consistency)
    # - NO_REGISTER_PREFIX_PATH: skip registration (useful for compiler-only installs like thrift)
    if(NOT ARG_NO_REGISTER_PREFIX_PATH)
        thirdparty_register_to_cmake_prefix_path("${installdir}")
        message(DEBUG "[thirdparty_cmake_install] Registered ${installdir} to CMAKE_PREFIX_PATH")
    endif()

    set(${CMAKE_CURRENT_FUNCTION_RESULT} ${_build_result} PARENT_SCOPE)
endfunction()

# Common optimization flags and CMake policy settings for all third-party libraries
# This replaces the need to modify source files with file patches
function(thirdparty_get_optimization_flags output_var)
    # Parse optional component name for dependency resolution
    set(options "")
    set(oneValueArgs COMPONENT)
    set(multiValueArgs "")
    cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
    set(_opt_flags)
    
    # Base optimization flags
    list(APPEND _opt_flags
        # Use compilers from main project
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}

        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DBUILD_SHARED_LIBS:BOOL=OFF
        -DCMAKE_CXX_STANDARD=23
        -DCMAKE_CXX_STANDARD_REQUIRED=ON
        -DBUILD_TESTING=OFF
        -DCMAKE_SUPPRESS_DEVELOPER_WARNINGS=ON
        -DCMAKE_WARN_DEPRECATED=OFF
        -DBUILD_TESTS=OFF
        -DBUILD_EXAMPLES=OFF

        -Wno-dev
        --no-warn-unused-cli

        # Boost
        -DBOOST_ROOT=${THIRDPARTY_INSTALL_DIR}/boost
        -DBOOST_INCLUDEDIR=${THIRDPARTY_INSTALL_DIR}/boost/include
        -DBOOST_LIBRARYDIR=${THIRDPARTY_INSTALL_DIR}/boost/lib
        -DBOOST_LINK_STATIC=ON
        -DBoost_USE_STATIC_LIBS=ON
        -DBoost_USE_MULTITHREADED=ON
        -DBoost_USE_STATIC_RUNTIME=ON
        -DBoost_NO_SYSTEM_PATHS=ON
    )

    # libc++ configuration for cross-platform consistency
    # Use the same libc++ flags detected by the main project
    # Create base variables that components can extend by appending their own flags
    set(HALO_CMAKE_C_FLAGS_BASE "")
    set(HALO_CMAKE_CXX_FLAGS_BASE "")
    set(HALO_CMAKE_EXE_LINKER_FLAGS_BASE "")
    set(HALO_CMAKE_SHARED_LINKER_FLAGS_BASE "")
    set(HALO_CMAKE_MODULE_LINKER_FLAGS_BASE "")
    
    # Initialize base flags with existing CMAKE flags (including those set by FindLinker.cmake)
    if(DEFINED CMAKE_C_FLAGS AND CMAKE_C_FLAGS)
        set(HALO_CMAKE_C_FLAGS_BASE "${CMAKE_C_FLAGS}")
    endif()
    if(DEFINED CMAKE_CXX_FLAGS AND CMAKE_CXX_FLAGS)
        set(HALO_CMAKE_CXX_FLAGS_BASE "${CMAKE_CXX_FLAGS}")
    endif()
    if(DEFINED CMAKE_EXE_LINKER_FLAGS AND CMAKE_EXE_LINKER_FLAGS)
        set(HALO_CMAKE_EXE_LINKER_FLAGS_BASE "${CMAKE_EXE_LINKER_FLAGS}")
        message(DEBUG "[thirdparty] Inherited CMAKE_EXE_LINKER_FLAGS: ${CMAKE_EXE_LINKER_FLAGS}")
    endif()
    if(DEFINED CMAKE_SHARED_LINKER_FLAGS AND CMAKE_SHARED_LINKER_FLAGS)
        set(HALO_CMAKE_SHARED_LINKER_FLAGS_BASE "${CMAKE_SHARED_LINKER_FLAGS}")
        message(DEBUG "[thirdparty] Inherited CMAKE_SHARED_LINKER_FLAGS: ${CMAKE_SHARED_LINKER_FLAGS}")
    endif()
    if(DEFINED CMAKE_MODULE_LINKER_FLAGS AND CMAKE_MODULE_LINKER_FLAGS)
        set(HALO_CMAKE_MODULE_LINKER_FLAGS_BASE "${CMAKE_MODULE_LINKER_FLAGS}")
        message(DEBUG "[thirdparty] Inherited CMAKE_MODULE_LINKER_FLAGS: ${CMAKE_MODULE_LINKER_FLAGS}")
    endif()
    
    # Unified linker propagation (final): only propagate explicit HALO_LINKER path if provided.
    if(HALO_LINKER)
        list(APPEND _opt_flags -DCMAKE_LINKER=${HALO_LINKER})
    endif()
    
    # --- Ninja Generator Support for faster builds ---
    # Check if Ninja is available and use it for third-party libraries
    find_program(NINJA_EXECUTABLE ninja)
    if(NINJA_EXECUTABLE)
        list(APPEND _opt_flags -GNinja)
        message(DEBUG "[thirdparty] Using Ninja generator for faster third-party builds")
    else()
        # Fallback to default generator with parallel make support
        thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _make_jobs)
        list(APPEND _opt_flags -DCMAKE_BUILD_PARALLEL_LEVEL=${_make_jobs})
        message(STATUS "[thirdparty] Ninja not found, using default generator with ${_make_jobs} parallel jobs")
    endif()
    
    if(APPLE)
        if(DEFINED HALO_MACOS_DEPLOYMENT_TARGET AND HALO_MACOS_DEPLOYMENT_TARGET)
            set(_macos_target "${HALO_MACOS_DEPLOYMENT_TARGET}")
        elseif(DEFINED CMAKE_OSX_DEPLOYMENT_TARGET AND CMAKE_OSX_DEPLOYMENT_TARGET)
            set(_macos_target "${CMAKE_OSX_DEPLOYMENT_TARGET}")
        endif()
        
        list(APPEND _opt_flags
            -DCMAKE_OSX_DEPLOYMENT_TARGET=${_macos_target}
        )
    endif()
    
    # --- ccache Support for faster rebuilds ---
    # ccache is configured globally by thirdparty_setup_ccache()
    # Here we ensure it's applied to individual third-party library builds
    thirdparty_get_ccache_executable(_ccache_path)
    if(_ccache_path)
        # Add explicit compiler launcher flags to ensure ccache works even if 
        # the third-party library doesn't inherit global CMAKE_*_COMPILER_LAUNCHER
        list(APPEND _opt_flags 
            -DCMAKE_C_COMPILER_LAUNCHER=${_ccache_path}
            -DCMAKE_CXX_COMPILER_LAUNCHER=${_ccache_path}
        )
    endif()
    
    # Modern CMake policy defaults to avoid compatibility issues
    # This eliminates the need for source file modifications
    list(APPEND _opt_flags
        # Force minimum policy version to avoid compatibility errors
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
        # CMP0000: Require cmake_minimum_required command - set to OLD to suppress warning
        -DCMAKE_POLICY_DEFAULT_CMP0000=OLD
        # CMP0042: macOS @rpath in target's install name
        -DCMAKE_POLICY_DEFAULT_CMP0042=NEW
        # CMP0063: Honor visibility properties for all target types
        -DCMAKE_POLICY_DEFAULT_CMP0063=NEW
        # CMP0077: option() honors normal variables (critical for BUILD_SHARED_LIBS)
        -DCMAKE_POLICY_DEFAULT_CMP0077=NEW
        # CMP0076: target_sources() command converts relative paths to absolute
        -DCMAKE_POLICY_DEFAULT_CMP0076=NEW
        # CMP0079: target_link_libraries() allows use with targets in other directories
        -DCMAKE_POLICY_DEFAULT_CMP0079=NEW
    )
    
    # Automatically add dependency CMAKE_ARGS if component is specified
    if(ARG_COMPONENT)
        # Use the cached CMAKE_PREFIX_PATH for child cmake invocations
        get_property(_cmake_prefix_path CACHE CMAKE_PREFIX_PATH PROPERTY VALUE)
        if(_cmake_prefix_path)
            list(LENGTH _cmake_prefix_path _path_count)
            message(DEBUG "[thirdparty] Cache CMAKE_PREFIX_PATH has ${_path_count} paths for ${ARG_COMPONENT}")
            set(_cmake_prefix_path_string "${_cmake_prefix_path}")
            set(THIRDPARTY_CMAKE_PREFIX_PATH_STRING "${_cmake_prefix_path_string}" PARENT_SCOPE)
        else()
            message(DEBUG "[thirdparty] Cache CMAKE_PREFIX_PATH empty for ${ARG_COMPONENT}")
            set(THIRDPARTY_CMAKE_PREFIX_PATH_STRING "" PARENT_SCOPE)
        endif()
    endif()
    
    # ============================================================================
    # LTO Isolation: Explicitly disable IPO for third-party libraries
    # ============================================================================
    # The main project may have CMAKE_INTERPROCEDURAL_OPTIMIZATION=ON with custom
    # CMAKE_*_COMPILE_OPTIONS_IPO settings. We explicitly disable IPO for third-party
    # libraries to prevent LTO flag propagation and ensure consistent builds.
    #
    # Key points:
    # 1. CMAKE_INTERPROCEDURAL_OPTIMIZATION, CMAKE_*_COMPILE_OPTIONS_IPO are independent
    #    from CMAKE_*_FLAGS and CMAKE_*_LINKER_FLAGS
    # 2. Without explicit settings, child CMake processes could inherit or auto-detect
    #    different IPO defaults (e.g., -flto=thin on macOS)
    # 3. We force IPO=OFF to guarantee third-party libraries build without LTO
    list(APPEND _opt_flags
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
    )
    message(DEBUG "[thirdparty] LTO explicitly disabled for third-party libraries (CMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF)")

    if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND PKG_CONFIG_EXECUTABLE)
        list(APPEND _opt_flags
            -DPKG_CONFIG_EXECUTABLE=${PKG_CONFIG_EXECUTABLE}
        )
        message(DEBUG "[thirdparty] Propagating pkg-config executable: ${PKG_CONFIG_EXECUTABLE}")
    endif()
    
    # Combine and append all CMAKE flags at the end to avoid overrides
    if(HALO_CMAKE_C_FLAGS_BASE)
        # Quote as single argument to preserve spaces in composed flags (e.g. "-O3 -DNDEBUG -march=...")
        list(APPEND _opt_flags "-DCMAKE_C_FLAGS=${HALO_CMAKE_C_FLAGS_BASE}")
        message(DEBUG "[thirdparty] Combined CMAKE_C_FLAGS: ${HALO_CMAKE_C_FLAGS_BASE}")
    endif()
    if(HALO_CMAKE_CXX_FLAGS_BASE)
        list(APPEND _opt_flags "-DCMAKE_CXX_FLAGS=${HALO_CMAKE_CXX_FLAGS_BASE}")
        message(DEBUG "[thirdparty] Combined CMAKE_CXX_FLAGS: ${HALO_CMAKE_CXX_FLAGS_BASE}")
    endif()
    if(HALO_CMAKE_EXE_LINKER_FLAGS_BASE)
        list(APPEND _opt_flags "-DCMAKE_EXE_LINKER_FLAGS=${HALO_CMAKE_EXE_LINKER_FLAGS_BASE}")
        message(DEBUG "[thirdparty] Combined CMAKE_EXE_LINKER_FLAGS: ${HALO_CMAKE_EXE_LINKER_FLAGS_BASE}")
    endif()
    if(HALO_CMAKE_SHARED_LINKER_FLAGS_BASE)
        list(APPEND _opt_flags "-DCMAKE_SHARED_LINKER_FLAGS=${HALO_CMAKE_SHARED_LINKER_FLAGS_BASE}")
        message(DEBUG "[thirdparty] Combined CMAKE_SHARED_LINKER_FLAGS: ${HALO_CMAKE_SHARED_LINKER_FLAGS_BASE}")
    endif()
    if(HALO_CMAKE_MODULE_LINKER_FLAGS_BASE)
        list(APPEND _opt_flags "-DCMAKE_MODULE_LINKER_FLAGS=${HALO_CMAKE_MODULE_LINKER_FLAGS_BASE}")
        message(DEBUG "[thirdparty] Combined CMAKE_MODULE_LINKER_FLAGS: ${HALO_CMAKE_MODULE_LINKER_FLAGS_BASE}")
    endif()
    
    # Export base variables to parent scope for components to use
    set(HALO_CMAKE_C_FLAGS_BASE "${HALO_CMAKE_C_FLAGS_BASE}" PARENT_SCOPE)
    set(HALO_CMAKE_CXX_FLAGS_BASE "${HALO_CMAKE_CXX_FLAGS_BASE}" PARENT_SCOPE)
    set(HALO_CMAKE_EXE_LINKER_FLAGS_BASE "${HALO_CMAKE_EXE_LINKER_FLAGS_BASE}" PARENT_SCOPE)
    set(HALO_CMAKE_SHARED_LINKER_FLAGS_BASE "${HALO_CMAKE_SHARED_LINKER_FLAGS_BASE}" PARENT_SCOPE)
    set(HALO_CMAKE_MODULE_LINKER_FLAGS_BASE "${HALO_CMAKE_MODULE_LINKER_FLAGS_BASE}" PARENT_SCOPE)
    
    set(${output_var} "${_opt_flags}" PARENT_SCOPE)
endfunction()

# --- Validation Path Audit ---
# Collect suspicious validation file paths that likely result from undefined *_INSTALL_DIR
# patterns at call time. Criteria:
#   * Absolute path beginning with /lib/ or /include/
#   * Path that was auto-adjusted by heuristic in thirdparty_cmake_install
function(thirdparty_audit_collect_suspicious component raw_path reason)
    # Store as list of tuples component|path|reason
    set(_current_list "${THIRDPARTY_SUSPICIOUS_VALIDATION_PATHS}")
    list(APPEND _current_list "${component}|${raw_path}|${reason}")
    set(THIRDPARTY_SUSPICIOUS_VALIDATION_PATHS "${_current_list}" CACHE INTERNAL "Suspicious validation file paths")
endfunction()

# --- Centralized ccache Configuration ---
# This function configures ccache globally for the entire build system
# It should be called once at the beginning of the third-party build process
function(thirdparty_setup_ccache)
    find_program(CCACHE_EXECUTABLE ccache)
    if(CCACHE_EXECUTABLE)
        # ============================================================
        # Global ccache configuration for main project
        # ============================================================
        # Set ccache as the compiler launcher for the main project
        set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_EXECUTABLE} CACHE STRING "Use ccache for C++ compilation" FORCE)
        set(CMAKE_C_COMPILER_LAUNCHER ${CCACHE_EXECUTABLE} CACHE STRING "Use ccache for C compilation" FORCE)
        
        # ============================================================
        # ccache Performance Optimization
        # ============================================================
        # Set cache size to 50GB (adjust based on available disk space)
        execute_process(
            COMMAND ${CCACHE_EXECUTABLE} --max-size=15G
            OUTPUT_QUIET ERROR_QUIET
        )
        
        # Enable compression to save disk space
        execute_process(
            COMMAND ${CCACHE_EXECUTABLE} --set-config=compression=true
            OUTPUT_QUIET ERROR_QUIET
        )
        
        # Enable statistics for monitoring
        execute_process(
            COMMAND ${CCACHE_EXECUTABLE} --set-config=stats=true
            OUTPUT_QUIET ERROR_QUIET
        )
        
        # Set reasonable cache file limit
        execute_process(
            COMMAND ${CCACHE_EXECUTABLE} --max-files=0
            OUTPUT_QUIET ERROR_QUIET
        )
        
        message(STATUS "ccache configured globally: ${CCACHE_EXECUTABLE}")
        
        # ============================================================
        # Display ccache Status and Statistics
        # ============================================================
        execute_process(
            COMMAND ${CCACHE_EXECUTABLE} --show-stats
            OUTPUT_VARIABLE _ccache_stats
            ERROR_QUIET
        )
        if(_ccache_stats)
            # Extract key statistics for summary
            string(REGEX MATCH "Hits: *([0-9]+) */ *([0-9]+)" _hit_match "${_ccache_stats}")
            if(_hit_match)
                string(REGEX REPLACE ".*Hits: *([0-9]+) */ *([0-9]+).*" "\\1" _hits "${_ccache_stats}")
                string(REGEX REPLACE ".*Hits: *([0-9]+) */ *([0-9]+).*" "\\2" _total "${_ccache_stats}")
                if(_total GREATER 0)
                    math(EXPR _hit_rate "100 * ${_hits} / ${_total}")
                    message(STATUS "ccache hit rate: ${_hit_rate}% (${_hits}/${_total})")
                endif()
            endif()
            
            # Show cache size info
            string(REGEX MATCH "Cache size \\(GB\\): *([0-9.]+) */ *([0-9.]+)" _size_match "${_ccache_stats}")
            if(_size_match)
                string(REGEX REPLACE ".*Cache size \\(GB\\): *([0-9.]+) */ *([0-9.]+).*" "\\1" _used "${_ccache_stats}")
                string(REGEX REPLACE ".*Cache size \\(GB\\): *([0-9.]+) */ *([0-9.]+).*" "\\2" _max "${_ccache_stats}")
                message(STATUS "ccache storage: ${_used}GB / ${_max}GB used")
            endif()
        endif()
        
        # Export ccache path for use by other functions
        set(THIRDPARTY_CCACHE_EXECUTABLE ${CCACHE_EXECUTABLE} CACHE INTERNAL "ccache executable path")
        
    else()
        message(STATUS "ccache not found")
        message(STATUS "  Install with:")
        message(STATUS "  macOS: brew install ccache")
        message(STATUS "  Ubuntu/Debian: apt install ccache") 
        message(STATUS "  CentOS/RHEL: yum install ccache")
        message(STATUS "  ccache can significantly speed up rebuilds of third-party libraries")
    endif()
endfunction()

# --- Utility function to get ccache path if available ---
# This function provides a centralized way to check for ccache availability
function(thirdparty_get_ccache_executable output_var)
    # First check if we have a cached value from thirdparty_setup_ccache()
    get_property(_cached_ccache CACHE THIRDPARTY_CCACHE_EXECUTABLE PROPERTY VALUE)
    if(_cached_ccache)
        set(${output_var} ${_cached_ccache} PARENT_SCOPE)
        return()
    endif()
    
    # Fallback to direct detection
    find_program(_ccache_exec ccache)
    set(${output_var} ${_ccache_exec} PARENT_SCOPE)
endfunction()

function(thirdparty_setup_directories library_name)
    string(TOUPPER "${library_name}" _lib_upper)
    string(REPLACE "-" "_" _lib_upper "${_lib_upper}")
    
    # Set standard directory variables
    set(${_lib_upper}_NAME "${library_name}" PARENT_SCOPE)
    # Infer archive extension from URL when possible; fallback to .tar.gz
    set(_version "${${_lib_upper}_VERSION}")
    set(_url     "${${_lib_upper}_URL}")
    set(_extension ".tar.gz")
    if(_url)
        get_filename_component(_url_filename "${_url}" NAME)
        string(REGEX MATCH "(\\.tar\\.gz|\\.tgz|\\.tar\\.bz2|\\.tbz2|\\.tar\\.xz|\\.txz|\\.zip)$" _ext_match "${_url_filename}")
        if(_ext_match)
            set(_extension "${_ext_match}")
        elseif(_url MATCHES "\\.zip")
            set(_extension ".zip")
        endif()
    endif()
    set(${_lib_upper}_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/${library_name}-${_version}${_extension}" PARENT_SCOPE)
    set(${_lib_upper}_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${library_name}" PARENT_SCOPE)
    set(${_lib_upper}_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${library_name}" PARENT_SCOPE)
    set(${_lib_upper}_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${library_name}" PARENT_SCOPE)
    
    # Make installation directory absolute
    get_filename_component(_abs_install_dir "${THIRDPARTY_INSTALL_DIR}/${library_name}" ABSOLUTE)
    set(${_lib_upper}_INSTALL_DIR "${_abs_install_dir}" PARENT_SCOPE)
endfunction()

function(thirdparty_build_cmake_library library_name)
    # Parse arguments
    set(options)
    set(oneValueArgs EXTRACT_PATTERN SOURCE_SUBDIR)
    set(multiValueArgs VALIDATION_FILES CMAKE_ARGS CMAKE_CACHE_ARGS FILE_REPLACEMENTS)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

    # Uppercase the library name to get variable prefixes (e.g., gflags -> GFLAGS)
    string(TOUPPER "${library_name}" _upper_name)
    string(REPLACE "-" "_" _upper_name ${_upper_name}) # Handle names like "double-conversion"

    # Get component info from variables
    set(_version "${${_upper_name}_VERSION}")
    set(_url "${${_upper_name}_URL}")
    set(_sha256 "${${_upper_name}_SHA256}")

    # Set up standard directory and file names
    set(_source_dir "${THIRDPARTY_SRC_DIR}/${library_name}")
    set(_build_dir "${THIRDPARTY_BUILD_DIR}/${library_name}")
    set(_install_dir "${THIRDPARTY_INSTALL_DIR}/${library_name}")
    
    # --- Standardized download file naming ---
    # Extract filename from URL to get the correct extension (e.g., .tar.gz, .zip)
    get_filename_component(_url_filename "${_url}" NAME)
    string(REGEX MATCH "(\\.tar\\.gz|\\.tgz|\\.tar\\.bz2|\\.tbz2|\\.tar\\.xz|\\.txz|\\.zip)$" _extension "${_url_filename}")
    if(NOT _extension)
        # Fallback for URLs without extensions in the path
        if(_url MATCHES "\\.zip")
            set(_extension ".zip")
        else()
            set(_extension ".tar.gz") # Default assumption
        endif()
    endif()
    # --- End of standardized naming ---

    # Set default extract pattern if not provided
    if(NOT ARG_EXTRACT_PATTERN)
        set(ARG_EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/${library_name}-*")
    endif()

    # Acquire source (git or archive)
    thirdparty_acquire_source("${library_name}" _source_dir)

    if(ARG_FILE_REPLACEMENTS)
        # Only patch when source is freshly acquired to avoid repeated replacements
        set(_do_patch TRUE)
        if(DEFINED ${_upper_name}_SOURCE_FRESH)
            if(NOT ${${_upper_name}_SOURCE_FRESH})
                set(_do_patch FALSE)
                message(DEBUG "[thirdparty] ${library_name}: source reused; skipping FILE_REPLACEMENTS")
            endif()
        endif()

        if(_do_patch)
        list(LENGTH ARG_FILE_REPLACEMENTS _replacement_count)
        math(EXPR _group_count "${_replacement_count} / 3")
        
        if(NOT _replacement_count EQUAL 0)
            math(EXPR _remainder "${_replacement_count} % 3")
            if(NOT _remainder EQUAL 0)
                message(FATAL_ERROR "[thirdparty] FILE_REPLACEMENTS must contain groups of 3 elements: file_path, old_string, new_string")
            endif()
            
            set(_index 0)
            while(_index LESS _replacement_count)
                list(GET ARG_FILE_REPLACEMENTS ${_index} _relative_file_path)
                math(EXPR _old_index "${_index} + 1")
                math(EXPR _new_index "${_index} + 2")
                list(GET ARG_FILE_REPLACEMENTS ${_old_index} _old_string)
                list(GET ARG_FILE_REPLACEMENTS ${_new_index} _new_string)
                
                set(_target_file "${_source_dir}/${_relative_file_path}")
                
                if(NOT EXISTS "${_target_file}")
                    message(FATAL_ERROR "[thirdparty] File not found for replacement: ${_target_file}")
                endif()
                
                message(STATUS "[thirdparty] Applying content replacement in: ${_relative_file_path}")
                
                # Read file content
                file(READ "${_target_file}" _file_content)
                
                # Perform replacement
                string(REPLACE "${_old_string}" "${_new_string}" _modified_content "${_file_content}")
                
                # Check if replacement actually happened
                if(_modified_content STREQUAL _file_content)
                    message(STATUS "[thirdparty] No replacement needed in ${_relative_file_path} (pattern not present)")
                else()
                    # Write modified content back
                    file(WRITE "${_target_file}" "${_modified_content}")
                    message(STATUS "[thirdparty] Successfully replaced content in: ${_relative_file_path}")
                endif()
                
                math(EXPR _index "${_index} + 3")
            endwhile()
        endif()
        endif()
    endif()

    thirdparty_get_optimization_flags(_common_cmake_args COMPONENT "${library_name}")

    # Handle cache args with semicolons by creating a temporary cache file
    set(_cache_file "")
    if(ARG_CMAKE_CACHE_ARGS)
        set(_cache_file "${CMAKE_BINARY_DIR}/thirdparty_cache_${library_name}.cmake")
        file(WRITE "${_cache_file}" "# Auto-generated cache file for ${library_name}\n")
        foreach(_cache_arg ${ARG_CMAKE_CACHE_ARGS})
            # Parse VAR=VALUE format
            string(FIND "${_cache_arg}" "=" _eq_pos)
            if(_eq_pos GREATER -1)
                string(SUBSTRING "${_cache_arg}" 0 ${_eq_pos} _var_name)
                math(EXPR _val_start "${_eq_pos} + 1")
                string(SUBSTRING "${_cache_arg}" ${_val_start} -1 _var_value)
                # Remove surrounding quotes if present
                string(REGEX REPLACE "^\"(.*)\"$" "\\1" _var_value "${_var_value}")
                file(APPEND "${_cache_file}" "set(${_var_name} \"${_var_value}\" CACHE STRING \"\" FORCE)\n")
            else()
                # Fallback for arguments without equals
                file(APPEND "${_cache_file}" "set(${_cache_arg} CACHE STRING \"\" FORCE)\n")
            endif()
        endforeach()
    endif()

    set(_final_cmake_args)
    if(_cache_file)
        list(APPEND _final_cmake_args "-C${_cache_file}")
    endif()
    list(APPEND _final_cmake_args -DCMAKE_INSTALL_PREFIX=${_install_dir})
    list(APPEND _final_cmake_args ${_common_cmake_args})
    list(APPEND _final_cmake_args ${ARG_CMAKE_ARGS})

    thirdparty_cmake_configure("${_source_dir}" "${_build_dir}"
        SOURCE_SUBDIR "${ARG_SOURCE_SUBDIR}"
        VALIDATION_MODE ANY
        VALIDATION_FILES
            "${_build_dir}/Makefile"
            "${_build_dir}/build.ninja" # For Ninja generator
        CMAKE_ARGS ${_final_cmake_args}
    )

    # Pre-audit raw validation entries for suspicious patterns (undefined install dir -> leading /lib or /include)
    if(ARG_VALIDATION_FILES)
        foreach(_rv IN LISTS ARG_VALIDATION_FILES)
            if(_rv MATCHES "^/lib/" OR _rv MATCHES "^/include/")
                thirdparty_audit_collect_suspicious("${library_name}" "${_rv}" "raw-leading-root-subdir")
            endif()
        endforeach()
    endif()

    thirdparty_cmake_install("${_build_dir}" "${_install_dir}"
        VALIDATION_FILES ${ARG_VALIDATION_FILES}
    )

    set(${_upper_name}_INSTALL_DIR "${_install_dir}" PARENT_SCOPE)
    get_filename_component(${_upper_name}_INSTALL_DIR "${_install_dir}" ABSOLUTE)

    message(DEBUG "[thirdparty] Finished building ${library_name}. Installed at: ${_install_dir}")
endfunction()

# Standardized function for autotools-based (./configure, make, make install) third-party libraries
function(thirdparty_build_autotools_library library_name)
    # Parse arguments
    cmake_parse_arguments(ARGS "BUILD_IN_SOURCE" "CONFIGURE_SCRIPT_NAME;POST_INSTALL_COMMAND" "CONFIGURE_ARGS;MAKE_ARGS;INSTALL_ARGS;VALIDATION_FILES" ${ARGN})

    # Set defaults
    if(NOT ARGS_CONFIGURE_SCRIPT_NAME)
        set(ARGS_CONFIGURE_SCRIPT_NAME "configure")
    endif()
    if(NOT ARGS_INSTALL_ARGS)
        set(ARGS_INSTALL_ARGS "install")
    endif()

    # Uppercase the library name to get variable prefixes
    string(TOUPPER "${library_name}" _upper_name)
    string(REPLACE "-" "_" _upper_name ${_upper_name})

    # Get component info from variables
    set(_version "${${_upper_name}_VERSION}")
    set(_url "${${_upper_name}_URL}")
    set(_sha256 "${${_upper_name}_SHA256}")

    # Set up standard directory and file names
    set(_source_dir "${THIRDPARTY_SRC_DIR}/${library_name}")
    set(_build_dir "${THIRDPARTY_BUILD_DIR}/${library_name}")
    set(_install_dir "${THIRDPARTY_INSTALL_DIR}/${library_name}")

    # (Archive naming removed; unified acquisition handles both archive and git)
    # Acquire source (git or archive)
    thirdparty_acquire_source("${library_name}" _source_dir)

    # --- Enhanced skip logic with stamp ---
    # Normalize validation file paths
    set(_normalized_validation_files)
    if(ARGS_VALIDATION_FILES)
        foreach(_vf IN LISTS ARGS_VALIDATION_FILES)
            get_filename_component(_abs_vf "${_vf}" ABSOLUTE)
            list(APPEND _normalized_validation_files "${_abs_vf}")
        endforeach()
    endif()

    if(DEFINED HALO_FORCE_THIRDPARTY_REINSTALL AND HALO_FORCE_THIRDPARTY_REINSTALL)
        set(_force_reinstall TRUE)
    else()
        set(_force_reinstall FALSE)
    endif()
    set(_skip_msg_mode DEBUG)
    if(DEFINED HALO_THIRDPARTY_VERBOSE_SUPPRESS AND NOT HALO_THIRDPARTY_VERBOSE_SUPPRESS)
        set(_skip_msg_mode STATUS)
    endif()

    set(_stamp_file "${_install_dir}/.halo_thirdparty_install_stamp")
    set(_need_build TRUE)
    set(_missing_files)
    if(NOT _force_reinstall)
        if(_normalized_validation_files)
            set(_all_exist TRUE)
            foreach(_file IN LISTS _normalized_validation_files)
                if(NOT EXISTS "${_file}")
                    set(_all_exist FALSE)
                    list(APPEND _missing_files "${_file}")
                endif()
            endforeach()
            if(_all_exist AND EXISTS "${_stamp_file}")
                file(READ "${_stamp_file}" _stamp_content)
                string(REGEX MATCH "^PATH_HASH=([A-Fa-f0-9]+)" _ph_line "${_stamp_content}")
                if(_ph_line)
                    string(SHA1 _current_path_hash "${_normalized_validation_files}")
                    string(REGEX REPLACE "^PATH_HASH=([A-Fa-f0-9]+).*" "\\1" _stamp_path_hash "${_stamp_content}")
                    if(_current_path_hash STREQUAL "${_stamp_path_hash}")
                        set(_need_build FALSE)
                        if(_skip_msg_mode STREQUAL "STATUS")
                            message(STATUS "[thirdparty_build_autotools_library] Skip build (stamp valid) for ${library_name}")
                        else()
                            message(DEBUG "[thirdparty_build_autotools_library] Skip build (stamp valid) for ${library_name}")
                        endif()
                    endif()
                endif()
            endif()
        endif()
    else()
        message(STATUS "[thirdparty_build_autotools_library] Force reinstall enabled for ${library_name}")
    endif()

    if(NOT _need_build AND _missing_files)
        set(_need_build TRUE) # safety
    endif()

    if(NOT _need_build)
        set(${_upper_name}_INSTALL_DIR "${_install_dir}" PARENT_SCOPE)
        get_filename_component(${_upper_name}_INSTALL_DIR "${_install_dir}" ABSOLUTE)
        thirdparty_register_to_cmake_prefix_path("${_install_dir}")
        return()
    else()
        if(_missing_files)
            message(STATUS "[thirdparty_build_autotools_library] Missing validation files triggering build for ${library_name}:")
            foreach(_mf IN LISTS _missing_files)
                message(STATUS "  * ${_mf}")
            endforeach()
        elseif(_force_reinstall)
            message(STATUS "[thirdparty_build_autotools_library] Rebuilding despite existing files (force enabled) for ${library_name}")
        else()
            message(STATUS "[thirdparty_build_autotools_library] Proceeding with build (no valid stamp) for ${library_name}")
        endif()
    endif()

    # Source ready at _source_dir (git or archive)

    # Determine working directory for build
    set(_work_dir "${_build_dir}")
    if(ARGS_BUILD_IN_SOURCE)
        set(_work_dir "${_source_dir}")
    else()
        file(MAKE_DIRECTORY "${_work_dir}")
    endif()

    # Always operate in append mode for autotools third-parties:
    # Do not override autotools-detected *FLAGS at configure time; instead
    # append project flags during build/install (CFLAGS+= ...). This preserves
    # feature detection macros (SIMD, crypto extensions, etc.).
    # Stash project flags for later append.
    set(_halo_project_cflags   "${CMAKE_C_FLAGS}")
    set(_halo_project_cxxflags "${CMAKE_CXX_FLAGS}")
    set(_halo_project_ldflags_raw "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS} ${CMAKE_MODULE_LINKER_FLAGS}")
    string(STRIP "${_halo_project_ldflags_raw}" _halo_project_ldflags_raw)
    
    # Deduplicate linker flags to avoid duplicate -fuse-ld=mold (or other linker flags)
    if(_halo_project_ldflags_raw)
        separate_arguments(_halo_ld_list UNIX_COMMAND "${_halo_project_ldflags_raw}")
        set(_dedup_halo_ld_list)
        foreach(_flag IN LISTS _halo_ld_list)
            list(FIND _dedup_halo_ld_list "${_flag}" _flag_idx)
            if(_flag_idx EQUAL -1)
                list(APPEND _dedup_halo_ld_list "${_flag}")
            endif()
        endforeach()
        string(JOIN " " _halo_project_ldflags ${_dedup_halo_ld_list})
        string(STRIP "${_halo_project_ldflags}" _halo_project_ldflags)
        # Secondary pass: collapse multiple -fuse-ld= occurrences to a single one (keep first)
        if(_halo_project_ldflags MATCHES "-fuse-ld=")
            separate_arguments(_halo_ld_tokens UNIX_COMMAND "${_halo_project_ldflags}")
            set(_seen_fuse FALSE)
            set(_final_ld_tokens)
            foreach(_t IN LISTS _halo_ld_tokens)
                if(_t MATCHES "^-fuse-ld=")
                    if(NOT _seen_fuse)
                        list(APPEND _final_ld_tokens "${_t}")
                        set(_seen_fuse TRUE)
                    else()
                        # skip duplicate linker selection flag
                    endif()
                else()
                    list(APPEND _final_ld_tokens "${_t}")
                endif()
            endforeach()
            string(JOIN " " _halo_project_ldflags ${_final_ld_tokens})
            string(STRIP "${_halo_project_ldflags}" _halo_project_ldflags)
        endif()
        message(DEBUG "[thirdparty_build_autotools_library] Sanitized LDFLAGS for ${library_name}: ${_halo_project_ldflags}")
    else()
        set(_halo_project_ldflags "")
    endif()

    # --- Configure Step ---
    if(NOT EXISTS "${_work_dir}/Makefile")
        message(STATUS "[thirdparty_build_autotools_library] Configuring ${library_name}...")

        # Run autogen.sh if it exists (common for git checkouts)
        if(EXISTS "${_source_dir}/autogen.sh")
            execute_process(
                COMMAND bash autogen.sh
                WORKING_DIRECTORY "${_source_dir}"
                RESULT_VARIABLE _autogen_result
            )
            if(NOT _autogen_result EQUAL 0)
                message(FATAL_ERROR "Failed to run autogen.sh for ${library_name}")
            endif()
        endif()

        # Construct configure command with comprehensive linker support
        set(_configure_script "${_source_dir}/${ARGS_CONFIGURE_SCRIPT_NAME}")
        set(_configure_args --prefix=${_install_dir} ${ARGS_CONFIGURE_ARGS})
        # For logging: produce a readable command line
        list(JOIN _configure_args " " _configure_args_string)
        
        set(_linker_env)
        if(CMAKE_C_COMPILER)
            list(APPEND _linker_env "CC=${CMAKE_C_COMPILER}")
        endif()
        if(CMAKE_CXX_COMPILER)
            list(APPEND _linker_env "CXX=${CMAKE_CXX_COMPILER}")
        endif()
        if(HALO_LINKER)
            list(APPEND _linker_env "LD=${HALO_LINKER}")
        endif()
        if(PKG_CONFIG_EXECUTABLE)
            list(APPEND _linker_env "PKG_CONFIG=${PKG_CONFIG_EXECUTABLE}")
        endif()

        set(_auto_CFLAGS   "${CMAKE_C_FLAGS}")
        set(_auto_CXXFLAGS "${CMAKE_CXX_FLAGS}")
        set(_auto_LDFLAGS_RAW "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_SHARED_LINKER_FLAGS} ${CMAKE_MODULE_LINKER_FLAGS}")
        string(STRIP "${_auto_LDFLAGS_RAW}" _auto_LDFLAGS_RAW)
        if(_auto_LDFLAGS_RAW)
            separate_arguments(_auto_ld_list UNIX_COMMAND "${_auto_LDFLAGS_RAW}")
            set(_dedup_ld_list)
            set(_fuse_values)
            set(_fuse_positions)
            set(_idx 0)
            foreach(_f IN LISTS _auto_ld_list)
                if(_f MATCHES "^-fuse-ld=.*")
                    list(APPEND _fuse_values "${_f}")
                    list(APPEND _fuse_positions "${_idx}:${_f}")
                endif()
                if(_f STREQUAL "--start-group" OR _f STREQUAL "--end-group")
                    list(APPEND _dedup_ld_list "${_f}")
                else()
                    list(FIND _dedup_ld_list "${_f}" _exist_idx)
                    if(_exist_idx EQUAL -1)
                        list(APPEND _dedup_ld_list "${_f}")
                    endif()
                endif()
                math(EXPR _idx "${_idx} + 1")
            endforeach()
            if(_fuse_values)
                set(_unique_fuse)
                foreach(_v IN LISTS _fuse_values)
                    list(FIND _unique_fuse "${_v}" _u_idx)
                    if(_u_idx EQUAL -1)
                        list(APPEND _unique_fuse "${_v}")
                    endif()
                endforeach()
                list(LENGTH _unique_fuse _fuse_len)
                if(_fuse_len GREATER 1)
                    message(FATAL_ERROR "[thirdparty_build_autotools_library] Multiple distinct -fuse-ld detected in aggregated linker flags (positions=${_fuse_positions}); using first occurrence order after dedup: ${_unique_fuse}")
                endif()
            endif()
            string(JOIN " " _auto_LDFLAGS ${_dedup_ld_list})
        else()
            set(_auto_LDFLAGS "")
        endif()

        string(STRIP "${_auto_CFLAGS}"   _auto_CFLAGS)
        string(STRIP "${_auto_CXXFLAGS}" _auto_CXXFLAGS)
        string(STRIP "${_auto_LDFLAGS}"  _auto_LDFLAGS)

        message(STATUS "[thirdparty_build_autotools_library] (append mode) Allow autotools to set its own *FLAGS for ${library_name}; project flags will be appended at build/install")

        list(JOIN _linker_env " " _env_string)
        message(STATUS "[thirdparty_build_autotools_library] Configure env: ${_env_string}")
        message(STATUS "[thirdparty_build_autotools_library] Configure command: ${_env_string} ${_configure_script} ${_configure_args_string}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E env ${_linker_env} ${_configure_script} ${_configure_args}
            WORKING_DIRECTORY "${_work_dir}"
            RESULT_VARIABLE _configure_result
        )
        if(NOT _configure_result EQUAL 0)
            message(FATAL_ERROR "Failed to configure ${library_name}")
        endif()
    else()
        if(EXISTS "${_work_dir}/config.status")
            message(STATUS "[thirdparty_build_autotools_library] Skip configure: Makefile & config.status present for ${library_name}.")
        else()
            message(STATUS "[thirdparty_build_autotools_library] Makefile found (no config.status) for ${library_name}, assuming prior configure; skipping.")
        endif()
    endif()

    # --- Build and Install Step ---
    thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _make_jobs)
    set(PARALLEL_JOBS "-j${_make_jobs}")

    message(STATUS "[thirdparty_build_autotools_library] Building ${library_name}...")
    # Compose append arguments if in append mode
    set(_append_flag_args)
    if(_halo_project_cflags)
        # Pass flags without surrounding quotes to allow make to split them into distinct arguments.
        # Quoting caused clang to treat combined fragments as a single (invalid) library name.
        list(APPEND _append_flag_args "CFLAGS+=${_halo_project_cflags}")
    endif()
    if(_halo_project_cxxflags)
        list(APPEND _append_flag_args "CXXFLAGS+=${_halo_project_cxxflags}")
    endif()
    if(_halo_project_ldflags)
        list(APPEND _append_flag_args "LDFLAGS+=${_halo_project_ldflags}")
    endif()
    if(_append_flag_args)
        message(STATUS "[thirdparty_build_autotools_library] Appending project flags at build: ${_append_flag_args}")
    endif()

    if(HALO_LINKER AND _linker_env)
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E env ${_linker_env} make ${PARALLEL_JOBS} ${_append_flag_args} ${ARGS_MAKE_ARGS}
            WORKING_DIRECTORY "${_work_dir}"
            RESULT_VARIABLE _build_result
        )
    else()
        execute_process(
            COMMAND make ${PARALLEL_JOBS} ${_append_flag_args} ${ARGS_MAKE_ARGS}
            WORKING_DIRECTORY "${_work_dir}"
            RESULT_VARIABLE _build_result
        )
    endif()
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build ${library_name}")
    endif()

    # Audit raw validation paths before install for autotools libraries (same criteria)
    if(ARGS_VALIDATION_FILES)
        foreach(_rv IN LISTS ARGS_VALIDATION_FILES)
            if(_rv MATCHES "^/lib/" OR _rv MATCHES "^/include/")
                thirdparty_audit_collect_suspicious("${library_name}" "${_rv}" "raw-leading-root-subdir")
            endif()
        endforeach()
    endif()

    message(STATUS "[thirdparty_build_autotools_library] Installing ${library_name}...")
    set(_append_install_flag_args)
    if(_halo_project_cflags)
        list(APPEND _append_install_flag_args "CFLAGS+=${_halo_project_cflags}")
    endif()
    if(_halo_project_cxxflags)
        list(APPEND _append_install_flag_args "CXXFLAGS+=${_halo_project_cxxflags}")
    endif()
    if(_halo_project_ldflags)
        list(APPEND _append_install_flag_args "LDFLAGS+=${_halo_project_ldflags}")
    endif()
    if(HALO_LINKER AND _linker_env)
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E env ${_linker_env} make ${ARGS_INSTALL_ARGS} ${_append_install_flag_args}
            WORKING_DIRECTORY "${_work_dir}"
            RESULT_VARIABLE _install_result
        )
    else()
        execute_process(
            COMMAND make ${ARGS_INSTALL_ARGS} ${_append_install_flag_args}
            WORKING_DIRECTORY "${_work_dir}"
            RESULT_VARIABLE _install_result
        )
    endif()
    if(NOT _install_result EQUAL 0)
        message(FATAL_ERROR "Failed to install ${library_name}")
    else()
        # Write/update stamp file
        if(_normalized_validation_files)
            string(SHA1 _path_hash "${_normalized_validation_files}")
            file(WRITE "${_stamp_file}" "PATH_HASH=${_path_hash}\n")
            foreach(_vf IN LISTS _normalized_validation_files)
                if(EXISTS "${_vf}")
                    file(TIMESTAMP "${_vf}" _ts UTC)
                    file(APPEND "${_stamp_file}" "FILE=${_vf}|${_ts}\n")
                endif()
            endforeach()
            message(DEBUG "[thirdparty_build_autotools_library] Wrote stamp ${_stamp_file}")
        endif()
    endif()

    # Run post-install command if provided
    if(ARGS_POST_INSTALL_COMMAND)
        message(STATUS "[thirdparty_build_autotools_library] Running post-install command for ${library_name}: ${ARGS_POST_INSTALL_COMMAND}")
        cmake_language(CALL ${ARGS_POST_INSTALL_COMMAND})
    endif()

    # Final validation
    foreach(_file IN LISTS ARGS_VALIDATION_FILES)
        if(NOT EXISTS "${_file}")
            message(FATAL_ERROR "Validation file not found after installation: ${_file}")
        endif()
    endforeach()

    # Export the installation directory for other components to find
    set(${_upper_name}_INSTALL_DIR "${_install_dir}" PARENT_SCOPE)
    get_filename_component(${_upper_name}_INSTALL_DIR "${_install_dir}" ABSOLUTE)
    # Always register to CMAKE_PREFIX_PATH for consistency
    thirdparty_register_to_cmake_prefix_path("${_install_dir}")
    
    message(DEBUG "[thirdparty] Finished building ${library_name}. Installed at: ${_install_dir}")
endfunction()

# Function to register a third-party executable path
function(thirdparty_register_executable_path name path)
    if(NOT EXISTS "${path}")
        message(FATAL_ERROR "[thirdparty] Executable not found: ${path}")
        return()
    endif()
    
    # Add to global collection
    set(_current_paths ${THIRDPARTY_EXECUTABLE_PATHS})
    list(APPEND _current_paths "${name}=${path}")
    set(THIRDPARTY_EXECUTABLE_PATHS "${_current_paths}" CACHE INTERNAL "Collected third-party executable paths")
    
    message(DEBUG "[thirdparty] Registered executable: ${name} -> ${path}")
endfunction()

# Function to generate compile definitions from collected executable paths
function(thirdparty_get_executable_definitions output_var)
    set(_definitions)
    foreach(_entry IN LISTS THIRDPARTY_EXECUTABLE_PATHS)
        string(REPLACE "=" ";" _parts "${_entry}")
        list(GET _parts 0 _name)
        list(GET _parts 1 _path)
        string(TOUPPER "${_name}" _upper_name)
        list(APPEND _definitions "${_upper_name}_EXECUTABLE_PATH=\"${_path}\"")
    endforeach()
    set(${output_var} "${_definitions}" PARENT_SCOPE)
endfunction()

# --- Ninja Build System Optimization for Third-party Libraries ---
# This function provides additional optimizations when Ninja is used as the generator
function(thirdparty_configure_ninja_optimization cmake_args_var)
    find_program(NINJA_EXECUTABLE ninja)
    if(NOT NINJA_EXECUTABLE)
        return()
    endif()
    
    # Get reference to the cmake args list
    set(_args ${${cmake_args_var}})
    
    # Check if we're already using Ninja generator
    list(FIND _args "-GNinja" _ninja_index)
    if(_ninja_index EQUAL -1)
        list(APPEND _args -GNinja)
    endif()
    
    # Check if job pools are already configured
    set(_has_job_pools FALSE)
    foreach(_arg IN LISTS _args)
        if(_arg MATCHES "^-DCMAKE_JOB_POOLS=")
            set(_has_job_pools TRUE)
            break()
        endif()
    endforeach()
    
    if(NOT _has_job_pools)
        # Configure parallel jobs for optimal resource usage
        thirdparty_get_build_jobs(OUTPUT_COMPILE_JOBS _compile_jobs OUTPUT_LINK_JOBS _link_jobs)
        
        list(APPEND _args 
            # Use CMake's built-in parallel job configuration
            -DCMAKE_BUILD_PARALLEL_LEVEL=${_compile_jobs}
        )
        
        message(STATUS "[thirdparty] Ninja: configured with ${_compile_jobs} parallel jobs")
    endif()
    
    # Set the modified args back to the variable
    set(${cmake_args_var} ${_args} PARENT_SCOPE)
endfunction()

# --- Safe flag combination utility ------------------------------------------
# thirdparty_combine_flags(<out_var> [FRAGMENTS frag1 frag2 ...])
# Joins non-empty flag fragments with single spaces, trims leading/trailing
# whitespace, and avoids creating an empty string (returns empty if all empty).
# Future extension point: de-duplicate include directories or -D macros.
function(thirdparty_combine_flags out_var)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs FRAGMENTS)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")
    set(_parts)
    foreach(_f IN LISTS ARG_FRAGMENTS)
        if(_f)
            string(STRIP "${_f}" _clean)
            if(NOT _clean STREQUAL "")
                list(APPEND _parts "${_clean}")
            endif()
        endif()
    endforeach()
    if(_parts)
        string(JOIN " " _joined ${_parts})
        string(STRIP "${_joined}" _joined)
        set(${out_var} "${_joined}" PARENT_SCOPE)
    else()
        set(${out_var} "" PARENT_SCOPE)
    endif()
endfunction()

