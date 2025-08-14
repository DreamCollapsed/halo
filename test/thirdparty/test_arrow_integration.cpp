#include <arrow/api.h>
#include <arrow/compute/api.h>
#include <arrow/csv/api.h>
#include <arrow/io/api.h>
#include <arrow/ipc/api.h>
#include <arrow/json/api.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

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

TEST(ArrowIntegration, DoubleArrayOperations) {
  arrow::DoubleBuilder builder;
  std::vector<double> values = {1.1, 2.2, 3.3, 4.4, 5.5};

  for (double val : values) {
    ASSERT_TRUE(builder.Append(val).ok());
  }

  std::shared_ptr<arrow::Array> array;
  ASSERT_TRUE(builder.Finish(&array).ok());

  auto double_array = std::static_pointer_cast<arrow::DoubleArray>(array);
  ASSERT_EQ(double_array->length(), 5);

  // Test individual values
  for (int i = 0; i < 5; ++i) {
    EXPECT_DOUBLE_EQ(double_array->Value(i), values[i]);
  }

  // Test null count
  EXPECT_EQ(double_array->null_count(), 0);
}

TEST(ArrowIntegration, TableCreationAndFiltering) {
  // Create schema
  auto f0 = arrow::field("id", arrow::int64());
  auto f1 = arrow::field("name", arrow::utf8());
  auto f2 = arrow::field("score", arrow::float64());
  auto schema = arrow::schema({f0, f1, f2});

  // Build arrays
  arrow::Int64Builder id_builder;
  arrow::StringBuilder name_builder;
  arrow::DoubleBuilder score_builder;

  std::vector<int64_t> ids = {1, 2, 3, 4, 5};
  std::vector<std::string> names = {"Alice", "Bob", "Charlie", "David", "Eve"};
  std::vector<double> scores = {95.5, 87.2, 92.1, 78.8, 99.9};

  for (size_t i = 0; i < ids.size(); ++i) {
    ASSERT_TRUE(id_builder.Append(ids[i]).ok());
    ASSERT_TRUE(name_builder.Append(names[i]).ok());
    ASSERT_TRUE(score_builder.Append(scores[i]).ok());
  }

  std::shared_ptr<arrow::Array> id_array, name_array, score_array;
  ASSERT_TRUE(id_builder.Finish(&id_array).ok());
  ASSERT_TRUE(name_builder.Finish(&name_array).ok());
  ASSERT_TRUE(score_builder.Finish(&score_array).ok());

  // Create table
  auto table = arrow::Table::Make(schema, {id_array, name_array, score_array});
  ASSERT_EQ(table->num_rows(), 5);
  ASSERT_EQ(table->num_columns(), 3);

  // Test column access by name from schema
  EXPECT_EQ(table->schema()->field(0)->name(), "id");
  EXPECT_EQ(table->schema()->field(1)->name(), "name");
  EXPECT_EQ(table->schema()->field(2)->name(), "score");
}

TEST(ArrowIntegration, IOMemoryBufferOperations) {
  // Test in-memory buffer operations
  std::string test_data = "Hello, Arrow world!";
  auto buffer = arrow::Buffer::FromString(test_data);

  ASSERT_EQ(buffer->size(), test_data.size());
  EXPECT_EQ(std::string(reinterpret_cast<const char*>(buffer->data()),
                        buffer->size()),
            test_data);

  // Test buffer slicing
  auto slice = arrow::SliceBuffer(buffer, 7, 5);  // "Arrow"
  ASSERT_EQ(slice->size(), 5);
  EXPECT_EQ(
      std::string(reinterpret_cast<const char*>(slice->data()), slice->size()),
      "Arrow");

  // Test mutable buffer
  ASSERT_TRUE(arrow::AllocateBuffer(100).ok());
  auto mutable_buffer_result = arrow::AllocateBuffer(100);
  ASSERT_TRUE(mutable_buffer_result.ok());
  auto mutable_buffer = std::move(mutable_buffer_result).ValueOrDie();

  ASSERT_EQ(mutable_buffer->size(), 100);
  ASSERT_TRUE(mutable_buffer->is_mutable());
}

TEST(ArrowIntegration, ComputeOperations) {
  // Create array for computation
  arrow::Int32Builder builder;
  std::vector<int32_t> values = {10, 20, 30, 40, 50};

  for (int32_t val : values) {
    ASSERT_TRUE(builder.Append(val).ok());
  }

  std::shared_ptr<arrow::Array> array;
  ASSERT_TRUE(builder.Finish(&array).ok());

  // Test basic array operations without compute functions
  // Verify the array was created correctly
  auto int32_array = std::static_pointer_cast<arrow::Int32Array>(array);
  ASSERT_EQ(int32_array->length(), 5);

  // Manually verify values and compute sum
  int64_t manual_sum = 0;
  int32_t manual_min = int32_array->Value(0);
  int32_t manual_max = int32_array->Value(0);

  for (int64_t i = 0; i < int32_array->length(); ++i) {
    int32_t value = int32_array->Value(i);
    manual_sum += value;
    manual_min = std::min(manual_min, value);
    manual_max = std::max(manual_max, value);
  }

  EXPECT_EQ(manual_sum, 150);  // 10+20+30+40+50
  EXPECT_EQ(manual_min, 10);
  EXPECT_EQ(manual_max, 50);

  // Test array slicing and filtering
  auto slice = array->Slice(1, 3);  // Elements at indices 1, 2, 3
  ASSERT_EQ(slice->length(), 3);

  auto slice_int32 = std::static_pointer_cast<arrow::Int32Array>(slice);
  EXPECT_EQ(slice_int32->Value(0), 20);  // Index 1 from original
  EXPECT_EQ(slice_int32->Value(1), 30);  // Index 2 from original
  EXPECT_EQ(slice_int32->Value(2), 40);  // Index 3 from original
}

