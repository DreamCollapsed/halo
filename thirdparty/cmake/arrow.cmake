# Apache Arrow third-party integration (C++)
# Reference: https://arrow.apache.org

thirdparty_setup_directories("arrow")

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${ARROW_INSTALL_DIR}

    -DARROW_BUILD_SHARED=OFF
    -DARROW_BUILD_STATIC=ON

    # Use system dependencies we already build
    -DARROW_DEPENDENCY_SOURCE=SYSTEM
    -DARROW_DEPENDENCY_USE_SHARED=OFF

    # Prefer static variants of system dependencies (avoid dylibs)
    -DARROW_LZ4_USE_SHARED=OFF
    -DARROW_ZSTD_USE_SHARED=OFF
    -DARROW_SNAPPY_USE_SHARED=OFF
    -DARROW_BZ2_USE_SHARED=OFF

    # Hint CMake find modules to pick static libs where supported
    -DZLIB_USE_STATIC_LIBS=ON
    -DLZ4_USE_STATIC_LIBS=ON
    -DZSTD_USE_STATIC_LIBS=ON
    -DSNAPPY_USE_STATIC_LIBS=ON
    -DBZIP2_USE_STATIC_LIBS=ON

    -DARROW_PARQUET=OFF
    -DARROW_DATASET=OFF
    -DARROW_COMPUTE=OFF
    -DARROW_CSV=OFF
    -DARROW_JSON=OFF
    -DARROW_FLIGHT=OFF
    -DARROW_GANDIVA=OFF
    -DARROW_FILESYSTEM=ON
    -DARROW_ORC=OFF
    -DARROW_WITH_RE2=OFF
    -DARROW_WITH_UTF8PROC=OFF
    -DARROW_USE_GLOG=ON
    -DARROW_WITH_BROTLI=OFF
    -DARROW_WITH_GRPC=OFF

    -DARROW_WITH_ZLIB=ON
    -DARROW_WITH_ZSTD=ON
    -DARROW_WITH_LZ4=ON
    -DARROW_WITH_SNAPPY=ON
    -DARROW_WITH_BZ2=ON
    -DARROW_WITH_LZMA=ON

    -DARROW_BUILD_TESTS=OFF
    -DARROW_BUILD_EXAMPLES=OFF
    -DARROW_BUILD_BENCHMARKS=OFF
    -DARROW_BUILD_INTEGRATION=OFF
    -DARROW_BUILD_UTILITIES=OFF
)

thirdparty_build_cmake_library("arrow"
    SOURCE_SUBDIR "cpp"
    CMAKE_ARGS ${_opt_flags}
    VALIDATION_FILES
        "${ARROW_INSTALL_DIR}/lib/libarrow.a"
        "${ARROW_INSTALL_DIR}/lib/cmake/Arrow/ArrowConfig.cmake"
)

find_package(Arrow CONFIG REQUIRED)
if(TARGET Arrow::arrow_static AND NOT TARGET Arrow::arrow)
    add_library(Arrow::arrow ALIAS Arrow::arrow_static)
endif()
message(STATUS "Arrow imported into superproject: ${ARROW_INSTALL_DIR}")
