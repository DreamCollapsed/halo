# libevent third-party integration
# Reference: https://github.com/libevent/libevent

# libevent has special download file naming (-stable suffix)
thirdparty_check_dependencies("libevent")

# Set up directories with special URL handling
thirdparty_setup_directories("libevent")

# Override download file name for libevent's special naming
set(LIBEVENT_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/libevent-${LIBEVENT_VERSION}-stable.tar.gz")
set(LIBEVENT_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/libevent")
set(LIBEVENT_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/libevent")
set(LIBEVENT_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/libevent")
get_filename_component(LIBEVENT_INSTALL_DIR "${LIBEVENT_INSTALL_DIR}" ABSOLUTE)

# Download and extract libevent
thirdparty_download_and_check("${LIBEVENT_URL}" "${LIBEVENT_DOWNLOAD_FILE}" "${LIBEVENT_SHA256}")
thirdparty_extract_and_rename("${LIBEVENT_DOWNLOAD_FILE}" "${LIBEVENT_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/libevent-*")

# Configure libevent with dependencies and optimization flags
thirdparty_get_optimization_flags(_opt_flags COMPONENT libevent)

list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${LIBEVENT_INSTALL_DIR}
    -DEVENT__DISABLE_TESTS=ON
    -DEVENT__DISABLE_REGRESS=ON
    -DEVENT__DISABLE_SAMPLES=ON
    -DEVENT__DISABLE_BENCHMARK=ON
    -DEVENT__LIBRARY_TYPE=STATIC
    -DEVENT__DISABLE_OPENSSL=OFF
    -DEVENT__DISABLE_THREAD_SUPPORT=OFF
    -DEVENT__DISABLE_DEBUG_MODE=ON
    -DEVENT__DISABLE_MM_REPLACEMENT=OFF
    -DEVENT__FORCE_KQUEUE_CHECK=OFF
)

thirdparty_cmake_configure("${LIBEVENT_SOURCE_DIR}" "${LIBEVENT_BUILD_DIR}"
    VALIDATION_FILES
        "${LIBEVENT_BUILD_DIR}/CMakeCache.txt"
        "${LIBEVENT_BUILD_DIR}/Makefile"
    CMAKE_ARGS
        ${_opt_flags}
)

# Build and install libevent
thirdparty_cmake_install("${LIBEVENT_BUILD_DIR}" "${LIBEVENT_INSTALL_DIR}"
    VALIDATION_FILES
        "${LIBEVENT_INSTALL_DIR}/lib/cmake/libevent/LibeventConfig.cmake"
        "${LIBEVENT_INSTALL_DIR}/lib/libevent.a"
        "${LIBEVENT_INSTALL_DIR}/lib/libevent_core.a"
        "${LIBEVENT_INSTALL_DIR}/lib/libevent_extra.a"
        "${LIBEVENT_INSTALL_DIR}/lib/libevent_openssl.a"
        "${LIBEVENT_INSTALL_DIR}/lib/libevent_pthreads.a"
        "${LIBEVENT_INSTALL_DIR}/include/event2/event.h"
        "${LIBEVENT_INSTALL_DIR}/include/event2/bufferevent.h"
        "${LIBEVENT_INSTALL_DIR}/include/event2/http.h"
)

# Export libevent to global scope
if(EXISTS "${LIBEVENT_INSTALL_DIR}/lib/cmake/libevent/LibeventConfig.cmake")
    list(APPEND CMAKE_PREFIX_PATH "${LIBEVENT_INSTALL_DIR}")
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)
    set(Libevent_DIR "${LIBEVENT_INSTALL_DIR}/lib/cmake/libevent" CACHE PATH "Path to installed libevent cmake config" FORCE)
    message(STATUS "libevent found and exported globally: ${LIBEVENT_INSTALL_DIR}")
else()
    message(WARNING "libevent installation not found at ${LIBEVENT_INSTALL_DIR}")
endif()
