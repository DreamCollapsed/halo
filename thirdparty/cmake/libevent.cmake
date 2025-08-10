# libevent third-party integration
# Reference: https://github.com/libevent/libevent

thirdparty_build_cmake_library("libevent"
    DEPENDENCIES "openssl"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/libevent-*"
    CMAKE_ARGS
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
        -DOPENSSL_ROOT_DIR=${THIRDPARTY_INSTALL_DIR}/openssl
        -DOPENSSL_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/openssl/include
        -DOPENSSL_SSL_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
        -DOPENSSL_CRYPTO_LIBRARY=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/libevent/lib/cmake/libevent/LibeventConfig.cmake"
        "${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent.a"
        "${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent_core.a"
        "${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent_extra.a"
        "${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent_openssl.a"
        "${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent_pthreads.a"
        "${THIRDPARTY_INSTALL_DIR}/libevent/include/event2/event.h"
        "${THIRDPARTY_INSTALL_DIR}/libevent/include/event2/bufferevent.h"
        "${THIRDPARTY_INSTALL_DIR}/libevent/include/event2/http.h"
)

set(LIBEVENT_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/libevent")
get_filename_component(LIBEVENT_INSTALL_DIR "${LIBEVENT_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${LIBEVENT_INSTALL_DIR}/lib/cmake/libevent/LibeventConfig.cmake")
    find_package(Libevent CONFIG REQUIRED COMPONENTS core extra openssl pthreads QUIET)
    
    message(STATUS "libevent found and exported globally: ${LIBEVENT_INSTALL_DIR}")
else()
    message(FATAL_ERROR "libevent installation not found at ${LIBEVENT_INSTALL_DIR}")
endif()
