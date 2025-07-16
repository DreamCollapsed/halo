# Folly third-party integration
# Reference: https://github.com/facebook/folly/blob/main/README.md

# Folly has multiple dependencies - temporarily remove jemalloc
thirdparty_check_dependencies("gflags;glog;double-conversion;libevent;openssl;zstd;lz4;snappy;boost;fmt;jemalloc")

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
# find_package modes.
set(_opt_flags
    # --- Basic Build Setup ---
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DBUILD_SHARED_LIBS=OFF
    -DCMAKE_INSTALL_PREFIX=${FOLLY_INSTALL_DIR}

    # --- Dependency Discovery Sandbox ---
    # Force find_* commands to look ONLY in our installed directory.
    -DCMAKE_FIND_ROOT_PATH=${THIRDPARTY_INSTALL_DIR}
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
    
    # Add jemalloc include path and define symbol mappings for the compiler.
    # Folly's build system automatically looks for prefixed jemalloc symbols (je_*).
    # We must define these macros to map the unprefixed calls in Folly's code
    # to the prefixed symbols that its own build system expects.
    # Use CMAKE_REQUIRED_INCLUDES for header detection and CMAKE_CXX_FLAGS for symbols
    -DCMAKE_REQUIRED_INCLUDES=${THIRDPARTY_INSTALL_DIR}/jemalloc/include
    -DCMAKE_CXX_FLAGS=-I${THIRDPARTY_INSTALL_DIR}/jemalloc/include\ -Dmallocx=je_mallocx\ -Drallocx=je_rallocx\ -Dxallocx=je_xallocx\ -Dsallocx=je_sallocx\ -Ddallocx=je_dallocx\ -Dsdallocx=je_sdallocx\ -Dnallocx=je_nallocx\ -Dmallctl=je_mallctl\ -Dmallctlnametomib=je_mallctlnametomib\ -Dmallctlbymib=je_mallctlbymib

    # --- Precise Dependency Injection (Modern `Config` mode) ---
    # For packages folly finds with `find_package(... CONFIG)`
    -DBoost_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/boost/lib/cmake/Boost-1.88.0
    -Dfmt_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/fmt/lib/cmake/fmt

    # --- Precise Dependency Injection (Legacy `Module` mode) ---
    # For packages folly finds with `find_package(... MODULE)`, we must provide
    # the old-style hint variables that their respective Find*.cmake scripts expect.
    -DDOUBLE_CONVERSION_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/double-conversion/include
    -DDOUBLE_CONVERSION_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/double-conversion/lib/libdouble-conversion.a
    -DGFLAGS_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/gflags/include
    -DGFLAGS_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/gflags/lib/libgflags.a
    -DGLOG_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/glog/include
    -DGLOG_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/glog/lib/libglog.a
    -DLIBEVENT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/libevent/include
    -DLIBEVENT_LIB:FILEPATH=${THIRDPARTY_INSTALL_DIR}/libevent/lib/libevent.a
    -DOPENSSL_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/openssl/include
    -DOPENSSL_SSL_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libssl.a
    -DOPENSSL_CRYPTO_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/openssl/lib/libcrypto.a
    -DZSTD_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/zstd/include
    -DZSTD_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/zstd/lib/libzstd.a
    -DLZ4_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/lz4/include
    -DLZ4_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/lz4/lib/liblz4.a
    -DSNAPPY_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/snappy/include
    -DSNAPPY_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/snappy/lib/libsnappy.a
    -DFASTFLOAT_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/fast-float/include

    # --- Boost Variant Control ---
    -DBOOST_LINK_STATIC:STRING=ON
    -DBoost_USE_STATIC_RUNTIME:BOOL=ON

    # --- Folly Specifics ---
    -DFOLLY_HAVE_UNALIGNED_ACCESS:BOOL=ON
    -DFOLLY_USE_SYMBOLIZER:BOOL=ON
    -DFOLLY_HAVE_LIBGFLAGS:BOOL=ON
    -DFOLLY_HAVE_LIBGLOG:BOOL=ON
    -DFOLLY_HAVE_BACKTRACE:BOOL=ON
    # Enable jemalloc support since main project uses drop-in jemalloc
    -DFOLLY_USE_JEMALLOC:BOOL=ON
    # jemalloc include and library paths
    -DJEMALLOC_INCLUDE_DIR:PATH=${THIRDPARTY_INSTALL_DIR}/jemalloc/include
    -DJEMALLOC_LIBRARY:FILEPATH=${THIRDPARTY_INSTALL_DIR}/jemalloc/lib/libjemalloc.a
    # Ensure jemalloc is linked into all executables
    -DCMAKE_EXE_LINKER_FLAGS=-L${THIRDPARTY_INSTALL_DIR}/jemalloc/lib\ -ljemalloc
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