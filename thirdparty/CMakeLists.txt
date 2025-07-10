# Load common component information and utility functions
include(ComponentsInfo.cmake)
include(ThirdpartyUtils.cmake)

# Create required directories
file(MAKE_DIRECTORY ${THIRDPARTY_DOWNLOAD_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_SRC_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_BUILD_DIR})
file(MAKE_DIRECTORY ${THIRDPARTY_INSTALL_DIR})

# Integrate third-party libraries
include(cmake/abseil.cmake)
include(cmake/gtest.cmake)
include(cmake/gflags.cmake)
