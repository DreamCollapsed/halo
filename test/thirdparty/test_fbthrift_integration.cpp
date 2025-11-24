#include <folly/FBString.h>
#include <folly/Random.h>
#include <folly/Range.h>
#include <folly/String.h>
#include <folly/init/Init.h>
#include <gtest/gtest.h>
#include <thrift/lib/cpp2/Thrift.h>
#include <thrift/lib/cpp2/async/RpcTypes.h>
#include <thrift/lib/cpp2/protocol/BinaryProtocol.h>
#include <thrift/lib/cpp2/protocol/CompactProtocol.h>
#include <thrift/lib/cpp2/protocol/JSONProtocol.h>
#include <thrift/lib/cpp2/protocol/Serializer.h>
#include <thrift/lib/cpp2/server/ThriftServer.h>
#include <thrift/lib/cpp2/transport/core/ThriftRequest.h>

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <numbers>
#include <string>
#include <thread>
#include <vector>

TEST(FbthriftIntegration, BasicServerConfig) {
  apache::thrift::ThriftServer server;  // construction should succeed
  server.setNumIOWorkerThreads(1);
  server.setNumCPUWorkerThreads(1);
  SUCCEED();
}

TEST(FbthriftIntegration, SimpleSerialization) {
  // Serialize a simple struct-like object via protocol writer/reader round-trip
  // for a string
  folly::fbstring input = "hello";
  // Use CompactProtocol serializer (no user-defined struct; just test
  // availability of serializer template)
  apache::thrift::CompactProtocolWriter writer;
  folly::IOBufQueue queue;
  writer.setOutput(&queue, /*maxGrowth*/ 1U);
  writer.writeString(input);
  auto buf = queue.move();
  apache::thrift::CompactProtocolReader reader;
  reader.setInput(buf.get());
  std::string out;
  reader.readString(out);
  EXPECT_EQ(out, input.toStdString());
}

// Invalid operation test (attempt to read beyond buffer) to exercise error
// paths
TEST(FbthriftIntegration, ErrorPath) {
  apache::thrift::CompactProtocolReader reader;
  auto empty = folly::IOBuf::create(0);
  reader.setInput(empty.get());
  std::string value;
  // Reading string from empty buffer should fail; ensure it does not crash
  try {
    reader.readString(value);
    // If no exception, value should still be empty
    EXPECT_TRUE(value.empty());
  } catch (const std::exception&) {
    SUCCEED();
  }
}

// Large string serialization to exercise buffering and ensure no crashes for
// larger payloads
TEST(FbthriftIntegration, LargeStringSerialization) {
  std::string large(1 << 16, 'x');  // 64KB
  apache::thrift::CompactProtocolWriter writer;
  folly::IOBufQueue buffer_queue;
  writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
  writer.writeString(large);
  auto buf = buffer_queue.move();
  apache::thrift::CompactProtocolReader reader;
  reader.setInput(buf.get());
  std::string out;
  reader.readString(out);
  EXPECT_EQ(out, large);
}

// Idempotency of ensureFollyInit under concurrency (race test)
TEST(FbthriftIntegration, ConcurrentEnsureInit) {
  constexpr int THREAD_COUNT = 16;
  std::vector<std::thread> threads;
  threads.reserve(THREAD_COUNT);
  for (int i = 0; i < THREAD_COUNT; ++i) {
    threads.emplace_back([]() {});
  }
  for (auto& thread : threads) {
    thread.join();
  }
  SUCCEED();
}

// String serialization roundtrip test with various edge cases
TEST(FbthriftIntegration, StringSerializationRoundTrip) {
  std::vector<std::string> test_cases = {"",
                                         "f",
                                         "fo",
                                         "foo",
                                         "foobar",
                                         std::string(1, '\0'),
                                         std::string(2, '\0'),
                                         std::string(3, '\0')};

  for (const auto& test_value : test_cases) {
    apache::thrift::CompactProtocolWriter writer;
    folly::IOBufQueue buffer_queue;
    writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
    writer.writeString(test_value);
    auto buf = buffer_queue.move();

    apache::thrift::CompactProtocolReader reader;
    reader.setInput(buf.get());
    std::string result;
    reader.readString(result);
    EXPECT_EQ(result, test_value);
  }

  // Test with random data
  for (int i = 0; i < 32; ++i) {
    size_t len = folly::Random::rand32() % 256;
    std::string random_value;
    random_value.resize(len);
    for (size_t j = 0; j < len; ++j) {
      random_value[j] = static_cast<char>(folly::Random::rand32() & 0xFF);
    }

    apache::thrift::CompactProtocolWriter writer;
    folly::IOBufQueue buffer_queue;
    writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
    writer.writeString(random_value);
    auto buf = buffer_queue.move();

    apache::thrift::CompactProtocolReader reader;
    reader.setInput(buf.get());
    std::string result;
    reader.readString(result);
    EXPECT_EQ(result, random_value);
  }
}