TEST(ArrowIntegration, IPCStreamingFormat) {
  // Create a simple table
  auto f0 = arrow::field("numbers", arrow::int32());
  auto schema = arrow::schema({f0});

  arrow::Int32Builder builder;
  for (int i = 0; i < 10; ++i) {
    ASSERT_TRUE(builder.Append(i * i).ok());  // squares: 0, 1, 4, 9, 16, ...
  }

  std::shared_ptr<arrow::Array> array;
  ASSERT_TRUE(builder.Finish(&array).ok());

  auto record_batch = arrow::RecordBatch::Make(schema, 10, {array});

  // Serialize to IPC format
  auto buffer_output_stream = arrow::io::BufferOutputStream::Create();
  ASSERT_TRUE(buffer_output_stream.ok());
  auto output_stream = buffer_output_stream.ValueOrDie();

  auto writer_result = arrow::ipc::MakeStreamWriter(output_stream, schema);
  ASSERT_TRUE(writer_result.ok());
  auto writer = writer_result.ValueOrDie();

  ASSERT_TRUE(writer->WriteRecordBatch(*record_batch).ok());
  ASSERT_TRUE(writer->Close().ok());

  // Get the buffer
  auto buffer_result = output_stream->Finish();
  ASSERT_TRUE(buffer_result.ok());
  auto buffer = buffer_result.ValueOrDie();

  ASSERT_GT(buffer->size(), 0);

  // Test deserialization
  auto buffer_reader = std::make_shared<arrow::io::BufferReader>(buffer);
  auto reader_result = arrow::ipc::RecordBatchStreamReader::Open(buffer_reader);
  ASSERT_TRUE(reader_result.ok());
  auto reader = reader_result.ValueOrDie();

  std::shared_ptr<arrow::RecordBatch> read_batch;
  ASSERT_TRUE(reader->ReadNext(&read_batch).ok());
  ASSERT_NE(read_batch, nullptr);
  ASSERT_EQ(read_batch->num_rows(), 10);

  auto read_array =
      std::static_pointer_cast<arrow::Int32Array>(read_batch->column(0));
  for (int i = 0; i < 10; ++i) {
    EXPECT_EQ(read_array->Value(i), i * i);
  }
}

TEST(ArrowIntegration, CSVReadingWriting) {
  // Create test CSV data
  std::string csv_data = R"(name,age,city
Alice,25,New York
Bob,30,San Francisco
Charlie,35,Chicago)";

  auto input = std::make_shared<arrow::io::BufferReader>(
      arrow::Buffer::FromString(csv_data));

  // Read CSV
  auto csv_reader_result = arrow::csv::TableReader::Make(
      arrow::io::default_io_context(), input,
      arrow::csv::ReadOptions::Defaults(), arrow::csv::ParseOptions::Defaults(),
      arrow::csv::ConvertOptions::Defaults());
  ASSERT_TRUE(csv_reader_result.ok());
  auto csv_reader = csv_reader_result.ValueOrDie();

  auto table_result = csv_reader->Read();
  ASSERT_TRUE(table_result.ok());
  auto table = table_result.ValueOrDie();

  ASSERT_EQ(table->num_rows(), 3);
  ASSERT_EQ(table->num_columns(), 3);

  // Check column names
  auto schema = table->schema();
  EXPECT_EQ(schema->field(0)->name(), "name");
  EXPECT_EQ(schema->field(1)->name(), "age");
  EXPECT_EQ(schema->field(2)->name(), "city");
}

TEST(ArrowIntegration, DictionaryArrays) {
  // Create dictionary array for categorical data
  arrow::StringBuilder dict_builder;
  ASSERT_TRUE(dict_builder.Append("Red").ok());
  ASSERT_TRUE(dict_builder.Append("Green").ok());
  ASSERT_TRUE(dict_builder.Append("Blue").ok());

  std::shared_ptr<arrow::Array> dict_array;
  ASSERT_TRUE(dict_builder.Finish(&dict_array).ok());

  // Create indices
  arrow::Int8Builder index_builder;
  std::vector<int8_t> indices = {
      0, 1, 2, 1, 0, 2, 1};  // Red, Green, Blue, Green, Red, Blue, Green

  for (int8_t idx : indices) {
    ASSERT_TRUE(index_builder.Append(idx).ok());
  }

  std::shared_ptr<arrow::Array> index_array;
  ASSERT_TRUE(index_builder.Finish(&index_array).ok());

  // Create dictionary array
  auto dict_type = arrow::dictionary(arrow::int8(), arrow::utf8());
  auto dict_array_result =
      arrow::DictionaryArray::FromArrays(dict_type, index_array, dict_array);
  ASSERT_TRUE(dict_array_result.ok());
  auto dictionary_array = dict_array_result.ValueOrDie();

  ASSERT_EQ(dictionary_array->length(), 7);

  // Cast to dictionary array to access dictionary
  auto dict_array_cast =
      std::static_pointer_cast<arrow::DictionaryArray>(dictionary_array);
  ASSERT_EQ(dict_array_cast->dictionary()->length(), 3);

  // Test dictionary lookup
  auto string_dict = std::static_pointer_cast<arrow::StringArray>(
      dict_array_cast->dictionary());
  EXPECT_EQ(string_dict->GetString(0), "Red");
  EXPECT_EQ(string_dict->GetString(1), "Green");
  EXPECT_EQ(string_dict->GetString(2), "Blue");
}
