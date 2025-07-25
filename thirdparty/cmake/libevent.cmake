# libevent third-party integration
# Reference: https://github.com/libevent/libevent

# Use the standardized build function for libevent
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

# Additional libevent-specific setup
set(LIBEVENT_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/libevent")
get_filename_component(LIBEVENT_INSTALL_DIR "${LIBEVENT_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${LIBEVENT_INSTALL_DIR}/lib/cmake/libevent/LibeventConfig.cmake")
    set(Libevent_DIR "${LIBEVENT_INSTALL_DIR}/lib/cmake/libevent" CACHE PATH "Path to installed libevent cmake config" FORCE)
    
    # Import libevent package immediately with all components
    find_package(Libevent REQUIRED CONFIG COMPONENTS core extra openssl pthreads QUIET)
    
    message(STATUS "libevent found and exported globally: ${LIBEVENT_INSTALL_DIR}")
else()
    message(WARNING "libevent installation not found at ${LIBEVENT_INSTALL_DIR}")
endif()
