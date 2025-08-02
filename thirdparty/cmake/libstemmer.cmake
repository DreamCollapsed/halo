# libstemmer third-party integration
# Reference: https://snowballstem.org/
# libstemmer is a C library for stemming words down to their roots

# Check dependencies first
thirdparty_check_dependencies("libstemmer")

# Set up directories using common function
thirdparty_setup_directories("libstemmer")

# Override specific directory variables
set(LIBSTEMMER_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/libstemmer_c-${LIBSTEMMER_VERSION}.tar.gz")
set(LIBSTEMMER_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/libstemmer")
set(LIBSTEMMER_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/libstemmer")
set(LIBSTEMMER_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/libstemmer")
get_filename_component(LIBSTEMMER_INSTALL_DIR "${LIBSTEMMER_INSTALL_DIR}" ABSOLUTE)

# Check if already installed by validating files
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
    # Download and extract
    thirdparty_download_and_check("${LIBSTEMMER_URL}" "${LIBSTEMMER_DOWNLOAD_FILE}" "${LIBSTEMMER_SHA256}")
    thirdparty_extract_and_rename("${LIBSTEMMER_DOWNLOAD_FILE}" "${LIBSTEMMER_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/libstemmer_c-*")

    # libstemmer doesn't use autotools or CMake, it uses a simple Makefile
    # We need to build it manually
    message(STATUS "[libstemmer] Building libstemmer...")
    
    # Create build directory
    file(MAKE_DIRECTORY "${LIBSTEMMER_BUILD_DIR}")
    
    # Copy source files to build directory for out-of-source build
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${LIBSTEMMER_SOURCE_DIR}" "${LIBSTEMMER_BUILD_DIR}"
        RESULT_VARIABLE _copy_result
    )
    if(NOT _copy_result EQUAL 0)
        message(FATAL_ERROR "Failed to copy libstemmer sources to build directory")
    endif()
    
    # Build using make
    include(ProcessorCount)
    ProcessorCount(N)
    if(NOT N EQUAL 0)
        set(PARALLEL_JOBS "-j${N}")
    else()
        set(PARALLEL_JOBS "-j4")  # Fallback
    endif()
    
    execute_process(
        COMMAND make ${PARALLEL_JOBS} CFLAGS=-fPIC
        WORKING_DIRECTORY "${LIBSTEMMER_BUILD_DIR}"
        RESULT_VARIABLE _build_result
    )
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build libstemmer")
    endif()
    
    # Install manually (libstemmer doesn't have make install)
    file(MAKE_DIRECTORY "${LIBSTEMMER_INSTALL_DIR}/lib")
    file(MAKE_DIRECTORY "${LIBSTEMMER_INSTALL_DIR}/include")
    
    # Copy static library
    file(COPY "${LIBSTEMMER_BUILD_DIR}/libstemmer.a" 
         DESTINATION "${LIBSTEMMER_INSTALL_DIR}/lib/")
    
    # Copy header file
    file(COPY "${LIBSTEMMER_BUILD_DIR}/include/libstemmer.h" 
         DESTINATION "${LIBSTEMMER_INSTALL_DIR}/include/")
    
    message(STATUS "[libstemmer] Successfully installed to ${LIBSTEMMER_INSTALL_DIR}")
endif()

# Create modern CMake targets for libstemmer
if(EXISTS "${LIBSTEMMER_INSTALL_DIR}/lib/libstemmer.a")
    # Create libstemmer::libstemmer target
    if(NOT TARGET libstemmer::libstemmer)
        add_library(libstemmer::libstemmer STATIC IMPORTED)
        set_target_properties(libstemmer::libstemmer PROPERTIES
            IMPORTED_LOCATION "${LIBSTEMMER_INSTALL_DIR}/lib/libstemmer.a"
            INTERFACE_INCLUDE_DIRECTORIES "${LIBSTEMMER_INSTALL_DIR}/include"
        )
        
        message(STATUS "Created libstemmer::libstemmer target")
    endif()
    
    # Create a simpler alias for easier usage
    if(NOT TARGET stemmer)
        add_library(stemmer ALIAS libstemmer::libstemmer)
        message(STATUS "Created stemmer alias for libstemmer::libstemmer")
    endif()
    
    message(STATUS "libstemmer found and exported globally: ${LIBSTEMMER_INSTALL_DIR}")
else()
    message(WARNING "libstemmer installation not found at ${LIBSTEMMER_INSTALL_DIR}")
endif()

# Export the installation directory for other components to find
set(LIBSTEMMER_INSTALL_DIR "${LIBSTEMMER_INSTALL_DIR}" PARENT_SCOPE)
get_filename_component(LIBSTEMMER_INSTALL_DIR "${LIBSTEMMER_INSTALL_DIR}" ABSOLUTE)
thirdparty_register_to_cmake_prefix_path("${LIBSTEMMER_INSTALL_DIR}")
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
