# libstemmer third-party integration
# Reference: https://snowballstem.org/
# libstemmer is a C library for stemming words down to their roots

thirdparty_setup_directories("libstemmer")

set(_validation_files
    "${LIBSTEMMER_INSTALL_DIR}/lib/libstemmer.a"
    "${LIBSTEMMER_INSTALL_DIR}/include/libstemmer.h"
)

set(_need_build TRUE)
set(_all_files_exist TRUE)
foreach(_file ${_validation_files})
    if(NOT EXISTS "${_file}")
        set(_all_files_exist FALSE)
        break()
    endif()
endforeach()
if(_all_files_exist)
    message(STATUS "[libstemmer] All validation files exist, skip build.")
    set(_need_build FALSE)
endif()

if(_need_build)
    thirdparty_download_and_check("${LIBSTEMMER_URL}" "${LIBSTEMMER_DOWNLOAD_FILE}" "${LIBSTEMMER_SHA256}")
    thirdparty_extract_and_rename("${LIBSTEMMER_DOWNLOAD_FILE}" "${LIBSTEMMER_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/libstemmer_c-*")

    file(MAKE_DIRECTORY "${LIBSTEMMER_BUILD_DIR}")
    
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${LIBSTEMMER_SOURCE_DIR}" "${LIBSTEMMER_BUILD_DIR}"
        RESULT_VARIABLE _copy_result
    )
    if(NOT _copy_result EQUAL 0)
        message(FATAL_ERROR "Failed to copy libstemmer sources to build directory")
    endif()
    
    thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _make_jobs)
    set(PARALLEL_JOBS "-j${_make_jobs}")
    
    execute_process(
        COMMAND make ${PARALLEL_JOBS} CFLAGS=-fPIC
        WORKING_DIRECTORY "${LIBSTEMMER_BUILD_DIR}"
        RESULT_VARIABLE _build_result
    )
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build libstemmer")
    endif()
    
    file(MAKE_DIRECTORY "${LIBSTEMMER_INSTALL_DIR}/lib")
    file(MAKE_DIRECTORY "${LIBSTEMMER_INSTALL_DIR}/include")
    
    file(COPY "${LIBSTEMMER_BUILD_DIR}/libstemmer.a" 
         DESTINATION "${LIBSTEMMER_INSTALL_DIR}/lib/")
    
    file(COPY "${LIBSTEMMER_BUILD_DIR}/include/libstemmer.h" 
         DESTINATION "${LIBSTEMMER_INSTALL_DIR}/include/")
    
    message(STATUS "[libstemmer] Successfully installed to ${LIBSTEMMER_INSTALL_DIR}")
endif()

if(EXISTS "${LIBSTEMMER_INSTALL_DIR}/lib/libstemmer.a")
    if(NOT TARGET libstemmer::libstemmer)
        add_library(libstemmer::libstemmer STATIC IMPORTED)
        set_target_properties(libstemmer::libstemmer PROPERTIES
            IMPORTED_LOCATION "${LIBSTEMMER_INSTALL_DIR}/lib/libstemmer.a"
            INTERFACE_INCLUDE_DIRECTORIES "${LIBSTEMMER_INSTALL_DIR}/include"
        )
        
        message(STATUS "Created libstemmer::libstemmer target")
    endif()
    
    if(NOT TARGET stemmer)
        add_library(stemmer ALIAS libstemmer::libstemmer)
        message(STATUS "Created stemmer alias for libstemmer::libstemmer")
    endif()
    
    message(STATUS "libstemmer found and exported globally: ${LIBSTEMMER_INSTALL_DIR}")
else()
    message(FATAL_ERROR "libstemmer installation not found at ${LIBSTEMMER_INSTALL_DIR}")
endif()

set(LIBSTEMMER_INSTALL_DIR "${LIBSTEMMER_INSTALL_DIR}" PARENT_SCOPE)
get_filename_component(LIBSTEMMER_INSTALL_DIR "${LIBSTEMMER_INSTALL_DIR}" ABSOLUTE)
thirdparty_register_to_cmake_prefix_path("${LIBSTEMMER_INSTALL_DIR}")
