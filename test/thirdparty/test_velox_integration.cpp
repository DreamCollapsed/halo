#include <gtest/gtest.h>
#include <velox/type/Type.h>

using namespace facebook::velox;

TEST(VeloxIntegration, BasicTypeCreation) {
  // Test creating basic types using TypeFactory
  auto intType = TypeFactory<TypeKind::INTEGER>::create();
  ASSERT_NE(intType, nullptr);
  EXPECT_EQ(intType->kind(), TypeKind::INTEGER);
  EXPECT_EQ(intType->toString(), "INTEGER");
}

TEST(VeloxIntegration, MultipleTypeKinds) {
  // Test creating different types
  auto bigintType = TypeFactory<TypeKind::BIGINT>::create();
  auto doubleType = TypeFactory<TypeKind::DOUBLE>::create();
  auto varcharType = TypeFactory<TypeKind::VARCHAR>::create();
  
  ASSERT_NE(bigintType, nullptr);
  ASSERT_NE(doubleType, nullptr);
  ASSERT_NE(varcharType, nullptr);
  
  EXPECT_EQ(bigintType->kind(), TypeKind::BIGINT);
  EXPECT_EQ(doubleType->kind(), TypeKind::DOUBLE);
  EXPECT_EQ(varcharType->kind(), TypeKind::VARCHAR);
  
  EXPECT_EQ(bigintType->toString(), "BIGINT");
  EXPECT_EQ(doubleType->toString(), "DOUBLE");
  EXPECT_EQ(varcharType->toString(), "VARCHAR");
}

TEST(VeloxIntegration, TypeComparison) {
  auto intType1 = TypeFactory<TypeKind::INTEGER>::create();
  auto intType2 = TypeFactory<TypeKind::INTEGER>::create();
  auto bigintType = TypeFactory<TypeKind::BIGINT>::create();
  
  // Same type kinds should be equivalent
  EXPECT_TRUE(intType1->equivalent(*intType2));
  EXPECT_FALSE(intType1->equivalent(*bigintType));
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
