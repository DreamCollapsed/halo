# Boost third-party integration
# Reference: https://github.com/boostorg/boost
# Dependencies: xz, zlib, cares

set(Boost_USE_STATIC_LIBS ON CACHE BOOL "Force static linking for Boost")
set(Boost_USE_STATIC_RUNTIME ON CACHE BOOL "Force static runtime for Boost")

thirdparty_setup_directories("boost")

thirdparty_acquire_source("boost" BOOST_SOURCE_DIR)

function(boost_configure_and_build)
    thirdparty_get_build_jobs(OUTPUT_MAKE_JOBS _parallel_jobs)

    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(BOOST_ARCHITECTURE "arm")
        set(BOOST_ADDRESS_MODEL "64")
    else()
        set(BOOST_ARCHITECTURE "x86")
        set(BOOST_ADDRESS_MODEL "64")
    endif()

    # Enforce clang-only: fail fast if the chosen C++ compiler is not clang++ (versioned allowed)
    if(NOT CMAKE_CXX_COMPILER)
        message(FATAL_ERROR "[boost] CMAKE_CXX_COMPILER is not set; clang++ required")
    endif()
    # Trust the top-level CMake toolchain (already validated elsewhere); force Boost toolset=clang
    message(DEBUG "[boost] Using clang toolset with compiler='${CMAKE_CXX_COMPILER}' (no local name regex validation)")

    set(BOOST_B2_OPTIONS
        variant=release
        link=static
        runtime-link=static
        threading=multi
        cxxstd=23
        address-model=${BOOST_ADDRESS_MODEL}
        architecture=${BOOST_ARCHITECTURE}
        --layout=tagged
        toolset=clang
        --prefix=${BOOST_INSTALL_DIR}
        --build-dir=${BOOST_BUILD_DIR}
        -sZLIB_INCLUDE=${THIRDPARTY_INSTALL_DIR}/zlib/include
        -sZLIB_LIBPATH=${THIRDPARTY_INSTALL_DIR}/zlib/lib
        -sZLIB_LIBRARY=${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
        -sLZMA_INCLUDE=${THIRDPARTY_INSTALL_DIR}/xz/include
        -sLZMA_LIBPATH=${THIRDPARTY_INSTALL_DIR}/xz/lib
        -sLZMA_LIBRARY=${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a
        -sCARES_INCLUDE=${THIRDPARTY_INSTALL_DIR}/cares/include
        -sCARES_LIBPATH=${THIRDPARTY_INSTALL_DIR}/cares/lib
        -sCARES_LIBRARY=${THIRDPARTY_INSTALL_DIR}/cares/lib/libcares.a
        -sNO_ZLIB=1
        -sNO_LZMA=1
        -sNO_BZIP2=1
        -sZLIB_NAME=
        -sLZMA_NAME=
        linkflags=-L${THIRDPARTY_INSTALL_DIR}/zlib/lib
        linkflags=-L${THIRDPARTY_INSTALL_DIR}/xz/lib
        linkflags=-L${THIRDPARTY_INSTALL_DIR}/cares/lib
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
        --with-process
        headers
        -j${_parallel_jobs}
    )

    # Print compiler information for debugging
    message(STATUS "[boost] CMAKE_CXX_COMPILER: ${CMAKE_CXX_COMPILER}")
    message(STATUS "[boost] CMAKE_C_COMPILER: ${CMAKE_C_COMPILER}")
    message(STATUS "[boost] Boost toolset: clang")

    # Apply CMAKE_EXE_LINKER_FLAGS (contains linker selection flags like -fuse-ld=*)
    if(DEFINED CMAKE_EXE_LINKER_FLAGS AND CMAKE_EXE_LINKER_FLAGS)
        string(REPLACE " " ";" _cmake_linker_flags "${CMAKE_EXE_LINKER_FLAGS}")
        foreach(_flag ${_cmake_linker_flags})
            list(APPEND BOOST_B2_OPTIONS linkflags=${_flag})
        endforeach()
        message(DEBUG "[boost] Added CMAKE_EXE_LINKER_FLAGS: ${CMAKE_EXE_LINKER_FLAGS}")
    endif()

    # macOS specific linker behavior: only add force_load & search_paths_first on Apple
    if(APPLE)
        list(APPEND BOOST_B2_OPTIONS
            linkflags=-Wl,-search_paths_first
            linkflags=-Wl,-force_load,${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
            linkflags=-Wl,-force_load,${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a
            linkflags=-Wl,-force_load,${THIRDPARTY_INSTALL_DIR}/cares/lib/libcares.a
        )
        message(STATUS "[boost] Added macOS specific -force_load and -search_paths_first flags")
    endif()

    if(_boost_verbose_dump)
        message(STATUS "[boost] Final B2 options (verbose dump):")
        foreach(_option ${BOOST_B2_OPTIONS})
            message(STATUS "[boost]   ${_option}")
        endforeach()
    else()
        foreach(_option ${BOOST_B2_OPTIONS})
            message(STATUS "[boost]   ${_option}")
        endforeach()
    endif()

    if(NOT EXISTS "${BOOST_SOURCE_DIR}/b2")
        # Setup environment for bootstrap
        set(_bootstrap_env)
        if(CMAKE_CXX_COMPILER)
            list(APPEND _bootstrap_env "CXX=${CMAKE_CXX_COMPILER}")
        endif()
        if(CMAKE_C_COMPILER)
            list(APPEND _bootstrap_env "CC=${CMAKE_C_COMPILER}")
        endif()

        if(_bootstrap_env)
            execute_process(
                COMMAND ${CMAKE_COMMAND} -E env ${_bootstrap_env} bash bootstrap.sh --with-toolset=clang --prefix=${BOOST_INSTALL_DIR}
                WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
                RESULT_VARIABLE _bootstrap_result
            )
        else()
            execute_process(
                COMMAND bash bootstrap.sh --with-toolset=clang --prefix=${BOOST_INSTALL_DIR}
                WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
                RESULT_VARIABLE _bootstrap_result
            )
        endif()

        if(NOT _bootstrap_result EQUAL 0)
            message(FATAL_ERROR "Failed to bootstrap Boost b2.")
        endif()
    endif()

    file(MAKE_DIRECTORY "${BOOST_BUILD_DIR}")

    # Setup environment for b2 build
    set(_build_env)
    if(CMAKE_CXX_COMPILER)
        list(APPEND _build_env "CXX=${CMAKE_CXX_COMPILER}")
        message(STATUS "[boost] Setting CXX environment: ${CMAKE_CXX_COMPILER}")
    endif()
    if(CMAKE_C_COMPILER)
        list(APPEND _build_env "CC=${CMAKE_C_COMPILER}")
        message(STATUS "[boost] Setting CC environment: ${CMAKE_C_COMPILER}")
    endif()
    
    # Set explicit linker for custom/non-standard locations
    if(DEFINED HALO_LINKER AND HALO_LINKER AND EXISTS "${HALO_LINKER}")
        list(APPEND _build_env "LD=${HALO_LINKER}")
        message(STATUS "[boost] Set explicit linker environment: LD=${HALO_LINKER}")
    endif()

    # Print environment variables for debugging
    if(_build_env)
        message(STATUS "[boost] Build environment variables:")
        foreach(_env_var ${_build_env})
            message(STATUS "[boost]   ${_env_var}")
        endforeach()
    endif()

    if(_build_env)
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E env ${_build_env} ./b2 install ${BOOST_B2_OPTIONS}
            WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
            RESULT_VARIABLE _build_result
        )
    else()
        execute_process(
            COMMAND ./b2 install ${BOOST_B2_OPTIONS}
            WORKING_DIRECTORY "${BOOST_SOURCE_DIR}"
            RESULT_VARIABLE _build_result
        )
    endif()
    if(NOT _build_result EQUAL 0)
        message(FATAL_ERROR "Failed to build and install Boost.")
    endif()
    message(STATUS "Boost built and installed successfully")
endfunction()

set(BOOST_VALIDATION_FILES
    "${BOOST_INSTALL_DIR}/lib/cmake/Boost-${BOOST_VERSION}/BoostConfig.cmake"
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

thirdparty_map_imported_config(
    Boost::system
    Boost::filesystem
    Boost::thread
    Boost::chrono
    Boost::date_time
    Boost::regex
    Boost::program_options
    Boost::iostreams
    Boost::random
    Boost::context
    Boost::coroutine
    Boost::atomic
    Boost::container
    Boost::log
    Boost::timer
    Boost::serialization
    Boost::math
    Boost::json
    Boost::stacktrace_basic
    Boost::url
    Boost::wave
    Boost::fiber
    Boost::exception
    Boost::graph
)
