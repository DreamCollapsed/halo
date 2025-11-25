// Minimal Velox smoke tests after refactor.

#include <folly/experimental/symbolizer/Symbolizer.h>
#include <gtest/gtest.h>
#include <velox/type/Type.h>
#include <velox/type/Variant.h>

TEST(VeloxIntegration, BasicTypeCreation) {
  auto int_type = facebook::velox::TypeFactory<
      facebook::velox::TypeKind::INTEGER>::create();
  ASSERT_NE(int_type, nullptr);
  EXPECT_EQ(int_type->kind(), facebook::velox::TypeKind::INTEGER);
  EXPECT_EQ(int_type->toString(), "INTEGER");
}

TEST(VeloxIntegration, MultipleTypeKinds) {
  auto bigint_type =
      facebook::velox::TypeFactory<facebook::velox::TypeKind::BIGINT>::create();
  auto double_type =
      facebook::velox::TypeFactory<facebook::velox::TypeKind::DOUBLE>::create();
  auto varchar_type = facebook::velox::TypeFactory<
      facebook::velox::TypeKind::VARCHAR>::create();
  ASSERT_NE(bigint_type, nullptr);
  ASSERT_NE(double_type, nullptr);
  ASSERT_NE(varchar_type, nullptr);
  EXPECT_EQ(bigint_type->kind(), facebook::velox::TypeKind::BIGINT);
  EXPECT_EQ(double_type->kind(), facebook::velox::TypeKind::DOUBLE);
  EXPECT_EQ(varchar_type->kind(), facebook::velox::TypeKind::VARCHAR);
}

TEST(VeloxIntegration, TypeComparison) {
  auto int_type1 = facebook::velox::TypeFactory<
      facebook::velox::TypeKind::INTEGER>::create();
  auto int_type2 = facebook::velox::TypeFactory<
      facebook::velox::TypeKind::INTEGER>::create();
  auto bigint_type =
      facebook::velox::TypeFactory<facebook::velox::TypeKind::BIGINT>::create();
  EXPECT_TRUE(int_type1->equivalent(*int_type2));
  EXPECT_FALSE(int_type1->equivalent(*bigint_type));
}

TEST(VeloxIntegration, LibunwindIntegration) {
  // Ensure libunwind is linked via folly
  folly::symbolizer::SafeStackTracePrinter printer;
  SUCCEED();
}
