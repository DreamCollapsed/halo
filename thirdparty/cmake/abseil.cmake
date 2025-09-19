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

find_package(absl CONFIG REQUIRED)
