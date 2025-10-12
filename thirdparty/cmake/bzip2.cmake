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
    
    # Apply Makefile patch to remove test target
    execute_process(
        COMMAND sed -i.bak "s/^all: libbz2.a test$/all: libbz2.a/" Makefile
        WORKING_DIRECTORY ${BZIP2_SOURCE_DIR}
    )

    # Setup environment for make (always force CC to main project compiler)
    set(_make_env "CC=${CMAKE_C_COMPILER}")
    
    # Set explicit linker for custom/non-standard locations
    if(DEFINED HALO_LINKER AND HALO_LINKER AND EXISTS "${HALO_LINKER}")
        list(APPEND _make_env "LD=${HALO_LINKER}")
        message(DEBUG "[bzip2] Set explicit linker environment: LD=${HALO_LINKER}")
    endif()
    
    # Apply project-level linker flags directly (for Makefile-based build)
    set(_ldflags "")
    if(CMAKE_EXE_LINKER_FLAGS)
        set(_ldflags "${CMAKE_EXE_LINKER_FLAGS}")
    endif()
    
    # Apply combined LDFLAGS
    if(_ldflags)
        list(APPEND _make_env "LDFLAGS=${_ldflags}")
    endif()
    
    # Some upstream bzip2 Makefiles assign CC?=gcc or CC=gcc after environment propagation.
    # Passing CC=<compiler> on the make command line has the highest precedence.
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E env ${_make_env} make CC=${CMAKE_C_COMPILER} -j${PARALLEL_JOBS} libbz2.a
        WORKING_DIRECTORY ${BZIP2_SOURCE_DIR}
        RESULT_VARIABLE build_result
    )
    
    if(NOT build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build bzip2")
    endif()

    # Install using the same enforced compiler environment
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E env ${_make_env} make CC=${CMAKE_C_COMPILER} install PREFIX=${BZIP2_INSTALL_DIR}
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
