#include <gtest/gtest.h>

#ifdef __linux__
#include <cblas.h>

#include <array>
#include <string>

// Basic OpenBLAS library integration test
TEST(OpenBLASIntegrationTest, BasicHeaderAndFunction) {
  // Test basic BLAS function availability
  // Create simple vectors for dot product
  std::array<float, 3> vec1 = {1.0F, 2.0F, 3.0F};
  std::array<float, 3> vec2 = {4.0F, 5.0F, 6.0F};

  // Compute dot product: should be 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
  float result = cblas_sdot(3, vec1.data(), 1, vec2.data(), 1);
  EXPECT_FLOAT_EQ(result, 32.0F);
}

// OpenBLAS version check test
TEST(OpenBLASIntegrationTest, VersionCheck) {
  // Get OpenBLAS configuration string
  const char* config = openblas_get_config();
  ASSERT_TRUE(config != nullptr);

  std::string config_str(config);
  // Ensure it's OpenBLAS
  EXPECT_TRUE(config_str.find("OpenBLAS") != std::string::npos);

  // Extract version number from config string
  // Config string format: "OpenBLAS x.y.z ..."
  size_t pos = config_str.find("OpenBLAS ");
  if (pos != std::string::npos) {
    pos += 9;  // Skip "OpenBLAS "
    size_t end_pos = config_str.find(' ', pos);
    if (end_pos != std::string::npos) {
      std::string version = config_str.substr(pos, end_pos - pos);
      EXPECT_FALSE(version.empty());
      // Basic version format check (should contain dots)
      EXPECT_TRUE(version.find('.') != std::string::npos);
      // Check for specific version
      EXPECT_EQ(version, "0.3.30");
    }
  }

  // Optional: Print the config for debugging
  std::cout << "OpenBLAS config: " << config_str << '\n';
}
#endif

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}