#include <gtest/gtest.h>
#include <rapidjson/document.h>
#include <rapidjson/encodings.h>
#include <rapidjson/filereadstream.h>
#include <rapidjson/prettywriter.h>
#include <rapidjson/rapidjson.h>
#include <rapidjson/reader.h>
#include <rapidjson/schema.h>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>

#include <string>

TEST(RapidJSONIntegration, VersionCheck) {
  EXPECT_EQ(RAPIDJSON_MAJOR_VERSION, 1);
  EXPECT_EQ(RAPIDJSON_MINOR_VERSION, 1);
  EXPECT_EQ(RAPIDJSON_PATCH_VERSION, 0);
  EXPECT_STREQ(RAPIDJSON_VERSION_STRING, "1.1.0");
}

TEST(RapidJSONIntegration, ParseAndStringify) {
  const char* json = R"({"a":1,"b":[true,false,null],"s":"hi"})";
  rapidjson::Document doc;
  doc.Parse(json);
  ASSERT_FALSE(doc.HasParseError());
  ASSERT_TRUE(doc.HasMember("a"));
  ASSERT_TRUE(doc["b"].IsArray());
  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  doc.Accept(writer);
  std::string out = buffer.GetString();
  ASSERT_FALSE(out.empty());
}

TEST(RapidJSONIntegration, ComplexObjectManipulation) {
  rapidjson::Document doc;
  doc.SetObject();
  auto& allocator = doc.GetAllocator();

  // Add various types of values
  doc.AddMember("name", "John Doe", allocator);
  doc.AddMember("age", 30, allocator);
  doc.AddMember("is_student", false, allocator);
  doc.AddMember("height", 175.5, allocator);

  // Add array
  rapidjson::Value hobbies(rapidjson::kArrayType);
  hobbies.PushBack("reading", allocator);
  hobbies.PushBack("swimming", allocator);
  hobbies.PushBack("coding", allocator);
  doc.AddMember("hobbies", hobbies, allocator);

  // Add nested object
  rapidjson::Value address(rapidjson::kObjectType);
  address.AddMember("street", "123 Main St", allocator);
  address.AddMember("city", "New York", allocator);
  address.AddMember("zip", "10001", allocator);
  doc.AddMember("address", address, allocator);

  // Verify structure
  ASSERT_TRUE(doc.HasMember("name"));
  ASSERT_TRUE(doc["name"].IsString());
  EXPECT_EQ(std::string(doc["name"].GetString()), "John Doe");

  ASSERT_TRUE(doc.HasMember("age"));
  EXPECT_EQ(doc["age"].GetInt(), 30);

  ASSERT_TRUE(doc.HasMember("hobbies"));
  ASSERT_TRUE(doc["hobbies"].IsArray());
  EXPECT_EQ(doc["hobbies"].Size(), 3);
  EXPECT_EQ(std::string(doc["hobbies"][0].GetString()), "reading");

  ASSERT_TRUE(doc.HasMember("address"));
  ASSERT_TRUE(doc["address"].IsObject());
  EXPECT_EQ(std::string(doc["address"]["city"].GetString()), "New York");
}

TEST(RapidJSONIntegration, ArrayOperations) {
  const char* json =
      R"({"numbers":[1,2,3,4,5],"mixed":[true,"hello",42,null]})";
  rapidjson::Document doc;
  doc.Parse(json);

  ASSERT_FALSE(doc.HasParseError());
  ASSERT_TRUE(doc.HasMember("numbers"));
  ASSERT_TRUE(doc["numbers"].IsArray());

  // Test array iteration and modification
  auto& numbers = doc["numbers"];
  EXPECT_EQ(numbers.Size(), 5);

  // Sum all numbers
  int sum = 0;
  for (rapidjson::SizeType i = 0; i < numbers.Size(); ++i) {
    ASSERT_TRUE(numbers[i].IsInt());
    sum += numbers[i].GetInt();
  }
  EXPECT_EQ(sum, 15);  // 1+2+3+4+5

  // Test mixed array
  auto& mixed = doc["mixed"];
  EXPECT_EQ(mixed.Size(), 4);
  EXPECT_TRUE(mixed[0].IsBool());
  EXPECT_TRUE(mixed[1].IsString());
  EXPECT_TRUE(mixed[2].IsInt());
  EXPECT_TRUE(mixed[3].IsNull());

  EXPECT_TRUE(mixed[0].GetBool());
  EXPECT_EQ(std::string(mixed[1].GetString()), "hello");
  EXPECT_EQ(mixed[2].GetInt(), 42);
}

TEST(RapidJSONIntegration, PrettyPrinting) {
  rapidjson::Document doc;
  doc.SetObject();
  auto& allocator = doc.GetAllocator();

  // Create nested structure
  rapidjson::Value user(rapidjson::kObjectType);
  user.AddMember("id", 123, allocator);
  user.AddMember("username", "testuser", allocator);

  rapidjson::Value tags(rapidjson::kArrayType);
  tags.PushBack("admin", allocator);
  tags.PushBack("developer", allocator);
  user.AddMember("tags", tags, allocator);

  doc.AddMember("user", user, allocator);
  doc.AddMember("timestamp", "2023-01-01T00:00:00Z", allocator);

  // Generate pretty-printed JSON
  rapidjson::StringBuffer buffer;
  rapidjson::PrettyWriter<rapidjson::StringBuffer> writer(buffer);
  doc.Accept(writer);

  std::string pretty_json = buffer.GetString();
  ASSERT_FALSE(pretty_json.empty());

  // Should contain newlines and indentation
  EXPECT_NE(pretty_json.find('\n'), std::string::npos);
  EXPECT_NE(pretty_json.find("  "), std::string::npos);  // indentation
}

