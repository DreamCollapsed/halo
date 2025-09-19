# xtl third-party integration (header-only)
# Reference: https://github.com/xtensor-stack/xtl

thirdparty_setup_directories("xtl")

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${XTL_INSTALL_DIR}
)

thirdparty_build_cmake_library("xtl"
    CMAKE_ARGS ${_opt_flags}
    VALIDATION_FILES
        "${XTL_INSTALL_DIR}/include/xtl/xoptional.hpp"
        "${XTL_INSTALL_DIR}/share/cmake/xtl/xtlConfig.cmake"
)

find_package(xtl CONFIG REQUIRED)
