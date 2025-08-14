# xsimd third-party integration (header-only)
# Reference: https://github.com/xtensor-stack/xsimd

thirdparty_setup_directories("xsimd")

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${XSIMD_INSTALL_DIR}
    -DENABLE_XTL_COMPLEX=ON
)

thirdparty_build_cmake_library("xsimd"
    CMAKE_ARGS ${_opt_flags}
    VALIDATION_FILES
        "${XSIMD_INSTALL_DIR}/include/xsimd/config/xsimd_config.hpp"
        "${XSIMD_INSTALL_DIR}/share/cmake/xsimd/xsimdConfig.cmake"
)

find_package(xsimd CONFIG REQUIRED)
message(STATUS "xsimd imported into superproject: ${XSIMD_INSTALL_DIR}")
