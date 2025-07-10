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
            file(RENAME "${_unpacked_path}" "${srcdir}")
        endif()
    endif()
endfunction()

function(thirdparty_cmake_configure srcdir builddir)
    cmake_parse_arguments(PARSE_ARGV 2
        ARG
        "FORCE_CONFIGURE"
        "VALIDATION_PATTERN"
        "VALIDATION_FILES")

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
    execute_process(
        COMMAND ${CMAKE_COMMAND} -S "${srcdir}" -B "${builddir}" ${ARG_UNPARSED_ARGUMENTS}
        RESULT_VARIABLE result
    )

    if(NOT result EQUAL 0)
        message(WARNING "[thirdparty_cmake_configure] CMake configure failed for ${srcdir}")
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
        set(${CMAKE_CURRENT_FUNCTION_RESULT} 0 PARENT_SCOPE)
        return()
    endif()

    if(NOT EXISTS "${builddir}")
        message(WARNING "[thirdparty_cmake_install] Build directory ${builddir} not found, skip install.")
        set(${CMAKE_CURRENT_FUNCTION_RESULT} 1 PARENT_SCOPE)
        return()
    endif()
    
    # Build the project
    execute_process(
        COMMAND ${CMAKE_COMMAND} --build "${builddir}"
        RESULT_VARIABLE _build_result
    )
    
    if(_build_result EQUAL 0)
        # Create install directory if it doesn't exist
        file(MAKE_DIRECTORY "${installdir}")
        
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
