# Boost third-party integration
# Reference: https://github.com/boostorg/boost
# Dependencies: None

set(Boost_USE_STATIC_LIBS ON CACHE BOOL "Force static linking for Boost")
set(Boost_USE_STATIC_RUNTIME ON CACHE BOOL "Force static runtime for Boost")

thirdparty_setup_directories("boost")

thirdparty_download_and_check("${BOOST_URL}" "${BOOST_DOWNLOAD_FILE}" "${BOOST_SHA256}")
if(NOT EXISTS "${BOOST_SOURCE_DIR}/bootstrap.sh")
    thirdparty_extract_and_rename("${BOOST_DOWNLOAD_FILE}" "${BOOST_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/boost_*")
endif()

function(boost_configure_and_build)
    thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _parallel_jobs)

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(BOOST_ARCHITECTURE "arm")
        set(BOOST_ADDRESS_MODEL "64")
    else()
        set(BOOST_ARCHITECTURE "x86")
        set(BOOST_ADDRESS_MODEL "64")
    endif()

    set(BOOST_B2_OPTIONS
        variant=release
        link=static
        runtime-link=static
        threading=multi
        cxxstd=17
        address-model=${BOOST_ADDRESS_MODEL}
        architecture=${BOOST_ARCHITECTURE}
        --layout=tagged
        --prefix=${BOOST_INSTALL_DIR}
        --build-dir=${BOOST_BUILD_DIR}
        -sZLIB_INCLUDE=${THIRDPARTY_INSTALL_DIR}/zlib/include
        -sZLIB_LIBPATH=${THIRDPARTY_INSTALL_DIR}/zlib/lib
        -sZLIB_LIBRARY=${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
        -sLZMA_INCLUDE=${THIRDPARTY_INSTALL_DIR}/xz/include
        -sLZMA_LIBPATH=${THIRDPARTY_INSTALL_DIR}/xz/lib
        -sLZMA_LIBRARY=${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a
        -sNO_ZLIB=1
        -sNO_LZMA=1
        -sNO_BZIP2=1
        -sZLIB_NAME=
        -sLZMA_NAME=
        linkflags=-L${THIRDPARTY_INSTALL_DIR}/zlib/lib
        linkflags=-L${THIRDPARTY_INSTALL_DIR}/xz/lib
        linkflags=-Wl,-search_paths_first
        linkflags=-Wl,-force_load,${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
        linkflags=-Wl,-force_load,${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a
        --with-atomic
        --with-chrono
        --with-container
        --with-context
        --with-coroutine
        --with-date_time
        --with-exception
        --with-fiber
        --with-filesystem
        --with-graph
        --with-iostreams
        --with-json
        --with-log
        --with-math
        --with-program_options
        --with-random
        --with-regex
        --with-serialization
        --with-stacktrace
        --with-system
        --with-thread
        --with-timer
        --with-url
        --with-wave
        headers
        -j${_parallel_jobs}
    )

    if(NOT EXISTS "${BOOST_SOURCE_DIR}/b2")
        execute_process(
            COMMAND bash bootstrap.sh --prefix=${BOOST_INSTALL_DIR}
            WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
            RESULT_VARIABLE _bootstrap_result
        )
        if(NOT _bootstrap_result EQUAL 0)
            message(FATAL_ERROR "Failed to bootstrap Boost b2.")
        endif()
    endif()

    file(MAKE_DIRECTORY "${BOOST_BUILD_DIR}")

    execute_process(
        COMMAND ./b2 install ${BOOST_B2_OPTIONS}
        WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
        RESULT_VARIABLE _build_result
    )
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build and install Boost.")
    endif()
    message(STATUS "Boost built and installed successfully")
endfunction()

set(BOOST_VALIDATION_FILES
    "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}/BoostConfig.cmake"
    "${BOOST_INSTALL_DIR}/lib/libboost_context-mt-s-a64.a"
    "${BOOST_INSTALL_DIR}/lib/libboost_system-mt-s-a64.a"
)

set(_all_files_exist TRUE)
foreach(_file IN LISTS BOOST_VALIDATION_FILES)
    if(NOT EXISTS "${_file}")
        set(_all_files_exist FALSE)
        break()
    endif()
endforeach()

if(NOT _all_files_exist)
    boost_configure_and_build()
endif()
thirdparty_register_to_cmake_prefix_path("${BOOST_INSTALL_DIR}")

find_package(Boost CONFIG REQUIRED
    COMPONENTS
        system filesystem thread chrono date_time regex program_options 
        iostreams random context coroutine atomic container log timer
        serialization math json stacktrace_basic url wave
        fiber exception graph
)
message(STATUS "Boost found and exported globally: ${BOOST_INSTALL_DIR}")
