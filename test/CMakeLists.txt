# Unit test build

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
target_include_directories(test_folly
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/include
)
target_link_directories(test_folly
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib
)
add_dependencies(test_folly googletest)
target_link_libraries(test_folly
    PRIVATE
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest.dylib
    ${THIRDPARTY_INSTALL_DIR}/lib/libgtest_main.dylib
)
add_test(NAME test_folly COMMAND test_folly)
