# bison third-party integration
# Reference: http://ftp.gnu.org/gnu/bison/

# Use the standardized build function for bison
# Note: Bison uses autotools (configure/make) build system
thirdparty_build_autotools_library("bison"
    CONFIGURE_ARGS
        --enable-static
        --disable-shared
        --disable-nls
        --disable-dependency-tracking
        --without-libintl-prefix
        --without-libiconv-prefix
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/bison/bin/bison"
)

# Additional bison-specific setup
set(BISON_INSTALL_DIR "${THIRDPARTY_INSTALL_DIR}/bison")
get_filename_component(BISON_INSTALL_DIR "${BISON_INSTALL_DIR}" ABSOLUTE)

# Set BISON_EXECUTABLE for other projects that might need it
set(BISON_EXECUTABLE "${BISON_INSTALL_DIR}/bin/bison" CACHE FILEPATH "Path to bison executable" FORCE)

if(EXISTS "${BISON_EXECUTABLE}")
    # Create an imported executable target
    if(NOT TARGET bison::bison)
        add_executable(bison::bison IMPORTED GLOBAL)
        set_target_properties(bison::bison PROPERTIES
            IMPORTED_LOCATION "${BISON_EXECUTABLE}"
        )
    endif()
    
    # Add to PATH for build tools that might need it
    get_filename_component(BISON_BIN_DIR "${BISON_EXECUTABLE}" DIRECTORY)
    list(APPEND CMAKE_PROGRAM_PATH "${BISON_BIN_DIR}")
    set(CMAKE_PROGRAM_PATH "${CMAKE_PROGRAM_PATH}" PARENT_SCOPE)
    
    # Export the bison path for tests that need it
    set(BISON_EXECUTABLE_PATH "${BISON_EXECUTABLE}" CACHE INTERNAL "Path to project bison executable")
    
    message(STATUS "bison found and exported globally: ${BISON_INSTALL_DIR}")
else()
    message(WARNING "bison installation not found at ${BISON_INSTALL_DIR}")
endif()
