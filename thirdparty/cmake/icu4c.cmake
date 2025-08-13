thirdparty_setup_directories("icu4c")

# Prepare configure args equivalent to the previous script
set(_icu_configure_args
    --enable-static
    --disable-shared
    --disable-samples
    --disable-tests
    --enable-tools
    --with-data-packaging=static
    --enable-threads
    --disable-extras
    --disable-icuio
    --disable-layout
    --build=aarch64-apple-darwin
)

thirdparty_build_autotools_library("icu4c"
    CONFIGURE_SCRIPT_NAME "source/configure"
    CONFIGURE_ARGS ${_icu_configure_args} CFLAGS=-fPIC\ -O2 CXXFLAGS=-fPIC\ -O2
    VALIDATION_FILES
        "${ICU4C_INSTALL_DIR}/lib/libicuuc.a"
        "${ICU4C_INSTALL_DIR}/lib/libicudata.a"
        "${ICU4C_INSTALL_DIR}/lib/libicui18n.a"
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
    if(NOT TARGET ICU::ICU)
        add_library(ICU::ICU INTERFACE IMPORTED)
        set_target_properties(ICU::ICU PROPERTIES
            INTERFACE_LINK_LIBRARIES "ICU::i18n;ICU::uc;ICU::data"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU4C_INSTALL_DIR}/include"
        )
    endif() 
    message(STATUS "ICU4C found and exported globally: ${ICU4C_INSTALL_DIR}")
else()
    message(FATAL_ERROR "ICU4C configuration failed - missing library files")
endif()
