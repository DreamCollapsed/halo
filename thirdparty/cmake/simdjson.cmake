# simdjson third-party integration
# Reference: https://github.com/simdjson/simdjson
# We build (or use) the static library libsimdjson.a and install headers under include/simdjson.
# simdjson provides a CMake build; it's largely header-only but still builds a small library.

# Build simdjson with tests/examples disabled.
thirdparty_build_cmake_library("simdjson"
    CMAKE_ARGS
        -DSIMDJSON_DEVELOPMENT_CHECKS=OFF
        -DSIMDJSON_ENABLE_THREADS=ON
        -DSIMDJSON_ENABLE_LIB_VERSIONING=OFF
        -DSIMDJSON_ENABLE_SANITIZERS=OFF
        -DSIMDJSON_BUILD_STATIC=ON
        -DSIMDJSON_ENABLE_COMPUTE_CHECKS=OFF
        -DSIMDJSON_BUILD_EXAMPLES=OFF
        -DSIMDJSON_JUST_LIBRARY=ON
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/simdjson/include/simdjson.h"
        "${THIRDPARTY_INSTALL_DIR}/simdjson/lib/libsimdjson.a"
)

find_package(simdjson CONFIG REQUIRED)
message(STATUS "simdjson found and exported globally: ${THIRDPARTY_INSTALL_DIR}/simdjson")
