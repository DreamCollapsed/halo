cmake_minimum_required(VERSION 3.22)
project(MyProject VERSION 1.0.0 LANGUAGES CXX)

# 设置 C++23 标准
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# 设置输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 设置三方库相关路径
set(THIRDPARTY_DOWNLOAD_DIR ${CMAKE_SOURCE_DIR}/thirdparty/downloaded)
set(THIRDPARTY_SRC_DIR ${CMAKE_SOURCE_DIR}/thirdparty/src)
set(THIRDPARTY_INSTALL_DIR ${CMAKE_SOURCE_DIR}/thirdparty/installed)

# 创建必要的目录
file(MAKE_DIRECTORY ${THIRDPARTY_DOWNLOAD_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_SRC_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_INSTALL_DIR})

# 添加三方库的 CMake 配置
add_subdirectory(thirdparty)

# 设置编译器
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

# 添加编译选项
add_compile_options(-fPIC)

# 添加项目源代码
add_subdirectory(src) 