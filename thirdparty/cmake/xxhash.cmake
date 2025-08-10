# xxHash third-party integration
# Reference: https://github.com/Cyan4973/xxHash

thirdparty_setup_directories("xxhash")

thirdparty_download_and_check("${XXHASH_URL}" "${XXHASH_DOWNLOAD_FILE}" "${XXHASH_SHA256}")
thirdparty_extract_and_rename("${XXHASH_DOWNLOAD_FILE}" "${XXHASH_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/xxHash-*")

if(NOT EXISTS "${XXHASH_INSTALL_DIR}/lib/libxxhash.a")
    thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _make_jobs)
    set(PARALLEL_JOBS "-j${_make_jobs}")
    execute_process(
        COMMAND make ${PARALLEL_JOBS} install_libxxhash.a install_libxxhash.includes "PREFIX=${XXHASH_INSTALL_DIR}" CFLAGS=-fPIC
        WORKING_DIRECTORY "${XXHASH_SOURCE_DIR}"
        RESULT_VARIABLE _xxhash_build_result
    )
    if(_xxhash_build_result)
        message(FATAL_ERROR "Failed to build xxhash")
    endif()
    message(STATUS "xxhash built and installed successfully")
endif()

add_library(xxhash_thirdparty_static STATIC IMPORTED GLOBAL)
set_target_properties(xxhash_thirdparty_static PROPERTIES
    IMPORTED_LOCATION "${XXHASH_INSTALL_DIR}/lib/libxxhash.a"
    INTERFACE_INCLUDE_DIRECTORIES "${XXHASH_INSTALL_DIR}/include"
)

add_library(xxhash::xxhash ALIAS xxhash_thirdparty_static)

thirdparty_register_to_cmake_prefix_path("${XXHASH_INSTALL_DIR}")

message(STATUS "xxhash build configured and completed during configure time.")
