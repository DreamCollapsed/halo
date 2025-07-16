# fast-float third-party integration
# Reference: https://github.com/fastfloat/fast_float

# Use the standardized build function for simple CMake libraries
thirdparty_build_cmake_library("fast-float"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/fast_float-*"
    CMAKE_ARGS
        -DFASTFLOAT_TEST=OFF
        -DFASTFLOAT_SANITIZE=OFF
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/fast-float/share/cmake/FastFloat/FastFloatConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/fast-float/include/fast_float/fast_float.h"
)

# Additional fast-float-specific setup
set(FAST_FLOAT_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/fast-float")
get_filename_component(FAST_FLOAT_INSTALL_DIR "${FAST_FLOAT_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${FAST_FLOAT_INSTALL_DIR}/share/cmake/FastFloat/FastFloatConfig.cmake")
    set(FastFloat_DIR "${FAST_FLOAT_INSTALL_DIR}/share/cmake/FastFloat" CACHE PATH "Path to installed fast-float cmake config" FORCE)
    message(STATUS "fast-float found and exported globally: ${FAST_FLOAT_INSTALL_DIR}")
else()
    message(WARNING "fast-float installation not found at ${FAST_FLOAT_INSTALL_DIR}")
endif()
