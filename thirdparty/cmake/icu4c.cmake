# ICU4C third-party integration
# Reference: https://github.com/unicode-org/icu
# Dependencies: None

# This configuration provides ICU4C static libraries using the official autotools build system.
# ICU4C is the C/C++ library for Unicode and locale processing.

thirdparty_check_dependencies("icu4c")

# Set up directories
set(ICU4C_NAME "icu4c")
set(ICU4C_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/icu4c-${ICU4C_VERSION_UNDERSCORE}-src.tgz")
set(ICU4C_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${ICU4C_NAME}")
set(ICU4C_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${ICU4C_NAME}")
set(ICU4C_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${ICU4C_NAME}")

get_filename_component(ICU4C_INSTALL_DIR "${ICU4C_INSTALL_DIR}" ABSOLUTE)

# Download and extract ICU4C
thirdparty_download_and_check("${ICU4C_URL}" "${ICU4C_DOWNLOAD_FILE}" "${ICU4C_SHA256}")
if(NOT EXISTS "${ICU4C_SOURCE_DIR}/source/configure")
    thirdparty_extract_and_rename("${ICU4C_DOWNLOAD_FILE}" "${ICU4C_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/icu*")
endif()

# Custom ICU4C configuration and build function
function(icu4c_configure_and_build)
    set(ICU_SOURCE_DIR "${ICU4C_SOURCE_DIR}/source")
    
    # Configure build options for autotools
    # We build static libraries for better portability
    set(ICU4C_CONFIGURE_ARGS
        --prefix=${ICU4C_INSTALL_DIR}
        --enable-static
        --disable-shared
        --disable-samples
        --disable-tests
        --enable-tools
        --with-data-packaging=static
        # Enable threading support
        --enable-threads
        # Disable unnecessary components to reduce build time
        --disable-extras
        --disable-icuio
        --disable-layout
    )

    # Add architecture-specific flags
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        list(APPEND ICU4C_CONFIGURE_ARGS --build=aarch64-apple-darwin)
    endif()

    # Set compiler flags for static linking
    set(ENV{CXXFLAGS} "-fPIC -O2")
    set(ENV{CFLAGS} "-fPIC -O2")

    if(NOT EXISTS "${ICU4C_BUILD_DIR}/Makefile")
        message(STATUS "Configuring ICU4C...")
        file(MAKE_DIRECTORY "${ICU4C_BUILD_DIR}")
        
        execute_process(
            COMMAND "${ICU_SOURCE_DIR}/configure" ${ICU4C_CONFIGURE_ARGS}
            WORKING_DIRECTORY "${ICU4C_BUILD_DIR}"
            RESULT_VARIABLE _configure_result
            OUTPUT_VARIABLE _configure_output
            ERROR_VARIABLE _configure_error
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
        )
        
        if(_configure_output)
            message(STATUS "Configure output: ${_configure_output}")
        endif()
        if(_configure_error)
            message(STATUS "Configure error: ${_configure_error}")
        endif()
        
        if(NOT _configure_result EQUAL 0)
            message(FATAL_ERROR "Failed to configure ICU4C. Return code: ${_configure_result}")
        endif()
    endif()

    # Determine number of parallel jobs
    include(ProcessorCount)
    ProcessorCount(N)
    if(NOT N EQUAL 0)
        set(PARALLEL_JOBS ${N})
    else()
        set(PARALLEL_JOBS 4)
    endif()

    message(STATUS "Building ICU4C with ${PARALLEL_JOBS} parallel jobs...")
    
    # Build ICU4C
    execute_process(
        COMMAND make -j${PARALLEL_JOBS}
        WORKING_DIRECTORY "${ICU4C_BUILD_DIR}"
        RESULT_VARIABLE _build_result
    )
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build ICU4C.")
    endif()

    message(STATUS "Installing ICU4C...")
    
    # Install ICU4C
    execute_process(
        COMMAND make install
        WORKING_DIRECTORY "${ICU4C_BUILD_DIR}"
        RESULT_VARIABLE _install_result
    )
    if(NOT _install_result EQUAL 0)
        message(FATAL_ERROR "Failed to install ICU4C.")
    endif()
    
    message(STATUS "ICU4C built and installed successfully")
endfunction()

# Check if ICU4C is already built and installed
set(ICU4C_VALIDATION_FILES
    "${ICU4C_INSTALL_DIR}/lib/libicuuc.a"
    "${ICU4C_INSTALL_DIR}/lib/libicudata.a"
    "${ICU4C_INSTALL_DIR}/lib/libicui18n.a"
    "${ICU4C_INSTALL_DIR}/include/unicode/uversion.h"
    "${ICU4C_INSTALL_DIR}/bin/icu-config"
)

set(_all_files_exist TRUE)
foreach(_file IN LISTS ICU4C_VALIDATION_FILES)
    if(NOT EXISTS "${_file}")
        set(_all_files_exist FALSE)
        break()
    endif()
endforeach()

if(NOT _all_files_exist)
    message(STATUS "ICU4C not found or incomplete, building...")
    icu4c_configure_and_build()
else()
    message(STATUS "ICU4C already built and configured")
endif()

# Export ICU4C following project standards
if(EXISTS "${ICU4C_INSTALL_DIR}/lib/libicuuc.a")
    list(APPEND CMAKE_PREFIX_PATH "${ICU4C_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    
    # Create imported targets for ICU4C components
    if(NOT TARGET ICU::uc)
        add_library(ICU::uc STATIC IMPORTED)
        set_target_properties(ICU::uc PROPERTIES
            IMPORTED_LOCATION "${ICU4C_INSTALL_DIR}/lib/libicuuc.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
        )
    endif()
    
    if(NOT TARGET ICU::i18n)
        add_library(ICU::i18n STATIC IMPORTED)
        set_target_properties(ICU::i18n PROPERTIES
            IMPORTED_LOCATION "${ICU4C_INSTALL_DIR}/lib/libicui18n.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
            INTERFACE_LINK_LIBRARIES ICU::uc
        )
    endif()
    
    if(NOT TARGET ICU::data)
        add_library(ICU::data STATIC IMPORTED)
        set_target_properties(ICU::data PROPERTIES
            IMPORTED_LOCATION "${ICU4C_INSTALL_DIR}/lib/libicudata.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
        )
    endif()
    
    # Main ICU target that includes all components
    if(NOT TARGET ICU::ICU)
        add_library(ICU::ICU INTERFACE IMPORTED)
        set_target_properties(ICU::ICU PROPERTIES
            INTERFACE_LINK_LIBRARIES "ICU::i18n;ICU::uc;ICU::data"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
        )
    endif()
    
    message(STATUS "ICU4C found and exported globally: ${ICU4C_INSTALL_DIR}")
else()
    message(FATAL_ERROR "ICU4C configuration failed - missing library files")
endif()
