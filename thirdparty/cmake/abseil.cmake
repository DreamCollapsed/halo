# abseil third-party integration
# Reference: https://abseil.io/docs/cpp/tools/cmake-installs#initialize-your-project

# Use the standardized build function for simple CMake libraries
thirdparty_build_cmake_library("abseil"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/abseil-cpp-*"
    CMAKE_ARGS
        -DABSL_PROPAGATE_CXX_STD=ON
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/abseil/lib/cmake/absl/abslConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/abseil/lib/libabsl_strings.a"
        "${THIRDPARTY_INSTALL_DIR}/abseil/include/absl/strings/string_view.h"
)

# Additional abseil-specific setup
set(ABSEIL_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/abseil")
get_filename_component(ABSEIL_INSTALL_DIR "${ABSEIL_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${ABSEIL_INSTALL_DIR}/lib/cmake/absl/abslConfig.cmake")
    set(absl_DIR "${ABSEIL_INSTALL_DIR}/lib/cmake/absl" CACHE PATH "Path to installed abseil cmake config" FORCE)
    
    # Import abseil package immediately
    find_package(absl REQUIRED CONFIG QUIET)
    
    message(STATUS "Abseil found and exported globally: ${ABSEIL_INSTALL_DIR}")
else()
    message(WARNING "Abseil installation not found at ${ABSEIL_INSTALL_DIR}")
endif()
