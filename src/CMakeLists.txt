set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

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

add_test(NAME halo_test_run COMMAND halo)


# Abseil UT
add_executable(test_abseil ${CMAKE_SOURCE_DIR}/test/test_abseil.cpp)
set_target_properties(test_abseil PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/unit_test/thirdparty")

target_include_directories(test_abseil
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)

target_link_directories(test_abseil
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)

add_dependencies(test_abseil abseil googletest)

target_link_libraries(test_abseil
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest.dylib
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest_main.dylib
    ${THIRDPARTY_INSTALL_DIR}/lib/libabsl_strings.dylib
)

add_test(NAME abseil_ut COMMAND test_abseil)



add_executable(test_folly ${CMAKE_SOURCE_DIR}/test/test_folly.cpp)
set_target_properties(test_folly PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/unit_test/thirdparty")

# Set include directories for test_folly
target_include_directories(test_folly
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)

# Set link directories for test_folly
target_link_directories(test_folly
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)

add_dependencies(test_folly googletest)

# Link GoogleTest libraries for test_folly
target_link_libraries(test_folly
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest.dylib
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest_main.dylib
)

add_test(NAME test_folly COMMAND test_folly)
