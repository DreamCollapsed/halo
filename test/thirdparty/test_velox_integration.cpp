#include <gtest/gtest.h>
#include <velox/type/Type.h>

using namespace facebook::velox;

TEST(VeloxIntegration, BasicTypeKind) {
  auto t = INTEGER();
  ASSERT_NE(t, nullptr);
  EXPECT_EQ(t->kind(), TypeKind::INTEGER);
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
