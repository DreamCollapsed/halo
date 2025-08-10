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

set(FLEX_EXECUTABLE "${FLEX_INSTALL_DIR}/bin/flex" CACHE FILEPATH "Path to flex executable" FORCE)

if(EXISTS "${FLEX_EXECUTABLE}")
    if(NOT TARGET flex::flex)
        add_executable(flex::flex IMPORTED GLOBAL)
        set_target_properties(flex::flex PROPERTIES
            IMPORTED_LOCATION "${FLEX_EXECUTABLE}"
        )
    endif()
    
    get_filename_component(FLEX_BIN_DIR "${FLEX_EXECUTABLE}" DIRECTORY)
    list(APPEND CMAKE_PROGRAM_PATH "${FLEX_BIN_DIR}")
    set(CMAKE_PROGRAM_PATH "${CMAKE_PROGRAM_PATH}" PARENT_SCOPE)
    set(FLEX_EXECUTABLE_PATH "${FLEX_EXECUTABLE}" CACHE INTERNAL "Path to project flex executable")
    
    message(STATUS "flex found and exported globally: ${FLEX_INSTALL_DIR}")
else()
    message(FATAL_ERROR "flex installation not found at ${FLEX_INSTALL_DIR}")
endif()
