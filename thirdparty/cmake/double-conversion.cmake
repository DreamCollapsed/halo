# double-conversion third-party integration
# Reference: https://github.com/google/double-conversion

thirdparty_build_cmake_library("double-conversion"
    CMAKE_ARGS
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/cmake/double-conversion/double-conversionConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/libdouble-conversion.a"
        "${THIRDPARTY_INSTALL_DIR}/double-conversion/include/double-conversion/double-conversion.h"
)

set(DOUBLE_CONVERSION_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/double-conversion")
get_filename_component(DOUBLE_CONVERSION_INSTALL_DIR "${DOUBLE_CONVERSION_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${DOUBLE_CONVERSION_INSTALL_DIR}/lib/cmake/double-conversion/double-conversionConfig.cmake")
    find_package(double-conversion CONFIG REQUIRED)
    message(STATUS "double-conversion found and exported globally: ${DOUBLE_CONVERSION_INSTALL_DIR}")
else()
    message(FATAL_ERROR "double-conversion installation not found at ${DOUBLE_CONVERSION_INSTALL_DIR}")
endif()
