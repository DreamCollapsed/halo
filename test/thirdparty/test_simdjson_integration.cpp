#include <gtest/gtest.h>
#include <simdjson.h>

#include <string>
#include <vector>

// Basic version & implementation availability test
TEST(SimdjsonIntegration, VersionAPILoad) {
  const simdjson::implementation *impl = simdjson::get_active_implementation();
  ASSERT_NE(impl, nullptr);
  ASSERT_FALSE(impl->name().empty());
  // Count available implementations via iteration API
  size_t impl_count = 0;
  for (const auto &named_impl : simdjson::get_available_implementations()) {
    (void)named_impl;
    ++impl_count;
  }
  ASSERT_GT(impl_count, 0);
}

// Parse a simple JSON string
TEST(SimdjsonIntegration, SimpleParse) {
  // padded_string ensures required  SIMDJSON_PADDING bytes
  std::string raw = R"({"answer":42,"ok":true,"pi":3.14159,"array":[1,2,3]})";
  simdjson::padded_string json(raw.c_str(), raw.size());
  simdjson::ondemand::parser parser;
  auto doc_res = parser.iterate(json);
  ASSERT_EQ(doc_res.error(), simdjson::SUCCESS);
  auto answer_res = doc_res.value()["answer"].get_int64();
  ASSERT_EQ(answer_res.error(), simdjson::SUCCESS);
  auto ok_res = doc_res.value()["ok"].get_bool();
  ASSERT_EQ(ok_res.error(), simdjson::SUCCESS);
  auto pi_res = doc_res.value()["pi"].get_double();
  ASSERT_EQ(pi_res.error(), simdjson::SUCCESS);
  auto arr_res = doc_res.value()["array"].get_array();
  ASSERT_EQ(arr_res.error(), simdjson::SUCCESS);
  std::vector<int64_t> values;
  for (auto value_item : arr_res.value()) {
    auto v_int = static_cast<int64_t>(value_item.get_int64().value());
    values.push_back(v_int);
  }
  EXPECT_EQ(answer_res.value(), 42);
  EXPECT_TRUE(ok_res.value());
  EXPECT_NEAR(pi_res.value(), 3.14159, 1e-6);
  ASSERT_EQ(values.size(), 3);
  EXPECT_EQ(values[0], 1);
  EXPECT_EQ(values[1], 2);
  EXPECT_EQ(values[2], 3);
}

// Streaming large concatenated JSON documents (ndjson style) test
TEST(SimdjsonIntegration, ManyDocuments) {
  // Construct concatenated JSON documents
  std::string stream;
  stream.reserve(4096);
  for (int i = 0; i < 100; i++) {
    stream += std::string("{\"i\":") + std::to_string(i) +
              ",\"value\":" + std::to_string(i * i) +
              "}";  // no newlines needed
  }
  simdjson::ondemand::parser parser;
  size_t count = 0;
  size_t sum = 0;
  auto docs_result =
      parser.iterate_many(stream);  // simdjson_result<document_stream>
  ASSERT_EQ(docs_result.error(), simdjson::SUCCESS);
  for (auto doc : docs_result.value()) {
    int64_t i_item = doc["i"].get_int64();
    int64_t value = doc["value"].get_int64();
    EXPECT_EQ(value, i_item * i_item);
    sum += static_cast<size_t>(value);
    ++count;
  }
  EXPECT_EQ(count, 100);
  // Sum of squares 0..99 = 99*100*199/6
  size_t expected = 99 * 100 * 199 / 6;
  EXPECT_EQ(sum, expected);
}

// Validation of invalid JSON error pathways
TEST(SimdjsonIntegration, InvalidJson) {
  const char *bad = R"({"unterminated_key: 123)";  // missing end quote
  simdjson::ondemand::parser parser;
  auto doc_res = parser.iterate(bad);
  // Expect a parse error immediately (cannot even access fields cleanly)
  EXPECT_NE(doc_res.error(), simdjson::SUCCESS);
}
