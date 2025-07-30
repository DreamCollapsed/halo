# --- Safe Parent Scope Setting Utility ---
# This function safely sets variables in parent scope, avoiding warnings when no parent exists
function(thirdparty_safe_set_parent_scope variable_name value)
    # Check if we have a parent scope by testing if we can access CMAKE_CURRENT_SOURCE_DIR
    # from both current and what would be parent context
    get_directory_property(_has_parent PARENT_DIRECTORY)
    if(_has_parent)
        set(${variable_name} "${value}" PARENT_SCOPE)
    else()
        # No parent scope, set as cache variable instead
        set(${variable_name} "${value}" CACHE INTERNAL "Thirdparty variable: ${variable_name}" FORCE)
    endif()
endfunction()

# --- Centralized Build Job Configuration ---
# This function provides unified thread/job count configuration for all build systems
function(thirdparty_get_build_jobs)
    # Parse optional parameters for different build systems
    set(options "")
    set(oneValueArgs "OUTPUT_COMPILE_JOBS;OUTPUT_LINK_JOBS;OUTPUT_MAKE_JOBS;BUILD_TYPE")
    set(multiValueArgs "")
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
    include(ProcessorCount)
    ProcessorCount(_cpu_count)
    
    # Set default values if CPU count detection fails
    if(NOT _cpu_count OR _cpu_count EQUAL 0)
        set(_cpu_count 4)
        message(STATUS "[thirdparty] CPU count detection failed, using fallback: ${_cpu_count}")
    endif()
    
    # Configure different job types based on system capabilities and build type
    set(_compile_jobs ${_cpu_count})
    set(_link_jobs 2)
    set(_make_jobs ${_cpu_count})
    
    # Adjust for high-end systems (more conservative linking to avoid memory pressure)
    if(_cpu_count GREATER 8)
        set(_link_jobs 4)
    elseif(_cpu_count GREATER 16)
        set(_link_jobs 6)
    endif()
    
    # Special handling for debug builds (use fewer jobs to reduce memory usage)
    if(ARG_BUILD_TYPE AND ARG_BUILD_TYPE STREQUAL "Debug")
        math(EXPR _compile_jobs "${_cpu_count} / 2")
        math(EXPR _link_jobs "2")
        if(_compile_jobs LESS 2)
            set(_compile_jobs 2)
        endif()
        message(STATUS "[thirdparty] Debug build detected, using conservative job counts")
    endif()
    
    # Output the results to the specified variables
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
        file(DOWNLOAD "${url}" "${file}"
            EXPECTED_HASH SHA256=${hash}
            SHOW_PROGRESS)
    endif()
endfunction()

function(thirdparty_extract_and_rename tarfile srcdir pattern)
    if(NOT EXISTS "${srcdir}/CMakeLists.txt")
        file(GLOB _old_dirs "${pattern}")
        foreach(_d ${_old_dirs})
            file(REMOVE_RECURSE "${_d}")
        endforeach()
        file(MAKE_DIRECTORY "${srcdir}")
        get_filename_component(_workdir "${srcdir}" DIRECTORY)
        
        # Get complete filename
        get_filename_component(_filename "${tarfile}" NAME)
        # Use string operations to handle extensions
        string(REGEX MATCH "\\.[^.]*\\.[^.]*$" _double_ext "${_filename}")
        if(_double_ext)
            # Handle double extensions (like .tar.gz, .tar.bz2)
            string(TOLOWER "${_double_ext}" _ext)
        else()
            # Handle single extensions
            get_filename_component(_ext "${tarfile}" EXT)
            string(TOLOWER "${_ext}" _ext)
        endif()
        
        # Use cmake -E tar to automatically handle all supported compression formats
        if(_ext MATCHES "\\.(tar\\.gz|tgz|tar\\.bz2|tbz2|tar\\.xz|txz|tar)$" OR _ext STREQUAL ".zip")
            execute_process(
                COMMAND ${CMAKE_COMMAND} -E tar xf "${tarfile}"
                WORKING_DIRECTORY "${_workdir}"
                RESULT_VARIABLE _extract_failed
            )
            if(_extract_failed)
                message(FATAL_ERROR "Failed to extract ${tarfile}")
            endif()
        elseif(_ext MATCHES "\\.(gz|bz2|xz)$")
            # Only decompress single compressed file, not a tar package
            message(FATAL_ERROR "Unsupported archive format (not a tarball): ${tarfile}")
        else()
            message(FATAL_ERROR "Unsupported archive format: ${tarfile}")
        endif()

        file(GLOB _unpacked_dir "${pattern}")
        list(GET _unpacked_dir 0 _unpacked_path)
        if(_unpacked_path AND NOT _unpacked_path STREQUAL "${srcdir}")
            # Remove target directory if it exists to avoid "Directory not empty" error
            if(EXISTS "${srcdir}")
                file(REMOVE_RECURSE "${srcdir}")
            endif()
            file(RENAME "${_unpacked_path}" "${srcdir}")
        endif()
    endif()
