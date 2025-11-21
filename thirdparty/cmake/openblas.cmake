# OpenBLAS third-party integration
# Reference: https://github.com/OpenMathLib/OpenBLAS

# Only build OpenBLAS on Linux, skip on macOS
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    thirdparty_setup_directories("openblas")
    thirdparty_build_cmake_library(openblas
        CMAKE_ARGS
            -DBUILD_SHARED_LIBS=OFF
            -DBUILD_TESTING=OFF
            -DUSE_THREAD=ON
            -DBUILD_WITHOUT_LAPACK=OFF
            -DBUILD_RELAPACK=OFF
            -DNOFORTRAN=1
            -DC_LAPACK=1
        VALIDATION_FILES
            "${OPENBLAS_INSTALL_DIR}/lib/libopenblas.a"
            "${OPENBLAS_INSTALL_DIR}/include/openblas/openblas_config.h"
    )

    find_package(OpenBLAS CONFIG REQUIRED)

    thirdparty_map_imported_config(OpenBLAS::OpenBLAS)
endif()