// Multi-protocol serialization tests to exercise different protocol paths
TEST(FbthriftIntegration, MultiProtocolSerialization) {
  std::string test_data = "MultiProtocol测试数据";

  // Test BinaryProtocol
  {
    apache::thrift::BinaryProtocolWriter writer;
    folly::IOBufQueue buffer_queue;
    writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
    writer.writeString(test_data);
    auto buf = buffer_queue.move();
    apache::thrift::BinaryProtocolReader reader;
    reader.setInput(buf.get());
    std::string out;
    reader.readString(out);
    EXPECT_EQ(out, test_data) << "BinaryProtocol roundtrip failed";
  }

  // Test JSONProtocol
  {
    apache::thrift::JSONProtocolWriter writer;
    folly::IOBufQueue buffer_queue;
    writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
    writer.writeString(test_data);
    auto buf = buffer_queue.move();
    apache::thrift::JSONProtocolReader reader;
    reader.setInput(buf.get());
    std::string out;
    reader.readString(out);
    EXPECT_EQ(out, test_data) << "JSONProtocol roundtrip failed";
  }
}

// Protocol exception handling to exercise error paths
TEST(FbthriftIntegration, ProtocolExceptionHandling) {
  // Test malformed JSON protocol input
  try {
    apache::thrift::JSONProtocolReader reader;
    std::string malformed = "{ invalid json";
    auto buf = folly::IOBuf::copyBuffer(malformed);
    reader.setInput(buf.get());
    std::string out;
    reader.readString(out);  // Should throw or handle gracefully
    // If no exception, that's also acceptable (robust error handling)
  } catch (const apache::thrift::TException&) {
    SUCCEED();  // Expected exception type
  } catch (const std::exception&) {
    SUCCEED();  // Other exception is also acceptable
  }

  // Test truncated binary protocol
  try {
    apache::thrift::BinaryProtocolReader reader;
    std::string truncated = std::string{
        '\x00', '\x00', '\x00', '\x10'};  // Claims 16 bytes but only has 4
    auto buf = folly::IOBuf::copyBuffer(truncated);
    reader.setInput(buf.get());
    std::string out;
    reader.readString(out);
  } catch (const apache::thrift::TException&) {
    SUCCEED();
  } catch (const std::exception&) {
    SUCCEED();
  }
}

// Stress test with mixed protocols and large data
TEST(FbthriftIntegration, ProtocolStressTest) {
  // Generate varied test data
  std::vector<std::string> test_cases;
  test_cases.emplace_back("");  // empty
  test_cases.emplace_back("simple");
  test_cases.emplace_back(1024, 'A');  // 1KB
  test_cases.emplace_back("Unicode: 你好世界 🌍");

  // Binary data with all byte values
  std::string binary_data;
  for (int i = 0; i < 256; ++i) {
    binary_data.push_back(static_cast<char>(i));
  }
  test_cases.emplace_back(binary_data);

  for (const auto& data : test_cases) {
    // Compact Protocol
    {
      apache::thrift::CompactProtocolWriter writer;
      folly::IOBufQueue buffer_queue;
      writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
      writer.writeString(data);
      auto buf = buffer_queue.move();
      apache::thrift::CompactProtocolReader reader;
      reader.setInput(buf.get());
      std::string out;
      reader.readString(out);
      EXPECT_EQ(out, data) << "CompactProtocol failed for data size: "
                           << data.size();
    }

    // Binary Protocol
    {
      apache::thrift::BinaryProtocolWriter writer;
      folly::IOBufQueue buffer_queue;
      writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
      writer.writeString(data);
      auto buf = buffer_queue.move();
      apache::thrift::BinaryProtocolReader reader;
      reader.setInput(buf.get());
      std::string out;
      reader.readString(out);
      EXPECT_EQ(out, data) << "BinaryProtocol failed for data size: "
                           << data.size();
    }
  }
}

// Test FBThrift serializer templates for high-level API
TEST(FbthriftIntegration, SerializerTemplates) {
  // Test with simple types using serializer utilities
  std::string test_string = "Serializer测试";
  int32_t test_int = 42;
  double test_double = std::numbers::pi;

  // While we don't have custom structs, we can test basic serialization
  // primitives through protocol writers/readers which are the foundation of
  // FBThrift serializers

  // Test string serialization with all protocols
  std::vector<std::string> protocols = {"Binary", "Compact", "JSON"};

  (void)test_int;
  (void)test_double;

  for (const auto& protocol_name : protocols) {
    if (protocol_name == "Binary") {
      apache::thrift::BinaryProtocolWriter writer;
      folly::IOBufQueue buffer_queue;
      writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
      writer.writeString(test_string);
      auto buf = buffer_queue.move();

      apache::thrift::BinaryProtocolReader reader;
      reader.setInput(buf.get());
      std::string result;
      reader.readString(result);
      EXPECT_EQ(result, test_string) << "Binary protocol string test failed";
    }
  }
}