endfunction()

function(thirdparty_cmake_configure srcdir builddir)
    cmake_parse_arguments(PARSE_ARGV 2
        ARG
        "FORCE_CONFIGURE"
        "VALIDATION_PATTERN;SOURCE_SUBDIR"
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
        if(ARG_VALIDATION_FILES)
            set(need_configure FALSE)
            foreach(file IN LISTS ARG_VALIDATION_FILES)
                if(NOT EXISTS "${file}")
                    set(need_configure TRUE)
                    break()
                endif()
            endforeach()
        elseif(ARG_VALIDATION_PATTERN)
            file(GLOB _matched_files "${ARG_VALIDATION_PATTERN}")
            if(_matched_files)
                set(need_configure FALSE)
            endif()
        endif()
        
        if(NOT need_configure)
            message(STATUS "[thirdparty_cmake_configure] All validation files exist or pattern matched, skip configure.")
            set(CMAKE_CURRENT_FUNCTION_RESULT 0 PARENT_SCOPE)
            return()
        endif()
    endif()

    message(STATUS "[thirdparty_cmake_configure] Configuring ${_actual_src_dir} to ${builddir}")
    
    # Apply Ninja optimizations to the cmake arguments
    set(_cmake_args ${ARG_CMAKE_ARGS})
    thirdparty_configure_ninja_optimization(_cmake_args)
    
    # Print the complete cmake command for debugging
    set(_cmake_cmd_str "${CMAKE_COMMAND} -S \"${_actual_src_dir}\" -B \"${builddir}\"")
    foreach(_arg ${_cmake_args})
        set(_cmake_cmd_str "${_cmake_cmd_str} ${_arg}")
    endforeach()
    message(STATUS "[thirdparty_cmake_configure] CMake command: ${_cmake_cmd_str}")
    
    execute_process(
        COMMAND ${CMAKE_COMMAND} -S "${_actual_src_dir}" -B "${builddir}" ${_cmake_args}
        RESULT_VARIABLE result
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error
    )

    if(NOT result EQUAL 0)
        message(WARNING "[thirdparty_cmake_configure] CMake configure failed for ${_actual_src_dir}")
        if(output)
            message(STATUS "CMake stdout: ${output}")
        endif()
        if(error)
            message(STATUS "CMake stderr: ${error}")
        endif()
    endif()

    set(CMAKE_CURRENT_FUNCTION_RESULT "${result}" PARENT_SCOPE)
endfunction()

function(thirdparty_cmake_install builddir installdir)
    # Add optional parameters: check file list (to verify if component is already installed)
    # Parameter format: VALIDATION_FILES file1 [file2 ...] or VALIDATION_PATTERN pattern
    set(options "")
    set(oneValueArgs VALIDATION_PATTERN)
    set(multiValueArgs VALIDATION_FILES)
    cmake_parse_arguments(PARSE_ARGV 2 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

    # Check if already installed
    set(_need_install TRUE)
    if(ARG_VALIDATION_FILES)
        set(_all_files_exist TRUE)
        foreach(_file ${ARG_VALIDATION_FILES})
            if(NOT EXISTS "${_file}")
                set(_all_files_exist FALSE)
                break()
            endif()
        endforeach()
        if(_all_files_exist)
            message(STATUS "[thirdparty_cmake_install] All validation files exist in ${installdir}, skip build and install.")
            set(_need_install FALSE)
        endif()
    elseif(ARG_VALIDATION_PATTERN)
        file(GLOB _matched_files "${ARG_VALIDATION_PATTERN}")
        if(_matched_files)
            message(STATUS "[thirdparty_cmake_install] Found matching files for pattern ${ARG_VALIDATION_PATTERN}, skip build and install.")
            set(_need_install FALSE)
        endif()
    endif()

    if(NOT _need_install)
        message(STATUS "[thirdparty_cmake_install] All validation files exist, skip install for ${builddir}")
        set(${CMAKE_CURRENT_FUNCTION_RESULT} 0 PARENT_SCOPE)
        return()
    endif()

    if(NOT EXISTS "${builddir}")
        message(WARNING "[thirdparty_cmake_install] Build directory ${builddir} not found, skip install.")
        set(${CMAKE_CURRENT_FUNCTION_RESULT} 1 PARENT_SCOPE)
        return()
    endif()
    
    message(STATUS "[thirdparty_cmake_install] Building and installing from ${builddir} to ${installdir}")
    
    # Use optimized build command based on generator
    find_program(NINJA_EXECUTABLE ninja)
    if(NINJA_EXECUTABLE AND EXISTS "${builddir}/build.ninja")
        # Use Ninja directly for better performance
        message(STATUS "[thirdparty_cmake_install] Using Ninja for optimized build")
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
        endif()
    else()
        message(WARNING "[thirdparty_cmake_install] Build failed for ${builddir}, skip install.")
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
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DBUILD_SHARED_LIBS:BOOL=OFF
        -DBUILD_TESTING=OFF
        -DCMAKE_SUPPRESS_DEVELOPER_WARNINGS=ON
        -DCMAKE_WARN_DEPRECATED=OFF

        -Wno-dev
        --no-warn-unused-cli
    )
    
    # --- Build CMAKE_FIND_ROOT_PATH from installed components ---
    # For each component to find its dependencies correctly, we need to set CMAKE_FIND_ROOT_PATH
    # to point to the individual component installation directories, not the parent directory
    thirdparty_build_find_root_path(_find_root_paths)
    if(_find_root_paths)
        list(APPEND _opt_flags "-DCMAKE_FIND_ROOT_PATH=${_find_root_paths}")
        list(APPEND _opt_flags "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH")
        list(APPEND _opt_flags "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH") 
        list(APPEND _opt_flags "-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH")
    endif()
    
    # --- Ninja Generator Support for faster builds ---
    # Check if Ninja is available and use it for third-party libraries
    find_program(NINJA_EXECUTABLE ninja)
    if(NINJA_EXECUTABLE)
        list(APPEND _opt_flags -GNinja)
        message(STATUS "[thirdparty] Using Ninja generator for faster third-party builds")
    else()
        # Fallback to default generator with parallel make support
        thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _make_jobs)
        list(APPEND _opt_flags -DCMAKE_BUILD_PARALLEL_LEVEL=${_make_jobs})
        message(STATUS "[thirdparty] Ninja not found, using default generator with ${_make_jobs} parallel jobs")
    endif()
    
    # Add Link Time Optimization (LTO) if supported
    if(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE)
        list(APPEND _opt_flags -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON)
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
    
    # Handle FindBoost module removal in newer CMake versions (CMP0167)
    # This prevents warnings when folly or other libraries try to use FindBoost
    if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.30")
        list(APPEND _opt_flags -DCMAKE_POLICY_DEFAULT_CMP0167=NEW)
    endif()
    
    # Automatically add dependency CMAKE_ARGS if component is specified
    if(ARG_COMPONENT)
        # Get dependency paths and generate CMAKE_ARGS
        get_property(_deps CACHE "${ARG_COMPONENT}_DEPENDENCIES" PROPERTY VALUE)
        if(_deps)
            # First, add CMAKE_PREFIX_PATH for general discovery
            thirdparty_get_dependency_paths("${ARG_COMPONENT}" _dep_paths)
            if(_dep_paths)
                list(APPEND _opt_flags "-DCMAKE_PREFIX_PATH=${_dep_paths}")
            endif()
            
            # Then, add specific *_DIR for libraries that need explicit paths
            foreach(_dep IN LISTS _deps)
                # Check if this dependency has a standard CMake config
                if(EXISTS "${THIRDPARTY_INSTALL_DIR}/${_dep}/lib/cmake/${_dep}")
                    list(APPEND _opt_flags "-D${_dep}_DIR=${THIRDPARTY_INSTALL_DIR}/${_dep}/lib/cmake/${_dep}")
                elseif(EXISTS "${THIRDPARTY_INSTALL_DIR}/${_dep}/lib/cmake")
                    # For libraries like GTest that use different naming
                    file(GLOB _config_dirs "${THIRDPARTY_INSTALL_DIR}/${_dep}/lib/cmake/*")
                    if(_config_dirs)
                        list(GET _config_dirs 0 _config_dir)
                        get_filename_component(_config_name "${_config_dir}" NAME)
                        list(APPEND _opt_flags "-D${_config_name}_DIR=${_config_dir}")
                    endif()
                endif()
            endforeach()
        endif()
    endif()
    
    set(${output_var} "${_opt_flags}" PARENT_SCOPE)
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
        # Set cache size to 5GB (adjust based on available disk space)
        execute_process(
            COMMAND ${CCACHE_EXECUTABLE} --max-size=5G
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

# Standardized function for setting up common third-party library directories
function(thirdparty_setup_directories library_name)
    string(TOUPPER "${library_name}" _lib_upper)
    string(REPLACE "-" "_" _lib_upper "${_lib_upper}")
    
    # Set standard directory variables
    set(${_lib_upper}_NAME "${library_name}" PARENT_SCOPE)
    set(${_lib_upper}_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/${library_name}-${${_lib_upper}_VERSION}.tar.gz" PARENT_SCOPE)
    set(${_lib_upper}_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${library_name}" PARENT_SCOPE)
    set(${_lib_upper}_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${library_name}" PARENT_SCOPE)
    set(${_lib_upper}_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${library_name}" PARENT_SCOPE)
    
    # Make installation directory absolute
    get_filename_component(_abs_install_dir "${THIRDPARTY_INSTALL_DIR}/${library_name}" ABSOLUTE)
    set(${_lib_upper}_INSTALL_DIR "${_abs_install_dir}" PARENT_SCOPE)
endfunction()

# Standardized function for simple CMake-based third-party libraries
function(thirdparty_build_cmake_library library_name)
    # Parse arguments
    set(options)
    set(oneValueArgs EXTRACT_PATTERN SOURCE_SUBDIR)
    set(multiValueArgs VALIDATION_FILES CMAKE_ARGS)
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
    set(_download_file "${THIRDPARTY_DOWNLOAD_DIR}/${library_name}-${_version}${_extension}")
    # --- End of standardized naming ---

    # Set default extract pattern if not provided
    if(NOT ARG_EXTRACT_PATTERN)
        set(ARG_EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/${library_name}-*")
    endif()

    # Check dependencies first
    thirdparty_check_dependencies("${library_name}")

    # Download and extract
    thirdparty_download_and_check("${_url}" "${_download_file}" "${_sha256}")
    thirdparty_extract_and_rename("${_download_file}" "${_source_dir}" "${ARG_EXTRACT_PATTERN}")

    # Get common optimization flags
    thirdparty_get_optimization_flags(_common_cmake_args COMPONENT "${library_name}")

    # Configure
    thirdparty_cmake_configure("${_source_dir}" "${_build_dir}"
        SOURCE_SUBDIR "${ARG_SOURCE_SUBDIR}"
        VALIDATION_FILES
            "${_build_dir}/Makefile"
            "${_build_dir}/build.ninja" # For Ninja generator
        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${_install_dir}
            ${_common_cmake_args}
            ${ARG_CMAKE_ARGS}
    )

    # Build and install
    thirdparty_cmake_install("${_build_dir}" "${_install_dir}"
        VALIDATION_FILES ${ARG_VALIDATION_FILES}
    )

    # Export the installation directory for other components to find
    set(${_upper_name}_INSTALL_DIR "${_install_dir}" PARENT_SCOPE)
    get_filename_component(${_upper_name}_INSTALL_DIR "${_install_dir}" ABSOLUTE)
    list(APPEND CMAKE_PREFIX_PATH "${_install_dir}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    
    message(STATUS "Finished building ${library_name}. Installed at: ${_install_dir}")
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

    # --- Standardized download file naming ---
    get_filename_component(_url_filename "${_url}" NAME)
    string(REGEX MATCH "(\\.tar\\.gz|\\.tgz|\\.tar\\.bz2|\\.tbz2|\\.tar\\.xz|\\.txz|\\.zip)$" _extension "${_url_filename}")
    if(NOT _extension)
        if(_url MATCHES "\\.zip")
            set(_extension ".zip")
        else()
            set(_extension ".tar.gz") # Default assumption
        endif()
    endif()
    set(_download_file "${THIRDPARTY_DOWNLOAD_DIR}/${library_name}-${_version}${_extension}")

    # Check if already installed by validating files
    set(_need_build TRUE)
    if(ARGS_VALIDATION_FILES)
        set(_all_files_exist TRUE)
        foreach(_file ${ARGS_VALIDATION_FILES})
            if(NOT EXISTS "${_file}")
                set(_all_files_exist FALSE)
                break()
            endif()
        endforeach()
        if(_all_files_exist)
            message(STATUS "[thirdparty_build_autotools_library] All validation files exist for ${library_name}, skip build.")
            set(_need_build FALSE)
        endif()
    endif()

    if(NOT _need_build)
        # Still need to export variables
        set(${_upper_name}_INSTALL_DIR "${_install_dir}" PARENT_SCOPE)
        get_filename_component(${_upper_name}_INSTALL_DIR "${_install_dir}" ABSOLUTE)
        list(APPEND CMAKE_PREFIX_PATH "${_install_dir}")
        set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
        return()
    endif()

    # Check dependencies first
    thirdparty_check_dependencies("${library_name}")

    # Download and extract
    thirdparty_download_and_check("${_url}" "${_download_file}" "${_sha256}")
    thirdparty_extract_and_rename("${_download_file}" "${_source_dir}" "${THIRDPARTY_SRC_DIR}/${library_name}-*")

    # Determine working directory for build
    set(_work_dir "${_build_dir}")
    if(ARGS_BUILD_IN_SOURCE)
        set(_work_dir "${_source_dir}")
    else()
        file(MAKE_DIRECTORY "${_work_dir}")
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

        # Construct configure command
        set(_configure_script "${_source_dir}/${ARGS_CONFIGURE_SCRIPT_NAME}")
        set(_configure_args --prefix=${_install_dir} ${ARGS_CONFIGURE_ARGS})
        
        message(STATUS "[thirdparty_build_autotools_library] Configure command: ${_configure_script} ${_configure_args}")

        execute_process(
            COMMAND ${_configure_script} ${_configure_args}
            WORKING_DIRECTORY "${_work_dir}"
            RESULT_VARIABLE _configure_result
        )
        if(NOT _configure_result EQUAL 0)
            message(FATAL_ERROR "Failed to configure ${library_name}")
        endif()
    else()
        message(STATUS "[thirdparty_build_autotools_library] Makefile found for ${library_name}, skip configure.")
    endif()

    # --- Build and Install Step ---
    thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _make_jobs)
    set(PARALLEL_JOBS "-j${_make_jobs}")

    message(STATUS "[thirdparty_build_autotools_library] Building ${library_name}...")
    execute_process(
        COMMAND make ${PARALLEL_JOBS} ${ARGS_MAKE_ARGS}
        WORKING_DIRECTORY "${_work_dir}"
        RESULT_VARIABLE _build_result
    )
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build ${library_name}")
    endif()

    message(STATUS "[thirdparty_build_autotools_library] Installing ${library_name}...")
    execute_process(
        COMMAND make ${ARGS_INSTALL_ARGS}
        WORKING_DIRECTORY "${_work_dir}"
        RESULT_VARIABLE _install_result
    )
    if(NOT _install_result EQUAL 0)
        message(FATAL_ERROR "Failed to install ${library_name}")
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
    list(APPEND CMAKE_PREFIX_PATH "${_install_dir}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    
    message(STATUS "Finished building ${library_name}. Installed at: ${_install_dir}")
endfunction()

# Common optimization flags and CMake policy settings for all third-party libraries
# This replaces the need to modify source files with file patches
function(thirdparty_apply_common_settings)
    # Parse optional component name for dependency resolution
    set(options "")
    set(oneValueArgs COMPONENT)
    set(multiValueArgs "")
    cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")
    
    # --- Compiler and Linker Flags ---
    # Base optimization flags
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O3 -DNDEBUG")
    
    # Position Independent Code (for shared libraries)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
    
    # Link Time Optimization (LTO) if supported
    if(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
    endif()
    
    # --- CMake Policy Settings ---
    # Modern CMake policy defaults to avoid compatibility issues
    # This eliminates the need for source file modifications
    cmake_policy(SET CMP0042 NEW) # macOS @rpath in target's install name
    cmake_policy(SET CMP0063 NEW) # Honor visibility properties for all target types
    cmake_policy(SET CMP0077 NEW) # option() honors normal variables (critical for BUILD_SHARED_LIBS)
    cmake_policy(SET CMP0076 NEW) # target_sources() command converts relative paths to absolute
    cmake_policy(SET CMP0079 NEW) # target_link_libraries() allows use with targets in other directories
    
    # Automatically add dependency CMAKE_ARGS if component is specified
    if(ARG_COMPONENT)
        # Get dependency paths and generate CMAKE_ARGS
        get_property(_deps CACHE "${ARG_COMPONENT}_DEPENDENCIES" PROPERTY VALUE)
        if(_deps)
            # First, add CMAKE_PREFIX_PATH for general discovery
            thirdparty_get_dependency_paths("${ARG_COMPONENT}" _dep_paths)
            if(_dep_paths)
                list(APPEND CMAKE_PREFIX_PATH "${_dep_paths}")
            endif()
            
            # Then, add specific *_DIR for libraries that need explicit paths
            foreach(_dep IN LISTS _deps)
                # Check if this dependency has a standard CMake config
                if(EXISTS "${THIRDPARTY_INSTALL_DIR}/${_dep}/lib/cmake/${_dep}")
                    list(APPEND CMAKE_PREFIX_PATH "${THIRDPARTY_INSTALL_DIR}/${_dep}/lib/cmake/${_dep}")
                elseif(EXISTS "${THIRDPARTY_INSTALL_DIR}/${_dep}/lib/cmake")
                    # For libraries like GTest that use different naming
                    file(GLOB _config_dirs "${THIRDPARTY_INSTALL_DIR}/${_dep}/lib/cmake/*")
                    if(_config_dirs)
                        list(GET _config_dirs 0 _config_dir)
                        get_filename_component(_config_name "${_config_dir}" NAME)
                        list(APPEND CMAKE_PREFIX_PATH "${_config_dir}")
                    endif()
                endif()
            endforeach()
        endif()
    endif()
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

# --- Build CMAKE_FIND_ROOT_PATH from installed components ---
# This function scans the thirdparty installation directory and builds a list
# of component paths for CMAKE_FIND_ROOT_PATH, ensuring CMake can find dependencies
function(thirdparty_build_find_root_path output_var)
    set(_root_paths)
    
    # Scan for installed components
    if(EXISTS "${THIRDPARTY_INSTALL_DIR}")
        file(GLOB _component_dirs "${THIRDPARTY_INSTALL_DIR}/*")
        foreach(_dir IN LISTS _component_dirs)
            if(IS_DIRECTORY "${_dir}")
                get_filename_component(_component_name "${_dir}" NAME)
                
                # Skip common non-component directories
                if(_component_name MATCHES "^(tmp|temp|build|src|downloads)$")
                    continue()
                endif()
                
                # Check if this looks like a valid component installation
                # (has lib, include, or lib/cmake subdirectories)
                if(EXISTS "${_dir}/lib" OR EXISTS "${_dir}/include" OR EXISTS "${_dir}/lib/cmake")
                    list(APPEND _root_paths "${_dir}")
                    message(STATUS "[thirdparty] Found component for CMAKE_FIND_ROOT_PATH: ${_component_name}")
                endif()
            endif()
        endforeach()
    endif()
    
    # Convert list to semicolon-separated string as expected by CMake
    if(_root_paths)
        string(REPLACE ";" ";" _root_paths_str "${_root_paths}")
        set(${output_var} "${_root_paths_str}" PARENT_SCOPE)
        list(LENGTH _root_paths _path_count)
        message(STATUS "[thirdparty] CMAKE_FIND_ROOT_PATH contains ${_path_count} component paths")
    else()
        set(${output_var} "" PARENT_SCOPE)
        message(STATUS "[thirdparty] No installed components found for CMAKE_FIND_ROOT_PATH")
    endif()
endfunction()
