# flex third-party integration
# Reference: https://github.com/westes/flex

# Use the standardized build function for flex
# Note: Flex uses autotools (configure/make) build system
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

# Additional flex-specific setup
set(FLEX_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/flex")
get_filename_component(FLEX_INSTALL_DIR "${FLEX_INSTALL_DIR}" ABSOLUTE)

# Set FLEX_EXECUTABLE for other projects that might need it
set(FLEX_EXECUTABLE "${FLEX_INSTALL_DIR}/bin/flex" CACHE FILEPATH "Path to flex executable" FORCE)

if(EXISTS "${FLEX_EXECUTABLE}")
    # Create an imported executable target
    if(NOT TARGET flex::flex)
        add_executable(flex::flex IMPORTED GLOBAL)
        set_target_properties(flex::flex PROPERTIES
            IMPORTED_LOCATION "${FLEX_EXECUTABLE}"
        )
    endif()
    
    # Add to PATH for build tools that might need it
    get_filename_component(FLEX_BIN_DIR "${FLEX_EXECUTABLE}" DIRECTORY)
    list(APPEND CMAKE_PROGRAM_PATH "${FLEX_BIN_DIR}")
    set(CMAKE_PROGRAM_PATH "${CMAKE_PROGRAM_PATH}" PARENT_SCOPE)
    
    # Export the flex path for tests that need it
    set(FLEX_EXECUTABLE_PATH "${FLEX_EXECUTABLE}" CACHE INTERNAL "Path to project flex executable")
    
    message(STATUS "flex found and exported globally: ${FLEX_INSTALL_DIR}")
else()
    message(WARNING "flex installation not found at ${FLEX_INSTALL_DIR}")
endif()
