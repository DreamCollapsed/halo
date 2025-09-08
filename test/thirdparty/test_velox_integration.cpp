// Minimal Velox smoke tests after refactor.

#include <gtest/gtest.h>
#include <velox/type/Type.h>
#include <velox/type/Variant.h>

using namespace facebook::velox;

TEST(VeloxIntegration, BasicTypeCreation) {
  auto intType = TypeFactory<TypeKind::INTEGER>::create();
  ASSERT_NE(intType, nullptr);
  EXPECT_EQ(intType->kind(), TypeKind::INTEGER);
  EXPECT_EQ(intType->toString(), "INTEGER");
}

TEST(VeloxIntegration, MultipleTypeKinds) {
  auto bigintType = TypeFactory<TypeKind::BIGINT>::create();
  auto doubleType = TypeFactory<TypeKind::DOUBLE>::create();
  auto varcharType = TypeFactory<TypeKind::VARCHAR>::create();
  ASSERT_NE(bigintType, nullptr);
  ASSERT_NE(doubleType, nullptr);
  ASSERT_NE(varcharType, nullptr);
  EXPECT_EQ(bigintType->kind(), TypeKind::BIGINT);
  EXPECT_EQ(doubleType->kind(), TypeKind::DOUBLE);
  EXPECT_EQ(varcharType->kind(), TypeKind::VARCHAR);
}

TEST(VeloxIntegration, TypeComparison) {
  auto intType1 = TypeFactory<TypeKind::INTEGER>::create();
  auto intType2 = TypeFactory<TypeKind::INTEGER>::create();
  auto bigintType = TypeFactory<TypeKind::BIGINT>::create();
  EXPECT_TRUE(intType1->equivalent(*intType2));
  EXPECT_FALSE(intType1->equivalent(*bigintType));
}
