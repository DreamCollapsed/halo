add_executable(folly_test main.cpp)

target_include_directories(folly_test
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)

target_link_directories(folly_test
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)

add_dependencies(folly_test folly)

find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)

if(APPLE)
    target_link_libraries(folly_test
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
    target_link_libraries(folly_test
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

# 示例：添加一个简单的CTest测试
add_test(NAME folly_test_run COMMAND folly_test)

add_executable(unit_tests test_sample.cpp)

target_include_directories(unit_tests
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)

target_link_directories(unit_tests
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)

add_dependencies(unit_tests gtest)

target_link_libraries(unit_tests
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest.dylib
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest_main.dylib
)

add_test(NAME unit_tests_run COMMAND unit_tests)
