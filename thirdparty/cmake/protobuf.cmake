# Protobuf integration for the Halo project
# This file handles downloading, building, and installing Google Protocol Buffers

thirdparty_build_cmake_library("protobuf"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/protobuf-*"
    CMAKE_ARGS
        -Dprotobuf_BUILD_TESTS=OFF
        -Dprotobuf_BUILD_EXAMPLES=OFF
        -Dprotobuf_BUILD_PROTOC_BINARIES=ON
        -Dprotobuf_BUILD_SHARED_LIBS=OFF
        -Dprotobuf_MSVC_STATIC_RUNTIME=OFF
        -Dprotobuf_WITH_ZLIB=OFF
        -Dprotobuf_DISABLE_RTTI=OFF
        -Dprotobuf_ABSL_PROVIDER=package
        -Dprotobuf_BUILD_LIBPROTOC=ON
        -Dutf8_range_ENABLE_INSTALL=ON
        -Dabsl_DIR=${THIRDPARTY_INSTALL_DIR}/abseil/lib/cmake/absl
        # Force static linking of Abseil into protobuf
        -DCMAKE_FIND_LIBRARY_SUFFIXES=.a
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/protobuf/lib/libprotobuf.a"
        "${THIRDPARTY_INSTALL_DIR}/protobuf/include/google/protobuf/message.h"
        "${THIRDPARTY_INSTALL_DIR}/protobuf/bin/protoc"
)

find_package(protobuf CONFIG REQUIRED)
message(STATUS "Imported protobuf package targets")
