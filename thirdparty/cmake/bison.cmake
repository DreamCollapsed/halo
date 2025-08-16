# bison third-party integration
# Reference: http://ftp.gnu.org/gnu/bison/

thirdparty_build_autotools_library("bison"
    CONFIGURE_ARGS
        --disable-nls
        --disable-dependency-tracking
        --without-libintl-prefix
        --without-libiconv-prefix
    VALIDATION_FILES
        "${THIRDPARTY_INSTALL_DIR}/bison/bin/bison"
)
set(BISON_EXECUTABLE_PATH "${BISON_INSTALL_DIR}/bin/bison" CACHE INTERNAL "Path to project bison executable")
if(EXISTS "${BISON_EXECUTABLE_PATH}")
    get_filename_component(BISON_BIN_DIR "${BISON_EXECUTABLE_PATH}" DIRECTORY)
    list(APPEND CMAKE_PROGRAM_PATH "${BISON_BIN_DIR}")
    set(CMAKE_PROGRAM_PATH "${CMAKE_PROGRAM_PATH}" PARENT_SCOPE)
    
    # Register executable path for main project and tests
    thirdparty_register_executable_path("bison" "${BISON_EXECUTABLE_PATH}")
else()
    message(FATAL_ERROR "bison installation not found at ${BISON_INSTALL_DIR}")
endif()
