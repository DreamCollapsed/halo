#include <arrow/api.h>
#include <gtest/gtest.h>

TEST(Thirdparty, arrow_headers_and_types) {
  // Basic type factory works
  auto i32 = arrow::int32();
  ASSERT_NE(i32, nullptr);
  EXPECT_EQ(i32->id(), arrow::Type::INT32);

  // Array builder smoke test
  arrow::Int32Builder builder;
  ASSERT_TRUE(builder.Append(1).ok());
  ASSERT_TRUE(builder.Append(2).ok());
  ASSERT_TRUE(builder.Append(3).ok());
  std::shared_ptr<arrow::Array> out;
  ASSERT_TRUE(builder.Finish(&out).ok());
  ASSERT_NE(out, nullptr);
  EXPECT_EQ(out->length(), 3);
  auto int32_array = std::static_pointer_cast<arrow::Int32Array>(out);
  EXPECT_EQ(int32_array->Value(0), 1);
}

TEST(Thirdparty, string_array_with_nulls) {
  arrow::StringBuilder builder;
  ASSERT_TRUE(builder.Append("hello").ok());
  ASSERT_TRUE(builder.AppendNull().ok());
  ASSERT_TRUE(builder.Append("world").ok());
  std::shared_ptr<arrow::Array> arr;
  ASSERT_TRUE(builder.Finish(&arr).ok());
  auto sarr = std::static_pointer_cast<arrow::StringArray>(arr);
  ASSERT_EQ(sarr->length(), 3);
  ASSERT_FALSE(sarr->IsNull(0));
  ASSERT_TRUE(sarr->IsNull(1));
  ASSERT_EQ(sarr->GetString(0), "hello");
  ASSERT_EQ(sarr->GetString(2), "world");
}

TEST(Thirdparty, buffer_builder_roundtrip) {
  arrow::BufferBuilder bb;
  const uint8_t data[] = {1, 2, 3, 4, 5};
  ASSERT_TRUE(bb.Append(data, sizeof(data)).ok());
  std::shared_ptr<arrow::Buffer> buf;
  ASSERT_TRUE(bb.Finish(&buf).ok());
  ASSERT_EQ(buf->size(), 5);
  ASSERT_EQ(buf->data()[0], 1);
  ASSERT_EQ(buf->data()[4], 5);
}

TEST(Thirdparty, record_batch_and_slice) {
  auto f0 = arrow::field("a", arrow::int32());
  auto f1 = arrow::field("b", arrow::utf8());
  auto schema = arrow::schema({f0, f1});

  arrow::Int32Builder i32b;
  arrow::StringBuilder sb;
  ASSERT_TRUE(i32b.Append(10).ok());
  ASSERT_TRUE(i32b.Append(20).ok());
  ASSERT_TRUE(sb.Append("x").ok());
  ASSERT_TRUE(sb.Append("y").ok());

  std::shared_ptr<arrow::Array> a0, a1;
  ASSERT_TRUE(i32b.Finish(&a0).ok());
  ASSERT_TRUE(sb.Finish(&a1).ok());

  auto rb = arrow::RecordBatch::Make(schema, /*num_rows=*/2, {a0, a1});
  ASSERT_EQ(rb->num_rows(), 2);
  auto rb_slice = rb->Slice(1, 1);
  ASSERT_EQ(rb_slice->num_rows(), 1);
  auto col0 = std::static_pointer_cast<arrow::Int32Array>(rb_slice->column(0));
  auto col1 = std::static_pointer_cast<arrow::StringArray>(rb_slice->column(1));
  ASSERT_EQ(col0->Value(0), 20);
  ASSERT_EQ(col1->GetString(0), "y");
}
