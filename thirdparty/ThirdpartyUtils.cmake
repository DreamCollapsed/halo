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
    
    # Print the complete cmake command for debugging
    set(_cmake_cmd_str "${CMAKE_COMMAND} -S \"${_actual_src_dir}\" -B \"${builddir}\"")
    foreach(_arg ${ARG_CMAKE_ARGS})
        set(_cmake_cmd_str "${_cmake_cmd_str} ${_arg}")
    endforeach()
    message(STATUS "[thirdparty_cmake_configure] CMake command: ${_cmake_cmd_str}")
    
    execute_process(
        COMMAND ${CMAKE_COMMAND} -S "${_actual_src_dir}" -B "${builddir}" ${ARG_CMAKE_ARGS}
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

        # Sandbox mode: use thirdparty install dir for find_package searches
        -DCMAKE_FIND_ROOT_PATH=${THIRDPARTY_INSTALL_DIR}
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH

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
    include(ProcessorCount)
    ProcessorCount(N)
    if(NOT N EQUAL 0)
        set(PARALLEL_JOBS "-j${N}")
    else()
        set(PARALLEL_JOBS "-j4")  # Fallback
    endif()

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