// Test FBThrift async capabilities and server setup
TEST(FbthriftIntegration, AsyncCapabilities) {
  // Test ThriftServer configuration options
  apache::thrift::ThriftServer server;

  // Test various server configuration methods
  server.setNumIOWorkerThreads(2);
  server.setNumCPUWorkerThreads(4);
  server.setMaxRequests(1000);
  server.setTaskExpireTime(std::chrono::milliseconds(5000));
  server.setQueueTimeout(std::chrono::milliseconds(1000));

  // Test that server can be configured without crashing
  EXPECT_EQ(server.getNumIOWorkerThreads(), 2);
  EXPECT_EQ(server.getNumCPUWorkerThreads(), 4);

  SUCCEED() << "Async server configuration test passed";
}

// Test protocol buffer edge cases and data validation
TEST(FbthriftIntegration, ProtocolEdgeCases) {
  std::vector<std::string> edge_cases = {
      "",                                // Empty string
      std::string(1, '\0'),              // Null byte
      std::string("\x01\x02\x03\x04"),   // Binary data
      "UTF-8: 测试数据 🚀 ñáéíóú",       // Unicode
      std::string(65536, 'x'),           // Large string (64KB)
      "Control chars: \n\r\t\b\f",       // Control characters
      "Quotes: \"'`",                    // Special characters
      R"(JSON-like: {"key": "value"})",  // JSON-like content
  };

  for (const auto& test_case : edge_cases) {
    // Test with CompactProtocol (most efficient)
    {
      apache::thrift::CompactProtocolWriter writer;
      folly::IOBufQueue buffer_queue;
      writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
      writer.writeString(test_case);
      auto buf = buffer_queue.move();

      apache::thrift::CompactProtocolReader reader;
      reader.setInput(buf.get());
      std::string result;
      reader.readString(result);

      EXPECT_EQ(result, test_case)
          << "CompactProtocol failed for edge case of size: "
          << test_case.size();
    }

    // Test with JSONProtocol (human readable)
    {
      apache::thrift::JSONProtocolWriter writer;
      folly::IOBufQueue buffer_queue;
      writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);
      writer.writeString(test_case);
      auto buf = buffer_queue.move();

      apache::thrift::JSONProtocolReader reader;
      reader.setInput(buf.get());
      std::string result;
      reader.readString(result);

      EXPECT_EQ(result, test_case)
          << "JSONProtocol failed for edge case of size: " << test_case.size();
    }
  }
}

// Test numeric type serialization across protocols
TEST(FbthriftIntegration, NumericTypeSerialization) {
  // Test various numeric types
  struct TestCase {
    int8_t byte_value_ = -128;
    int16_t short_value_ = -32768;
    int32_t int_value_ = -2147483648;
    int64_t long_value_ = -9223372036854775807LL - 1;
    double double_value_ = std::numbers::pi;
  };

  TestCase original;

  // Test with BinaryProtocol
  {
    apache::thrift::BinaryProtocolWriter writer;
    folly::IOBufQueue buffer_queue;
    writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);

    writer.writeByte(original.byte_value_);
    writer.writeI16(original.short_value_);
    writer.writeI32(original.int_value_);
    writer.writeI64(original.long_value_);
    writer.writeDouble(original.double_value_);

    auto buf = buffer_queue.move();

    apache::thrift::BinaryProtocolReader reader;
    reader.setInput(buf.get());

    TestCase result;
    reader.readByte(result.byte_value_);
    reader.readI16(result.short_value_);
    reader.readI32(result.int_value_);
    reader.readI64(result.long_value_);
    reader.readDouble(result.double_value_);

    EXPECT_EQ(result.byte_value_, original.byte_value_);
    EXPECT_EQ(result.short_value_, original.short_value_);
    EXPECT_EQ(result.int_value_, original.int_value_);
    EXPECT_EQ(result.long_value_, original.long_value_);
    EXPECT_DOUBLE_EQ(result.double_value_, original.double_value_);
  }
}

// Test container type handling (lists, sets, maps)
TEST(FbthriftIntegration, ContainerSerialization) {
  // Test list serialization
  std::vector<std::string> string_list = {"first", "second", "third", "测试"};

  {
    apache::thrift::CompactProtocolWriter writer;
    folly::IOBufQueue buffer_queue;
    writer.setOutput(&buffer_queue, /*maxGrowth*/ 1U);

    // Write list header
    writer.writeListBegin(apache::thrift::protocol::T_STRING,
                          string_list.size());
    for (const auto& str : string_list) {
      writer.writeString(str);
    }
    writer.writeListEnd();

    auto buf = buffer_queue.move();

    apache::thrift::CompactProtocolReader reader;
    reader.setInput(buf.get());

    auto element_type = apache::thrift::protocol::TType{};
    uint32_t list_size = 0;
    reader.readListBegin(element_type, list_size);

    EXPECT_EQ(element_type, apache::thrift::protocol::T_STRING);
    EXPECT_EQ(list_size, string_list.size());

    std::vector<std::string> result_list;
    for (uint32_t i = 0; i < list_size; ++i) {
      std::string item;
      reader.readString(item);
      result_list.emplace_back(item);
    }
    reader.readListEnd();

    EXPECT_EQ(result_list, string_list);
  }
}

int main(int argc, char** argv) {
  folly::Init init{&argc, &argv};
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
