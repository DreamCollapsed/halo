add_executable(halo main.cpp)

# Set include directories for halo
target_include_directories(halo
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)

# Set link directories for halo
target_link_directories(halo
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)

add_dependencies(halo folly)

find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)

if(APPLE)
    target_link_libraries(halo
        PRIVATE
        ${THIRDPARTY_INSTALL_DIR}/lib/libfolly.dylib
        ${THIRDPARTY_INSTALL_DIR}/lib/libglog.dylib
        ${THIRDPARTY_INSTALL_DIR}/lib/libgflags.dylib
        ${THIRDPARTY_INSTALL_DIR}/lib/libevent-2.1.7.dylib
        ${THIRDPARTY_INSTALL_DIR}/lib/libdouble-conversion.dylib
        ${THIRDPARTY_INSTALL_DIR}/lib/libfmt.dylib
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_context.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_chrono.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_date_time.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_filesystem.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_program_options.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_regex.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_system.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_thread.a
        OpenSSL::SSL
        OpenSSL::Crypto
        ZLIB::ZLIB
    )
else()
    target_link_libraries(halo
        PRIVATE
        ${THIRDPARTY_INSTALL_DIR}/lib/libfolly.so
        ${THIRDPARTY_INSTALL_DIR}/lib/libglog.so
        ${THIRDPARTY_INSTALL_DIR}/lib/libgflags.so
        ${THIRDPARTY_INSTALL_DIR}/lib/libevent-2.1.so
        ${THIRDPARTY_INSTALL_DIR}/lib/libdouble-conversion.so
        ${THIRDPARTY_INSTALL_DIR}/lib/libfmt.so
        ${THIRDPARTY_INSTALL_DIR}/lib/libunwind.so
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_context.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_chrono.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_date_time.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_filesystem.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_program_options.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_regex.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_system.a
        ${THIRDPARTY_INSTALL_DIR}/lib/libboost_thread.a
        OpenSSL::SSL
        OpenSSL::Crypto
        ZLIB::ZLIB
    )
endif()

# Example: Add a simple CTest test
add_test(NAME halo_test_run COMMAND halo)

add_executable(halo_unit_tests test_sample.cpp)

# Set include directories for halo_unit_tests
target_include_directories(halo_unit_tests
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)

# Set link directories for halo_unit_tests
target_link_directories(halo_unit_tests
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)

add_dependencies(halo_unit_tests googletest)

# Link GoogleTest libraries for halo_unit_tests
target_link_libraries(halo_unit_tests
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest.dylib
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest_main.dylib
)

add_test(NAME halo_unit_tests_run COMMAND halo_unit_tests)
