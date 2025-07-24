# Folly third-party integration
# Reference: https://github.com/facebook/folly/blob/main/README.md

# Folly has multiple dependencies - include zlib and xz for compression support
thirdparty_check_dependencies("gflags;glog;double-conversion;libevent;openssl;zstd;lz4;snappy;boost;fmt;jemalloc;zlib;xz")

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

# Create FindGlog.cmake directly in folly's CMake directory for MODULE-mode compatibility
set(_findglog_content "# FindGlog.cmake - Auto-generated bridge module
# This bridges CONFIG-mode glog to MODULE-mode find_package calls

# Find glog using CONFIG mode
find_package(glog QUIET CONFIG HINTS \"${THIRDPARTY_INSTALL_DIR}/glog/lib/cmake/glog\")

if(glog_FOUND)
    # Extract information from the CONFIG-mode target
    get_target_property(GLOG_INCLUDE_DIR glog::glog INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(GLOG_LIBRARY glog::glog IMPORTED_LOCATION)
    
    # Try different configurations if IMPORTED_LOCATION is not available
    if(NOT GLOG_LIBRARY)
        get_target_property(GLOG_LIBRARY glog::glog IMPORTED_LOCATION_RELEASE)
    endif()
    if(NOT GLOG_LIBRARY)
        get_target_property(GLOG_LIBRARY glog::glog IMPORTED_LOCATION_DEBUG)
    endif()
    if(NOT GLOG_LIBRARY)
        set(GLOG_LIBRARY \"${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a\")
    endif()
    
    # Set MODULE-mode variables
    set(GLOG_LIBRARIES \\\${GLOG_LIBRARY})
    set(GLOG_FOUND TRUE)
    
    # Some projects expect these legacy variables
    set(LIBGLOG_FOUND TRUE)
    
    mark_as_advanced(GLOG_INCLUDE_DIR GLOG_LIBRARY)
    
    if(NOT TARGET Glog::glog)
        add_library(Glog::glog ALIAS glog::glog)
    endif()
else()
    # Fallback: Manual search if CONFIG mode fails
    find_path(GLOG_INCLUDE_DIR
        NAMES glog/logging.h
        HINTS \"${THIRDPARTY_INSTALL_DIR}/glog/include\"
    )
    
    find_library(GLOG_LIBRARY
        NAMES glog libglog
        HINTS \"${THIRDPARTY_INSTALL_DIR}/glog/lib\"
    )
    
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(Glog
        REQUIRED_VARS GLOG_LIBRARY GLOG_INCLUDE_DIR
    )
    
    if(GLOG_FOUND)
        set(GLOG_LIBRARIES \\\${GLOG_LIBRARY})
        set(LIBGLOG_FOUND TRUE)
        
        if(NOT TARGET Glog::glog)
            add_library(Glog::glog UNKNOWN IMPORTED)
            set_target_properties(Glog::glog PROPERTIES
                IMPORTED_LOCATION \\\"\\\${GLOG_LIBRARY}\\\"
                INTERFACE_INCLUDE_DIRECTORIES \\\"\\\${GLOG_INCLUDE_DIR}\\\"
            )
        endif()
    endif()
endif()
")

file(WRITE "${FOLLY_SOURCE_DIR}/CMake/FindGlog.cmake" "${_findglog_content}")
message(STATUS "Created FindGlog.cmake bridge module at ${FOLLY_SOURCE_DIR}/CMake/FindGlog.cmake")
message(STATUS "Appended jemalloc compile definitions to folly-deps.cmake")

# Configure folly with CMake and optimization flags.
# This is a hybrid approach to satisfy folly's mixed use of modern and legacy
thirdparty_get_optimization_flags(_opt_flags COMPONENT folly)
list(APPEND _opt_flags
    # Override install prefix
    -DCMAKE_INSTALL_PREFIX=${FOLLY_INSTALL_DIR}

    # Force CMake to use our third-party libraries first
    -DCMAKE_PREFIX_PATH=${THIRDPARTY_INSTALL_DIR}/zlib\;${THIRDPARTY_INSTALL_DIR}/xz\;${THIRDPARTY_INSTALL_DIR}/boost\;${THIRDPARTY_INSTALL_DIR}/gflags\;${THIRDPARTY_INSTALL_DIR}/glog\;${THIRDPARTY_INSTALL_DIR}/double-conversion\;${THIRDPARTY_INSTALL_DIR}/libevent\;${THIRDPARTY_INSTALL_DIR}/openssl\;${THIRDPARTY_INSTALL_DIR}/zstd\;${THIRDPARTY_INSTALL_DIR}/lz4\;${THIRDPARTY_INSTALL_DIR}/snappy\;${THIRDPARTY_INSTALL_DIR}/fmt\;${THIRDPARTY_INSTALL_DIR}/jemalloc
    
    # Disable system library search paths
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
    -DCMAKE_FIND_ROOT_PATH=${THIRDPARTY_INSTALL_DIR}

    # BOOST
    -DBOOST_LINK_STATIC:STRING=ON
    -DBoost_USE_STATIC_RUNTIME:BOOL=ON
    -DBoost_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/boost/lib/cmake/Boost-1.88.0

    # FMT
    -Dfmt_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/fmt/lib/cmake/fmt

    # DOUBLE_CONVERSION
    -DDOUBLE_CONVERSION_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/double-conversion/include
    -DDOUBLE_CONVERSION_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/libdouble-conversion.a

    # GFLAGS
    -DGFLAGS_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/gflags/include
    -DGFLAGS_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/gflags/lib/libgflags.a

    # GLOG
    -DGLOG_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/glog/include
    -DGLOG_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a

    # LIBEVENT
    -DLIBEVENT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/libevent/include
    -DLIBEVENT_LIB:FILEPATH=${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent.a

    # OPENSSL
    -DOPENSSL_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a

    # ZSTD
    -DZSTD_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/zstd/include
    -DZSTD_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a

    # LZ4
    -DLZ4_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/lz4/include
    -DLZ4_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/lz4/lib/liblz4.a

    # SNAPPY
    -DSNAPPY_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/snappy/include
    -DSNAPPY_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/snappy/lib/libsnappy.a

    # ZLIB - Force use of third-party library, not system
    -DZLIB_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/zlib/include
    -DZLIB_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/zlib/lib/libz.a
    -DZLIB_ROOT:PATH=${THIRDPARTY_INSTALL_DIR}/zlib

    # LZMA/XZ - Force use of third-party library, not system
    -DLIBLZMA_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/xz/include
    -DLIBLZMA_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a
    -DLibLZMA_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/xz/include
    -DLibLZMA_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a
    -DLZMA_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/xz/include
    -DLZMA_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/xz/lib/liblzma.a

    # FASTFLOAT
    -DFASTFLOAT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/fast-float/include

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

# Export Folly configuration for parent scope
set(FOLLY_INSTALL_DIR "${FOLLY_INSTALL_DIR}" PARENT_SCOPE)
set(Folly_DIR "${FOLLY_INSTALL_DIR}/lib/cmake/folly" CACHE PATH "Path to installed Folly cmake config" FORCE)

# Import Folly package immediately
if(EXISTS "${FOLLY_INSTALL_DIR}/lib/cmake/folly/folly-config.cmake")
    find_package(Folly REQUIRED CONFIG QUIET)
    message(STATUS "Folly found and imported: ${FOLLY_INSTALL_DIR}")
else()
    message(WARNING "Folly cmake config not found at ${FOLLY_INSTALL_DIR}")
endif()
