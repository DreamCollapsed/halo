# flex third-party integration
# Reference: https://github.com/westes/flex

thirdparty_build_autotools_library("flex"
    CONFIGURE_ARGS
        --enable-static
        --disable-shared
        --disable-nls
        --disable-dependency-tracking
        --without-libintl-prefix
        --without-libiconv-prefix
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/flex/bin/flex"
)

set(FLEX_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/flex")
get_filename_component(FLEX_INSTALL_DIR "${FLEX_INSTALL_DIR}" ABSOLUTE)

set(FLEX_EXECUTABLE_PATH "${FLEX_INSTALL_DIR}/bin/flex" CACHE INTERNAL "Path to project flex executable")
if(EXISTS "${FLEX_EXECUTABLE_PATH}")
    get_filename_component(FLEX_BIN_DIR "${FLEX_EXECUTABLE_PATH}" DIRECTORY)
    list(APPEND CMAKE_PROGRAM_PATH "${FLEX_BIN_DIR}")
    set(CMAKE_PROGRAM_PATH "${CMAKE_PROGRAM_PATH}" PARENT_SCOPE)
    
    # Register executable path for main project and tests
    thirdparty_register_executable_path("flex" "${FLEX_EXECUTABLE_PATH}")
else()
    message(FATAL_ERROR "flex installation not found at ${FLEX_INSTALL_DIR}")
endif()
