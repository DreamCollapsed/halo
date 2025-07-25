# bzip2
thirdparty_setup_directories(bzip2)

# Check dependencies first
thirdparty_check_dependencies("bzip2")

thirdparty_download_and_check("${BZIP2_URL}" "${BZIP2_DOWNLOAD_FILE}" "${BZIP2_SHA256}")
thirdparty_extract_and_rename("${BZIP2_DOWNLOAD_FILE}" "${BZIP2_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/bzip2-*")

set(_validation_files
    "${BZIP2_INSTALL_DIR}/lib/libbz2.a"
    "${BZIP2_INSTALL_DIR}/include/bzlib.h"
)

set(_need_build TRUE)
set(_all_files_exist TRUE)
foreach(_file ${_validation_files})
    if(NOT EXISTS "${_file}")
        set(_all_files_exist FALSE)
        break()
    endif()
endforeach()
if(${_all_files_exist})
    set(_need_build FALSE)
endif()

if(_need_build)
    message(STATUS "Building bzip2...")
    
    # Get number of parallel jobs
    include(ProcessorCount)
    ProcessorCount(N)
    if(NOT N EQUAL 0)
        set(PARALLEL_JOBS ${N})
    else()
        set(PARALLEL_JOBS 4)  # Fallback to 4 jobs
    endif()
    
    # Patch Makefile for parallel build
    execute_process(
        COMMAND sed -i.bak "s/^all: libbz2.a test$/all: libbz2.a/" Makefile
        WORKING_DIRECTORY ${BZIP2_SOURCE_DIR}
    )

    # Build static library
    execute_process(
        COMMAND make -j${PARALLEL_JOBS} libbz2.a
        WORKING_DIRECTORY ${BZIP2_SOURCE_DIR}
        RESULT_VARIABLE build_result
    )
    if(NOT build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build bzip2")
    endif()

    # Install
    execute_process(
        COMMAND make install PREFIX=${BZIP2_INSTALL_DIR}
        WORKING_DIRECTORY ${BZIP2_SOURCE_DIR}
        RESULT_VARIABLE install_result
    )
    if(NOT install_result EQUAL 0)
        message(FATAL_ERROR "Failed to install bzip2")
    endif()
else()
    message(STATUS "bzip2 already built.")
endif()

add_library(BZip2::BZip2 STATIC IMPORTED GLOBAL)
set_target_properties(BZip2::BZip2 PROPERTIES
    IMPORTED_LOCATION "${BZIP2_INSTALL_DIR}/lib/libbz2.a"
    INTERFACE_INCLUDE_DIRECTORIES "${BZIP2_INSTALL_DIR}/include"
)

message(STATUS "bzip2 found and exported globally: ${BZIP2_INSTALL_DIR}")
