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
        "VALIDATION_PATTERN"
        "VALIDATION_FILES;CMAKE_ARGS")

    if(NOT EXISTS "${srcdir}/CMakeLists.txt")
        message(WARNING "[thirdparty_cmake_configure] ${srcdir}/CMakeLists.txt not found, skip configure.")
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

    message(STATUS "[thirdparty_cmake_configure] Configuring ${srcdir} to ${builddir}")
    
    # Print the complete cmake command for debugging
    set(_cmake_cmd_str "${CMAKE_COMMAND} -S \"${srcdir}\" -B \"${builddir}\"")
    foreach(_arg ${ARG_CMAKE_ARGS})
        set(_cmake_cmd_str "${_cmake_cmd_str} ${_arg}")
    endforeach()
    message(STATUS "[thirdparty_cmake_configure] CMake command: ${_cmake_cmd_str}")
    
    execute_process(
        COMMAND ${CMAKE_COMMAND} -S "${srcdir}" -B "${builddir}" ${ARG_CMAKE_ARGS}
        RESULT_VARIABLE result
        OUTPUT_VARIABLE output
        ERROR_VARIABLE error
    )

    if(NOT result EQUAL 0)
        message(WARNING "[thirdparty_cmake_configure] CMake configure failed for ${srcdir}")
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
    
    # Build the project with parallel jobs
    include(ProcessorCount)
    ProcessorCount(N)
    if(NOT N EQUAL 0)
        set(PARALLEL_JOBS ${N})
    else()
        set(PARALLEL_JOBS 4)  # Fallback to 4 jobs
    endif()
    
    message(STATUS "[thirdparty_cmake_install] Build command: ${CMAKE_COMMAND} --build \"${builddir}\" --parallel ${PARALLEL_JOBS}")
    
    execute_process(
        COMMAND ${CMAKE_COMMAND} --build "${builddir}" --parallel ${PARALLEL_JOBS}
        RESULT_VARIABLE _build_result
    )
    
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
        -DCMAKE_SUPPRESS_DEVELOPER_WARNINGS=ON
        -DCMAKE_WARN_DEPRECATED=OFF
        -Wno-dev
        --no-warn-unused-cli
    )
    
    # Add Link Time Optimization (LTO) if supported
    if(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE)
        list(APPEND _opt_flags -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON)
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

