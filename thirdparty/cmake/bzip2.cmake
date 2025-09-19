# bzip2
thirdparty_setup_directories(bzip2)

thirdparty_acquire_source("bzip2" BZIP2_SOURCE_DIR)

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
    thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _make_jobs)
    set(PARALLEL_JOBS ${_make_jobs})
    
    execute_process(
        COMMAND sed -i.bak "s/^all: libbz2.a test$/all: libbz2.a/" Makefile
        WORKING_DIRECTORY ${BZIP2_SOURCE_DIR}
    )

    execute_process(
        COMMAND make -j${PARALLEL_JOBS} libbz2.a
        WORKING_DIRECTORY ${BZIP2_SOURCE_DIR}
        RESULT_VARIABLE build_result
    )
    if(NOT build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build bzip2")
    endif()

    execute_process(
        COMMAND make install PREFIX=${BZIP2_INSTALL_DIR}
        WORKING_DIRECTORY ${BZIP2_SOURCE_DIR}
        RESULT_VARIABLE install_result
    )
    if(NOT install_result EQUAL 0)
        message(FATAL_ERROR "Failed to install bzip2")
    endif()
else()
    message(DEBUG "bzip2 already built.")
endif()

add_library(BZip2::BZip2 STATIC IMPORTED GLOBAL)
set_target_properties(BZip2::BZip2 PROPERTIES
    IMPORTED_LOCATION "${BZIP2_INSTALL_DIR}/lib/libbz2.a"
    INTERFACE_INCLUDE_DIRECTORIES "${BZIP2_INSTALL_DIR}/include"
)

thirdparty_register_to_cmake_prefix_path("${BZIP2_INSTALL_DIR}")