TEST(RapidJSONIntegration, ErrorHandling) {
  // Test parsing invalid JSON
  const char* invalid_json = R"({"name":"John","age":30,})";  // trailing comma
  rapidjson::Document doc;
  doc.Parse(invalid_json);

  EXPECT_TRUE(doc.HasParseError());
  auto error_code = doc.GetParseError();
  EXPECT_NE(error_code, rapidjson::kParseErrorNone);

  // Test missing member access
  const char* valid_json = R"({"name":"John"})";
  rapidjson::Document valid_doc;
  valid_doc.Parse(valid_json);

  ASSERT_FALSE(valid_doc.HasParseError());
  EXPECT_FALSE(valid_doc.HasMember("age"));  // member doesn't exist

  // Safe member access
  if (valid_doc.HasMember("age") && valid_doc["age"].IsInt()) {
    // This branch should not execute
    FAIL() << "Age member should not exist";
  }
}

TEST(RapidJSONIntegration, DynamicTypeChecking) {
  const char* json = R"({
    "string_val": "hello",
    "int_val": 42,
    "double_val": 3.14,
    "bool_val": true,
    "null_val": null,
    "array_val": [1,2,3],
    "object_val": {"nested": "value"}
  })";

  rapidjson::Document doc;
  doc.Parse(json);
  ASSERT_FALSE(doc.HasParseError());

  // Test type checking
  EXPECT_TRUE(doc["string_val"].IsString());
  EXPECT_FALSE(doc["string_val"].IsInt());

  EXPECT_TRUE(doc["int_val"].IsInt());
  EXPECT_TRUE(doc["int_val"].IsNumber());
  EXPECT_FALSE(doc["int_val"].IsString());

  EXPECT_TRUE(doc["double_val"].IsDouble());
  EXPECT_TRUE(doc["double_val"].IsNumber());

  EXPECT_TRUE(doc["bool_val"].IsBool());
  EXPECT_FALSE(doc["bool_val"].IsString());

  EXPECT_TRUE(doc["null_val"].IsNull());

  EXPECT_TRUE(doc["array_val"].IsArray());
  EXPECT_FALSE(doc["array_val"].IsObject());

  EXPECT_TRUE(doc["object_val"].IsObject());
  EXPECT_FALSE(doc["object_val"].IsArray());
}

TEST(RapidJSONIntegration, LargeNumberHandling) {
  rapidjson::Document doc;
  doc.SetObject();
  auto& allocator = doc.GetAllocator();

  // Test various number types
  doc.AddMember("small_int", 42, allocator);
  doc.AddMember("large_int", 2147483647, allocator);  // max int32
  doc.AddMember("int64_val", static_cast<int64_t>(9223372036854775807LL),
                allocator);
  doc.AddMember("uint64_val", static_cast<uint64_t>(18446744073709551615ULL),
                allocator);
  doc.AddMember("float_val", 123.456F, allocator);
  doc.AddMember("double_val", 789.012, allocator);

  // Serialize and parse back
  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  doc.Accept(writer);

  rapidjson::Document parsed;
  parsed.Parse(buffer.GetString());
  ASSERT_FALSE(parsed.HasParseError());

  // Verify values
  EXPECT_EQ(parsed["small_int"].GetInt(), 42);
  EXPECT_EQ(parsed["large_int"].GetInt(), 2147483647);

  if (parsed["int64_val"].IsInt64()) {
    EXPECT_EQ(parsed["int64_val"].GetInt64(), 9223372036854775807LL);
  }

  EXPECT_NEAR(parsed["double_val"].GetDouble(), 789.012, 1e-15);
}

TEST(RapidJSONIntegration, MemberIterationAndModification) {
  rapidjson::Document doc;
  doc.SetObject();
  auto& allocator = doc.GetAllocator();

  // Add multiple members
  doc.AddMember("a", 1, allocator);
  doc.AddMember("b", 2, allocator);
  doc.AddMember("c", 3, allocator);

  // Iterate through members
  int sum = 0;
  for (auto it = doc.MemberBegin(); it != doc.MemberEnd(); ++it) {
    EXPECT_TRUE(it->name.IsString());
    EXPECT_TRUE(it->value.IsInt());
    sum += it->value.GetInt();
  }
  EXPECT_EQ(sum, 6);  // 1+2+3

  // Remove a member
  doc.RemoveMember("b");
  EXPECT_FALSE(doc.HasMember("b"));
  EXPECT_EQ(doc.MemberCount(), 2);

  // Modify existing member
  doc["a"] = 10;
  EXPECT_EQ(doc["a"].GetInt(), 10);
}
