# lz4 third-party integration
# Reference: https://github.com/lz4/lz4

thirdparty_build_cmake_library("lz4"
    SOURCE_SUBDIR "build/cmake"
    # LZ4_INSTALL_DIR is only defined after the helper returns; use deterministic path here.
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/lz4/lib/liblz4.a"
        "${THIRDPARTY_INSTALL_DIR}/lz4/include/lz4.h"
    CMAKE_ARGS
        -DLZ4_BUILD_CLI=OFF
        -DLZ4_BUILD_LEGACY_LIBS=OFF
        -DLZ4_BUNDLE_MODE=OFF
        -DLZ4_POSITION_INDEPENDENT_CODE=ON
)

find_package(lz4 CONFIG REQUIRED)

thirdparty_map_imported_config(LZ4::lz4_static LZ4::lz4)

message(DEBUG "lz4 found and imported: ${LZ4_INSTALL_DIR}")