# Function to check if we should use ccache for faster recompilation
function(thirdparty_setup_ccache)
    find_program(CCACHE_FOUND ccache)
    if(CCACHE_FOUND)
        set(CMAKE_CXX_COMPILER_LAUNCHER ccache CACHE STRING "Use ccache for compilation" FORCE)
        set(CMAKE_C_COMPILER_LAUNCHER ccache CACHE STRING "Use ccache for compilation" FORCE)
        message(STATUS "Using ccache for faster recompilation")
    endif()
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
    set(options FORCE_CONFIGURE)
    set(oneValueArgs EXTRACT_PATTERN SOURCE_SUBDIR PRE_BUILD_HOOK)
    set(multiValueArgs DEPENDENCIES CMAKE_ARGS VALIDATION_FILES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    string(TOUPPER "${library_name}" _lib_upper)
    string(REPLACE "-" "_" _lib_upper "${_lib_upper}")
    
    # Check dependencies and build CMAKE_PREFIX_PATH for dependencies
    set(_dep_prefix_paths)
    if(ARG_DEPENDENCIES)
        string(REPLACE ";" ";" _deps_list "${ARG_DEPENDENCIES}")
        thirdparty_check_dependencies("${_deps_list}")
        
        # Add dependency paths to CMAKE_PREFIX_PATH for this build
        foreach(_dep IN LISTS _deps_list)
            set(_dep_install_dir "${THIRDPARTY_INSTALL_DIR}/${_dep}")
            if(EXISTS "${_dep_install_dir}")
                list(APPEND _dep_prefix_paths "${_dep_install_dir}")
            endif()
        endforeach()
    else()
        thirdparty_check_dependencies("${library_name}")
    endif()
    
    # Set up directories
    thirdparty_setup_directories("${library_name}")
    
    # Get directory variables and component info
    # Extract filename from URL automatically
    get_filename_component(_url_filename "${${_lib_upper}_URL}" NAME)
    set(_download_file "${THIRDPARTY_DOWNLOAD_DIR}/${_url_filename}")
    set(_source_dir "${THIRDPARTY_SRC_DIR}/${library_name}")
    set(_build_dir "${THIRDPARTY_BUILD_DIR}/${library_name}")
    set(_install_dir "${THIRDPARTY_INSTALL_DIR}/${library_name}")
    get_filename_component(_install_dir "${_install_dir}" ABSOLUTE)
    
    # Get component information from ComponentsInfo.cmake
    if(DEFINED ${_lib_upper}_URL)
        set(_url "${${_lib_upper}_URL}")
    else()
        message(FATAL_ERROR "URL not defined for ${library_name}. Check ComponentsInfo.cmake for ${_lib_upper}_URL")
    endif()
    
    if(DEFINED ${_lib_upper}_SHA256)
        set(_sha256 "${${_lib_upper}_SHA256}")
    else()
        message(FATAL_ERROR "SHA256 not defined for ${library_name}. Check ComponentsInfo.cmake for ${_lib_upper}_SHA256")
    endif()
    
    # Set extract pattern
    if(ARG_EXTRACT_PATTERN)
        set(_extract_pattern "${ARG_EXTRACT_PATTERN}")
    else()
        set(_extract_pattern "${THIRDPARTY_SRC_DIR}/${library_name}-*")
    endif()
    
    # Download and extract
    thirdparty_download_and_check("${_url}" "${_download_file}" "${_sha256}")
    thirdparty_extract_and_rename("${_download_file}" "${_source_dir}" "${_extract_pattern}")
    
    # Execute PRE_BUILD_HOOK if specified
    if(ARG_PRE_BUILD_HOOK)
        cmake_language(CALL ${ARG_PRE_BUILD_HOOK})
    endif()
    
    # Handle SOURCE_SUBDIR if specified
    if(ARG_SOURCE_SUBDIR)
        set(_cmake_source_dir "${_source_dir}/${ARG_SOURCE_SUBDIR}")
    else()
        set(_cmake_source_dir "${_source_dir}")
    endif()
    
    # Configure with optimization flags
    thirdparty_get_optimization_flags(_opt_flags)
    
    # Add dependency paths to CMAKE_PREFIX_PATH for the sub-cmake call
    if(_dep_prefix_paths)
        list(JOIN _dep_prefix_paths ";" _prefix_path_str)
        list(APPEND _opt_flags -DCMAKE_PREFIX_PATH=${_prefix_path_str})
        message(STATUS "[${library_name}] Using dependency paths: ${_prefix_path_str}")
    endif()
    
    list(APPEND _opt_flags
        -DCMAKE_INSTALL_PREFIX=${_install_dir}
        ${ARG_CMAKE_ARGS}
    )
    
    # Set default validation files if not provided
    if(NOT ARG_VALIDATION_FILES)
        set(ARG_VALIDATION_FILES
            "${_build_dir}/CMakeCache.txt"
            "${_build_dir}/Makefile"
        )
    endif()
    
    # Configure the project
    if(ARG_FORCE_CONFIGURE)
        thirdparty_cmake_configure("${_cmake_source_dir}" "${_build_dir}"
            FORCE_CONFIGURE
            VALIDATION_FILES ${ARG_VALIDATION_FILES}
            CMAKE_ARGS ${_opt_flags}
        )
    else()
        thirdparty_cmake_configure("${_cmake_source_dir}" "${_build_dir}"
            VALIDATION_FILES ${ARG_VALIDATION_FILES}
            CMAKE_ARGS ${_opt_flags}
        )
    endif()
    
    # Set default install validation files
    set(_install_validation_files)
    
    # Try different common config file patterns
    set(_possible_configs
        "${_install_dir}/lib/cmake/${library_name}/${library_name}-config.cmake"
        "${_install_dir}/lib/cmake/${library_name}/${library_name}Config.cmake"
        "${_install_dir}/lib/cmake/${_lib_upper}/${_lib_upper}Config.cmake"
    )
    
    # Use provided validation files if available
    if(ARG_VALIDATION_FILES)
        list(APPEND _install_validation_files ${ARG_VALIDATION_FILES})
    endif()
    
    # Build and install
    thirdparty_cmake_install("${_build_dir}" "${_install_dir}"
        VALIDATION_FILES ${_install_validation_files}
    )
    
    # Export to global scope - try different config file patterns
    set(_config_found FALSE)
    foreach(_config_path IN LISTS _possible_configs)
        if(EXISTS "${_config_path}")
            list(APPEND CMAKE_PREFIX_PATH "${_install_dir}")
            set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
            message(STATUS "Added ${library_name} to CMAKE_PREFIX_PATH: ${_install_dir}")
            set(_config_found TRUE)
            break()
        endif()
    endforeach()
    
    # If standard patterns didn't work, search for any config file
    if(NOT _config_found)
        file(GLOB_RECURSE _all_configs "${_install_dir}/lib/cmake/*/*config.cmake")
        file(GLOB_RECURSE _all_configs_cap "${_install_dir}/lib/cmake/*/*Config.cmake")
        list(APPEND _all_configs ${_all_configs_cap})
        
        if(_all_configs)
            list(GET _all_configs 0 _found_config)
            list(APPEND CMAKE_PREFIX_PATH "${_install_dir}")
            set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
            message(STATUS "Added ${library_name} to CMAKE_PREFIX_PATH: ${_install_dir} (found config: ${_found_config})")
            set(_config_found TRUE)
        endif()
    endif()
    
    if(NOT _config_found)
        message(STATUS "${library_name} config file not found, but ${_install_dir} added to CMAKE_PREFIX_PATH")
        list(APPEND CMAKE_PREFIX_PATH "${_install_dir}")
        set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    endif()
endfunction()
