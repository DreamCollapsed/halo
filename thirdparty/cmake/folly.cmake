# Folly third-party integration
# Reference: https://github.com/facebook/folly/blob/main/README.md

# Folly has multiple dependencies - include zlib, xz, and bzip2 for compression support
thirdparty_check_dependencies("gflags;glog;double-conversion;libevent;openssl;zstd;lz4;snappy;boost;fmt;jemalloc;zlib;xz;bzip2")

# Set up directories
set(FOLLY_NAME "folly")
set(FOLLY_DOWNLOAD_FILE "${THIRDPARTY_DOWNLOAD_DIR}/folly-${FOLLY_VERSION}.tar.gz")
set(FOLLY_SOURCE_DIR "${THIRDPARTY_SRC_DIR}/${FOLLY_NAME}")
set(FOLLY_BUILD_DIR "${THIRDPARTY_BUILD_DIR}/${FOLLY_NAME}")
set(FOLLY_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/${FOLLY_NAME}")

get_filename_component(FOLLY_INSTALL_DIR "${FOLLY_INSTALL_DIR}" ABSOLUTE)

# Download and extract folly
thirdparty_download_and_check("${FOLLY_URL}" "${FOLLY_DOWNLOAD_FILE}" "${FOLLY_SHA256}")
thirdparty_extract_and_rename("${FOLLY_DOWNLOAD_FILE}" "${FOLLY_SOURCE_DIR}" "${THIRDPARTY_SRC_DIR}/folly-*" )
# Inject jemalloc symbol mappings into folly-deps.cmake so downstream targets compile correctly
file(APPEND "${FOLLY_SOURCE_DIR}/CMake/folly-deps.cmake" "
  
  # Inject jemalloc symbol macros for consumers
  target_compile_definitions(folly_deps INTERFACE \
    mallocx=je_mallocx \
    rallocx=je_rallocx \
    xallocx=je_xallocx \
    sallocx=je_sallocx \
    dallocx=je_dallocx \
    sdallocx=je_sdallocx \
    nallocx=je_nallocx \
    mallctl=je_mallctl \
    mallctlnametomib=je_mallctlnametomib \
    mallctlbymib=je_mallctlbymib
  )
")

message(STATUS "Appended jemalloc compile definitions to folly-deps.cmake")

# Modern approach: Modify folly-deps.cmake to use CONFIG mode for glog and Boost instead of MODULE mode
# This leverages modern CMake config support and eliminates the need for FindGlog.cmake and FindBoost.cmake patches
file(READ "${FOLLY_SOURCE_DIR}/CMake/folly-deps.cmake" _folly_deps_content)

# Fix glog to use CONFIG mode
string(REPLACE 
    "find_package(Glog MODULE)" 
    "find_package(glog CONFIG REQUIRED)" 
    _folly_deps_content "${_folly_deps_content}")
string(REPLACE 
    "set(FOLLY_HAVE_LIBGLOG \${GLOG_FOUND})" 
    "set(FOLLY_HAVE_LIBGLOG \${glog_FOUND})" 
    _folly_deps_content "${_folly_deps_content}")
string(REPLACE 
    "list(APPEND FOLLY_LINK_LIBRARIES \${GLOG_LIBRARY})" 
    "list(APPEND FOLLY_LINK_LIBRARIES glog::glog)" 
    _folly_deps_content "${_folly_deps_content}")
string(REPLACE 
    "list(APPEND FOLLY_INCLUDE_DIRECTORIES \${GLOG_INCLUDE_DIR})" 
    "# glog::glog target provides include directories automatically" 
    _folly_deps_content "${_folly_deps_content}")

# Fix Boost to use CONFIG mode instead of MODULE mode
string(REPLACE 
    "find_package(Boost 1.51.0 MODULE" 
    "find_package(Boost 1.51.0 CONFIG" 
    _folly_deps_content "${_folly_deps_content}")

file(WRITE "${FOLLY_SOURCE_DIR}/CMake/folly-deps.cmake" "${_folly_deps_content}")
message(STATUS "Modified folly-deps.cmake to use glog and Boost CONFIG mode (modern CMake approach)")

thirdparty_get_optimization_flags(_opt_flags COMPONENT folly)
list(APPEND _opt_flags
    -DCMAKE_INSTALL_PREFIX=${FOLLY_INSTALL_DIR}

    # --- Boost Configuration (Using CONFIG mode - modern CMake approach) ---
    -DBOOST_LINK_STATIC:BOOL=ON
    -DBOOST_ROOT:PATH=${THIRDPARTY_INSTALL_DIR}/boost
    -DBOOST_INCLUDEDIR:PATH=${THIRDPARTY_INSTALL_DIR}/boost/include
    -DBOOST_LIBRARYDIR:PATH=${THIRDPARTY_INSTALL_DIR}/boost/lib
    -DBoost_USE_MULTITHREADED:BOOL=ON
    -DBoost_USE_STATIC_RUNTIME:BOOL=ON
    -DBoost_NO_SYSTEM_PATHS:BOOL=ON
    -DBoost_NO_BOOST_CMAKE:BOOL=OFF
    -DBoost_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/boost/lib/cmake/Boost-1.88.0
    
    # ZLIB - Force use of third-party library, not system (no config file)
    -DZLIB_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/zlib/include
    -DZLIB_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
    -DZLIB_ROOT:PATH=${THIRDPARTY_INSTALL_DIR}/zlib

    # BZIP2 - Use standard FindBZip2 variables (no config file)
    -DBZIP2_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/bzip2/include
    -DBZIP2_INCLUDE_DIRS:PATH=${THIRDPARTY_INSTALL_DIR}/bzip2/include
    -DBZIP2_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/bzip2/lib/libbz2.a
    -DBZIP2_LIBRARIES:FILEPATH=${THIRDPARTY_INSTALL_DIR}/bzip2/lib/libbz2.a

    # FASTFLOAT
    -DFASTFLOAT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/fast-float/include

    # DOUBLE_CONVERSION - Use FindDoubleConversion.cmake variables (no config file)
    -DDOUBLE_CONVERSION_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/double-conversion/include
    -DDOUBLE_CONVERSION_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/libdouble-conversion.a

    # LIBEVENT - Use FindLibEvent.cmake variables (Folly's custom module)
    -DLIBEVENT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/libevent/include
    -DLIBEVENT_LIB:FILEPATH=${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent.a

    # Jemalloc
    -DCMAKE_REQUIRED_INCLUDES=${THIRDPARTY_INSTALL_DIR}/jemalloc/include
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -Dmallocx=je_mallocx\ -Drallocx=je_rallocx\ -Dxallocx=je_xallocx\ -Dsallocx=je_sallocx\ -Ddallocx=je_dallocx\ -Dsdallocx=je_sdallocx\ -Dnallocx=je_nallocx\ -Dmallctl=je_mallctl\ -Dmallctlnametomib=je_mallctlnametomib\ -Dmallctlbymib=je_mallctlbymib\ -DFOLLY_HAVE_BACKTRACE=1
    -DFOLLY_USE_JEMALLOC:BOOL=ON
    -DJEMALLOC_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/jemalloc/include
    -DJEMALLOC_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/jemalloc/lib/libjemalloc.a
    -DCMAKE_EXE_LINKER_FLAGS=-L${THIRDPARTY_INSTALL_DIR}/jemalloc/lib\ -ljemalloc

    # --- Folly Specifics ---
    -DFOLLY_HAVE_UNALIGNED_ACCESS:BOOL=ON
    -DFOLLY_USE_SYMBOLIZER:BOOL=ON
    -DFOLLY_HAVE_LIBGFLAGS:BOOL=ON
    -DFOLLY_HAVE_LIBGLOG:BOOL=ON
    -DFOLLY_HAVE_BACKTRACE:BOOL=ON
)

thirdparty_cmake_configure("${FOLLY_SOURCE_DIR}" "${FOLLY_BUILD_DIR}"
    FORCE_CONFIGURE
    VALIDATION_FILES
        "${FOLLY_BUILD_DIR}/CMakeCache.txt"
        "${FOLLY_BUILD_DIR}/Makefile"
    CMAKE_ARGS
        ${_opt_flags}
)

thirdparty_cmake_install("${FOLLY_BUILD_DIR}" "${FOLLY_INSTALL_DIR}"
    VALIDATION_FILES
        "${FOLLY_INSTALL_DIR}/lib/libfolly.a"
        "${FOLLY_INSTALL_DIR}/include/folly/folly-config.h"
)

# Export Folly configuration for parent scope (safely handled)
thirdparty_safe_set_parent_scope(FOLLY_INSTALL_DIR "${FOLLY_INSTALL_DIR}")
set(Folly_DIR "${FOLLY_INSTALL_DIR}/lib/cmake/folly" CACHE PATH "Path to installed Folly cmake config" FORCE)

# Import Folly package immediately
if(EXISTS "${FOLLY_INSTALL_DIR}/lib/cmake/folly/folly-config.cmake")
    find_package(Folly REQUIRED CONFIG QUIET)
    message(STATUS "Folly found and imported: ${FOLLY_INSTALL_DIR}")
else()
    message(WARNING "Folly cmake config not found at ${FOLLY_INSTALL_DIR}")
endif()
