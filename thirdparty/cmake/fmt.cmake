# fmt third-party integration
# Reference: https://github.com/fmtlib/fmt

thirdparty_build_cmake_library("fmt"
    CMAKE_ARGS
        -DFMT_DOC=OFF
        -DFMT_TEST=OFF
        -DFMT_FUZZ=OFF
        -DFMT_CUDA_TEST=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/fmt/lib/cmake/fmt/fmt-config.cmake"
        "${THIRDPARTY_INSTALL_DIR}/fmt/lib/libfmt.a"
        "${THIRDPARTY_INSTALL_DIR}/fmt/include/fmt/format.h"
        "${THIRDPARTY_INSTALL_DIR}/fmt/include/fmt/core.h"
)

find_package(fmt CONFIG REQUIRED)

thirdparty_map_imported_config(fmt::fmt)
