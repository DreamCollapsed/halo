# fmt third-party integration
# Reference: https://github.com/fmtlib/fmt

# Use the standardized build function for simple CMake libraries
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

# Additional fmt-specific setup
set(FMT_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/fmt")
get_filename_component(FMT_INSTALL_DIR "${FMT_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${FMT_INSTALL_DIR}/lib/cmake/fmt/fmt-config.cmake")
    set(fmt_DIR "${FMT_INSTALL_DIR}/lib/cmake/fmt" CACHE PATH "Path to installed fmt cmake config" FORCE)
    message(STATUS "fmt found and exported globally: ${FMT_INSTALL_DIR}")
else()
    message(WARNING "fmt installation not found at ${FMT_INSTALL_DIR}")
endif()
