#include <faiss/IndexFlat.h>
#include <gtest/gtest.h>

// Basic FAISS library integration test
TEST(FaissIntegrationTest, BasicHeaderAndIndexCreation) {
  // Create a simple L2 index with dimension 4
  faiss::IndexFlatL2 index(4);
  // The dimension property should match the parameter
  EXPECT_EQ(index.d, 4);
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
