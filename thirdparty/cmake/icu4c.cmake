thirdparty_setup_directories("icu4c")

# Determine appropriate build target based on platform
# Use CMAKE_SYSTEM_NAME for reliable platform detection
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(_icu_platform "APPLE")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(_icu_build_target "aarch64-apple-darwin")
    else()
        set(_icu_build_target "x86_64-apple-darwin")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_icu_platform "LINUX")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
        set(_icu_build_target "aarch64-linux-gnu")
    else()
        set(_icu_build_target "x86_64-linux-gnu")
    endif()
else()
    # Fallback for other systems
    set(_icu_build_target "")
    set(_icu_platform "OTHER")
endif()

# Debug output to verify platform detection
message(DEBUG "ICU4C: CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}, Detected platform=${_icu_platform}, Build target=${_icu_build_target}")

# Prepare configure args with platform-specific settings
# Common arguments for all platforms
set(_icu_common_args
    --enable-static
    --disable-shared
    --disable-samples
    --disable-tests
    --enable-tools
    --disable-extras
    --disable-layout
)

# Use static data packaging for all platforms
set(_icu_configure_args ${_icu_common_args} --with-data-packaging=static)

# Force build and host targets to prevent autotools from misdetecting platform
if(_icu_build_target)
    list(APPEND _icu_configure_args "--build=${_icu_build_target}")
    list(APPEND _icu_configure_args "--host=${_icu_build_target}")
endif()

# Platform-specific compiler flags
if(_icu_platform STREQUAL "APPLE")
    list(APPEND _icu_configure_args "CFLAGS=-fPIC -O2")
    list(APPEND _icu_configure_args "CXXFLAGS=-fPIC -O2")
elseif(_icu_platform STREQUAL "LINUX")
    # Linux: Preserve environment-provided CFLAGS/CXXFLAGS (they carry mold / rpaths).
    # Only add a non-intrusive ASFLAGS if integrated assembler causes issues; start conservative.
    # If future failures occur in .S files, we can append ASFLAGS=-fno-integrated-as here.
    list(APPEND _icu_configure_args "CPPFLAGS=-fPIC -O2")
endif()

# Environment variables that might confuse ICU4C's platform detection
if(_icu_platform STREQUAL "LINUX")
    # Clear macOS-specific environment variables that might be present
    set(ENV{DYLD_LIBRARY_PATH} "")
    set(ENV{DYLD_FALLBACK_LIBRARY_PATH} "")
    set(ENV{DYLD_FRAMEWORK_PATH} "")
endif()

thirdparty_build_autotools_library("icu4c"
    CONFIGURE_SCRIPT_NAME "source/configure"
    CONFIGURE_ARGS ${_icu_configure_args}
    VALIDATION_FILES
        "${ICU4C_INSTALL_DIR}/lib/libicuuc.a"
        "${ICU4C_INSTALL_DIR}/lib/libicudata.a"
        "${ICU4C_INSTALL_DIR}/lib/libicui18n.a"
        "${ICU4C_INSTALL_DIR}/lib/libicuio.a"
        "${ICU4C_INSTALL_DIR}/lib/libicutu.a"
        "${ICU4C_INSTALL_DIR}/include/unicode/uversion.h"
        "${ICU4C_INSTALL_DIR}/bin/icu-config"
)

if(EXISTS "${ICU4C_INSTALL_DIR}/lib/libicuuc.a")
    if(NOT TARGET ICU::uc)
        add_library(ICU::uc STATIC IMPORTED)
        set_target_properties(ICU::uc PROPERTIES
            IMPORTED_LOCATION "${ICU4C_INSTALL_DIR}/lib/libicuuc.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
        )
    endif()
    if(NOT TARGET ICU::i18n)
        add_library(ICU::i18n STATIC IMPORTED)
        set_target_properties(ICU::i18n PROPERTIES
            IMPORTED_LOCATION "${ICU4C_INSTALL_DIR}/lib/libicui18n.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
            INTERFACE_LINK_LIBRARIES ICU::uc
        )
    endif()
    if(NOT TARGET ICU::data)
        add_library(ICU::data STATIC IMPORTED)
        set_target_properties(ICU::data PROPERTIES
            IMPORTED_LOCATION "${ICU4C_INSTALL_DIR}/lib/libicudata.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
        )
    endif()
    if(EXISTS "${ICU4C_INSTALL_DIR}/lib/libicuio.a" AND NOT TARGET ICU::io)
        add_library(ICU::io STATIC IMPORTED)
        set_target_properties(ICU::io PROPERTIES
            IMPORTED_LOCATION "${ICU4C_INSTALL_DIR}/lib/libicuio.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
            INTERFACE_LINK_LIBRARIES ICU::uc
        )
    endif()
    if(EXISTS "${ICU4C_INSTALL_DIR}/lib/libicutu.a" AND NOT TARGET ICU::tu)
        add_library(ICU::tu STATIC IMPORTED)
        set_target_properties(ICU::tu PROPERTIES
            IMPORTED_LOCATION "${ICU4C_INSTALL_DIR}/lib/libicutu.a"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
            INTERFACE_LINK_LIBRARIES "ICU::i18n;ICU::uc"
        )
    endif()
    if(NOT TARGET ICU::ICU)
        add_library(ICU::ICU INTERFACE IMPORTED)
        set(_icu_link_targets ICU::i18n ICU::uc ICU::data)
        if(TARGET ICU::io)
            list(APPEND _icu_link_targets ICU::io)
        endif()
        if(TARGET ICU::tu)
            list(APPEND _icu_link_targets ICU::tu)
        endif()
        list(JOIN _icu_link_targets ";" _icu_link_targets_joined)
        set_target_properties(ICU::ICU PROPERTIES
            INTERFACE_LINK_LIBRARIES "${_icu_link_targets_joined}"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
        )
    endif() 
else()
    message(FATAL_ERROR "ICU4C configuration failed - missing library files")
endif()
