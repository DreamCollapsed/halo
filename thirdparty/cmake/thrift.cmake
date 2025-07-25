# Apache Thrift integration for the Halo project
# This file handles downloading, building, and installing Apache Thrift

include(${CMAKE_CURRENT_LIST_DIR}/../ThirdpartyUtils.cmake)

# Ensure Bison is available since thrift depends on it for code generation
if(NOT TARGET bison::bison)
    # Load bison if not already loaded
    include(${CMAKE_CURRENT_LIST_DIR}/bison.cmake)
endif()

# Ensure Flex is available since thrift depends on it for code generation
if(NOT TARGET flex::flex)
    # Load flex if not already loaded
    include(${CMAKE_CURRENT_LIST_DIR}/flex.cmake)
endif()

# Ensure Boost is available since thrift depends on it
if(NOT TARGET Boost::headers)
    # Load Boost if not already loaded
    include(${CMAKE_CURRENT_LIST_DIR}/boost.cmake)
endif()

# Ensure ZLIB is available since thrift can use it for compression
if(NOT TARGET zlib::zlib)
    # Load zlib if not already loaded
    include(${CMAKE_CURRENT_LIST_DIR}/zlib.cmake)
endif()

# Use the standardized build function for thrift
thirdparty_build_cmake_library("thrift"
    EXTRACT_PATTERN "${THIRDPARTY_SRC_DIR}/thrift-*"
    CMAKE_ARGS
        -DBUILD_TESTING=OFF
        -DBUILD_TUTORIALS=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_SHARED_LIBS=OFF
        -DWITH_QT5=OFF
        -DWITH_QT6=OFF
        -DWITH_JAVA=OFF
        -DWITH_PYTHON=OFF
        -DWITH_JAVASCRIPT=OFF
        -DWITH_NODEJS=OFF
        -DWITH_CPP=ON
        -DWITH_C_GLIB=OFF
        -DWITH_LIBEVENT=OFF
        -DWITH_OPENSSL=OFF
        -DWITH_ZLIB=ON
        -DWITH_STATIC_LIB=ON
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        -DBoost_USE_STATIC_LIBS=ON
        -DBoost_ROOT=${THIRDPARTY_INSTALL_DIR}/boost
        -DZLIB_ROOT=${THIRDPARTY_INSTALL_DIR}/zlib
        -DZLIB_LIBRARY=${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
        -DZLIB_INCLUDE_DIR=${THIRDPARTY_INSTALL_DIR}/zlib/include
        -DBISON_EXECUTABLE=${THIRDPARTY_INSTALL_DIR}/bison/bin/bison
        -DFLEX_EXECUTABLE=${THIRDPARTY_INSTALL_DIR}/flex/bin/flex
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/thrift/lib/libthrift.a"
        "${THIRDPARTY_INSTALL_DIR}/thrift/lib/libthriftz.a"
        "${THIRDPARTY_INSTALL_DIR}/thrift/include/thrift/Thrift.h"
        "${THIRDPARTY_INSTALL_DIR}/thrift/bin/thrift"
)

# Export thrift for use by other components using official CMake targets
set(THRIFT_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/thrift")
get_filename_component(THRIFT_INSTALL_DIR "${THRIFT_INSTALL_DIR}" ABSOLUTE)

if(EXISTS "${THRIFT_INSTALL_DIR}/lib/cmake/thrift/ThriftConfig.cmake")
    # Set the cache path for thrift cmake config (similar to gtest pattern)
    set(Thrift_DIR "${THRIFT_INSTALL_DIR}/lib/cmake/thrift" CACHE PATH "Path to installed Thrift cmake config" FORCE)
    
    # Temporarily disable CMAKE_DISABLE_FIND_PACKAGE_ZLIB to allow thrift's find_dependency(ZLIB)
    set(_original_disable_zlib_state ${CMAKE_DISABLE_FIND_PACKAGE_ZLIB})
    unset(CMAKE_DISABLE_FIND_PACKAGE_ZLIB CACHE)
    unset(CMAKE_DISABLE_FIND_PACKAGE_ZLIB)
    
    # Import Thrift package with QUIET flag
    find_package(Thrift REQUIRED CONFIG QUIET)
    
    # Restore the original ZLIB disable state
    set(CMAKE_DISABLE_FIND_PACKAGE_ZLIB ${_original_disable_zlib_state} CACHE BOOL "Disable ZLIB finding" FORCE)
    
    # The official ThriftConfig.cmake sets THRIFT_LIBRARIES to either thrift::thrift or thriftz::thriftz
    # based on the configuration (ZLIB support enabled = thriftz::thriftz)
    if(NOT TARGET ${THRIFT_LIBRARIES})
        message(FATAL_ERROR "Expected thrift target ${THRIFT_LIBRARIES} not found")
    endif()

    message(STATUS "Using official thrift targets: ${THRIFT_LIBRARIES}")
    message(STATUS "Thrift version: ${THRIFT_VERSION}")
    message(STATUS "Thrift compiler: ${THRIFT_COMPILER}")
    message(STATUS "Thrift install dir: ${THRIFT_INSTALL_DIR}")
else()
    message(WARNING "Thrift installation not found at ${THRIFT_INSTALL_DIR}")
endif()
