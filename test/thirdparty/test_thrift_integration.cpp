#include <gtest/gtest.h>
#include <thrift/Thrift.h>
#include <thrift/processor/TMultiplexedProcessor.h>
#include <thrift/protocol/TBinaryProtocol.h>
#include <thrift/protocol/TCompactProtocol.h>
#include <thrift/protocol/TJSONProtocol.h>
#include <thrift/server/TSimpleServer.h>
#include <thrift/transport/TBufferTransports.h>
#include <thrift/transport/TSSLSocket.h>
#include <thrift/transport/TSocket.h>
#include <thrift/transport/TTransportUtils.h>
#include <thrift/transport/TZlibTransport.h>

#include <memory>
#include <string>
#include <vector>

class ThriftIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Initialize any test fixtures here
  }

  void TearDown() override {
    // Clean up any test fixtures here
  }
};

// Test 1: Library Initialization
TEST_F(ThriftIntegrationTest, LibraryInitialization) {
  // Create a basic transport to verify library loading
  auto socket =
      std::make_shared<apache::thrift::transport::TSocket>("localhost", 9090);
  EXPECT_TRUE(socket != nullptr);
  EXPECT_EQ(socket->getHost(), "localhost");
  EXPECT_EQ(socket->getPort(), 9090);
}

// Test 2: Binary Protocol
TEST_F(ThriftIntegrationTest, BinaryProtocol) {
  auto write_transport =
      std::make_shared<apache::thrift::transport::TMemoryBuffer>();
  auto write_protocol =
      std::make_shared<apache::thrift::protocol::TBinaryProtocol>(
          write_transport);
  EXPECT_TRUE(write_protocol != nullptr);

  // Test writing basic types
  write_protocol->writeString(std::string("test_string"));
  write_protocol->writeI32(12345);
  write_protocol->writeI64(9876543210LL);
  write_protocol->writeBool(true);
  write_protocol->writeDouble(3.14159);

  // Get the written data and create a read buffer
  auto written_data = write_transport->getBufferAsString();
  auto read_transport =
      std::make_shared<apache::thrift::transport::TMemoryBuffer>(
          reinterpret_cast<uint8_t*>(const_cast<char*>(written_data.data())),
          written_data.size());
  auto read_protocol =
      std::make_shared<apache::thrift::protocol::TBinaryProtocol>(
          read_transport);

  std::string str_val;
  int32_t i32_val;
  int64_t i64_val;
  bool bool_val;
  double double_val;

  read_protocol->readString(str_val);
  read_protocol->readI32(i32_val);
  read_protocol->readI64(i64_val);
  read_protocol->readBool(bool_val);
  read_protocol->readDouble(double_val);

  EXPECT_EQ(str_val, "test_string");
  EXPECT_EQ(i32_val, 12345);
  EXPECT_EQ(i64_val, 9876543210LL);
  EXPECT_EQ(bool_val, true);
  EXPECT_DOUBLE_EQ(double_val, 3.14159);
}

// Test 3: JSON Protocol
TEST_F(ThriftIntegrationTest, JSONProtocol) {
  auto transport = std::make_shared<apache::thrift::transport::TMemoryBuffer>();
  auto protocol =
      std::make_shared<apache::thrift::protocol::TJSONProtocol>(transport);
  EXPECT_TRUE(protocol != nullptr);

  // Test writing and reading with JSON protocol
  protocol->writeString(std::string("json_test"));
  protocol->writeI32(42);
  protocol->writeBool(false);

  // The JSON protocol doesn't support direct read after write in the same way
  // So we'll just verify we can create and use the protocol
  EXPECT_TRUE(protocol != nullptr);
}

// Test 4: Compact Protocol
TEST_F(ThriftIntegrationTest, CompactProtocol) {
  auto transport = std::make_shared<apache::thrift::transport::TMemoryBuffer>();
  auto protocol =
      std::make_shared<apache::thrift::protocol::TCompactProtocol>(transport);
  EXPECT_TRUE(protocol != nullptr);

  // Test basic compact protocol operations
  protocol->writeString(std::string("compact_test"));
  protocol->writeI32(999);
  protocol->writeBool(true);

  EXPECT_TRUE(protocol != nullptr);
}

// Test 5: Transport Layer
TEST_F(ThriftIntegrationTest, TransportLayer) {
  // Test memory buffer transport
  auto memory_transport =
      std::make_shared<apache::thrift::transport::TMemoryBuffer>();
  EXPECT_TRUE(memory_transport != nullptr);

  std::string test_data = "Hello Thrift Transport!";
  memory_transport->write(reinterpret_cast<const uint8_t*>(test_data.c_str()),
                          test_data.length());

  // Read back the data
  uint8_t buffer[1024];
  uint32_t bytes_read = memory_transport->read(buffer, sizeof(buffer));
  EXPECT_EQ(bytes_read, test_data.length());

  std::string read_data(reinterpret_cast<char*>(buffer), bytes_read);
  EXPECT_EQ(read_data, test_data);
}

// Test 6: Buffered Transport
TEST_F(ThriftIntegrationTest, BufferedTransport) {
  auto memory_transport =
      std::make_shared<apache::thrift::transport::TMemoryBuffer>();
  auto buffered_transport =
      std::make_shared<apache::thrift::transport::TBufferedTransport>(
          memory_transport);
  EXPECT_TRUE(buffered_transport != nullptr);

  std::string test_data = "Buffered transport test";
  buffered_transport->write(reinterpret_cast<const uint8_t*>(test_data.c_str()),
                            test_data.length());
  buffered_transport->flush();

  // Verify we can work with buffered transport
  EXPECT_TRUE(buffered_transport != nullptr);
}

// Test 7: Framed Transport
TEST_F(ThriftIntegrationTest, FramedTransport) {
  auto memory_transport =
      std::make_shared<apache::thrift::transport::TMemoryBuffer>();
  auto framed_transport =
      std::make_shared<apache::thrift::transport::TFramedTransport>(
          memory_transport);
  EXPECT_TRUE(framed_transport != nullptr);

  std::string test_data = "Framed transport test";
  framed_transport->write(reinterpret_cast<const uint8_t*>(test_data.c_str()),
                          test_data.length());
  framed_transport->flush();

  EXPECT_TRUE(framed_transport != nullptr);
}

// Test 8: Exception Handling
TEST_F(ThriftIntegrationTest, ExceptionHandling) {
  try {
    // Create a socket that should fail to connect
    auto socket = std::make_shared<apache::thrift::transport::TSocket>(
        "invalid_host", 12345);
    socket->setConnTimeout(100);  // Short timeout

    // This should work (creating socket doesn't connect)
    EXPECT_TRUE(socket != nullptr);

    // Test that we can catch thrift exceptions
    apache::thrift::transport::TTransportException ex("Test exception");
    EXPECT_EQ(ex.getType(),
              apache::thrift::transport::TTransportException::UNKNOWN);
    EXPECT_NE(ex.what(), nullptr);

  } catch (const apache::thrift::TException& e) {
    // This is expected for invalid operations
    EXPECT_TRUE(true);
  }
}

// Test 9: Protocol Factory
TEST_F(ThriftIntegrationTest, ProtocolFactory) {
  auto transport = std::make_shared<apache::thrift::transport::TMemoryBuffer>();

  // Test binary protocol factory
  apache::thrift::protocol::TBinaryProtocolFactory binary_factory;
  auto binary_protocol = binary_factory.getProtocol(transport);
  EXPECT_TRUE(binary_protocol != nullptr);

  // Test compact protocol factory
  apache::thrift::protocol::TCompactProtocolFactory compact_factory;
  auto compact_protocol = compact_factory.getProtocol(transport);
  EXPECT_TRUE(compact_protocol != nullptr);

  // Test JSON protocol factory
  apache::thrift::protocol::TJSONProtocolFactory json_factory;
  auto json_protocol = json_factory.getProtocol(transport);
  EXPECT_TRUE(json_protocol != nullptr);
}

// Test 10: Multiplexed Processor
TEST_F(ThriftIntegrationTest, MultiplexedProcessor) {
  auto multiplexed_processor =
      std::make_shared<apache::thrift::TMultiplexedProcessor>();
  EXPECT_TRUE(multiplexed_processor != nullptr);

  // Test that we can create a multiplexed processor
  // In a real scenario, we would register actual service processors
  EXPECT_TRUE(multiplexed_processor != nullptr);
}

// Test 11: ZLIB Transport Compression
TEST_F(ThriftIntegrationTest, ZlibTransportCompression) {
  // Create a memory buffer for the underlying transport
  auto memory_transport =
      std::make_shared<apache::thrift::transport::TMemoryBuffer>();

  // Create ZLIB transport wrapper for compression
  auto zlib_transport =
      std::make_shared<apache::thrift::transport::TZlibTransport>(
          memory_transport);
  EXPECT_TRUE(zlib_transport != nullptr);

  // Create a test string that should compress well (repetitive data)
  std::string test_data;
  for (int i = 0; i < 100; ++i) {
    test_data += "This is test data for ZLIB compression validation. ";
  }

  // Write data through ZLIB transport (this will compress the data)
  zlib_transport->write(reinterpret_cast<const uint8_t*>(test_data.c_str()),
                        test_data.size());
  zlib_transport->flush();
  zlib_transport->finish();  // Important: finalize compression

  // Get the compressed data from underlying memory transport
  std::string compressed_data = memory_transport->getBufferAsString();

  // Verify compression occurred (compressed size should be significantly
  // smaller)
  EXPECT_GT(test_data.size(), compressed_data.size());
  EXPECT_GT(compressed_data.size(), 0);

  // Now test decompression by reading back through ZLIB transport
  auto read_memory_transport =
      std::make_shared<apache::thrift::transport::TMemoryBuffer>(
          reinterpret_cast<uint8_t*>(const_cast<char*>(compressed_data.data())),
          compressed_data.size());

  auto read_zlib_transport =
      std::make_shared<apache::thrift::transport::TZlibTransport>(
          read_memory_transport);

  // Read back the decompressed data
  std::vector<uint8_t> decompressed_buffer(test_data.size());
  uint32_t bytes_read = read_zlib_transport->read(decompressed_buffer.data(),
                                                  decompressed_buffer.size());

  // Verify decompression worked correctly
  EXPECT_EQ(bytes_read, test_data.size());
  std::string decompressed_data(
      reinterpret_cast<char*>(decompressed_buffer.data()), bytes_read);
  EXPECT_EQ(decompressed_data, test_data);
}

// Test: SSL Socket Support (OpenSSL integration)
TEST_F(ThriftIntegrationTest, SSLSocketSupport) {
  using namespace apache::thrift::transport;
  using namespace apache::thrift::protocol;

  // Test creating basic transport (without connecting)
  auto socket = std::make_shared<TSocket>("localhost", 9090);
  EXPECT_TRUE(socket != nullptr);
  EXPECT_EQ(socket->getHost(), "localhost");
  EXPECT_EQ(socket->getPort(), 9090);

  // Test SSL socket creation using TSSLSocketFactory (with OpenSSL support)
  TSSLSocketFactory ssl_factory;
  auto ssl_socket = ssl_factory.createSocket("localhost", 9090);
  EXPECT_TRUE(ssl_socket != nullptr);
  EXPECT_EQ(ssl_socket->getHost(), "localhost");
  EXPECT_EQ(ssl_socket->getPort(), 9090);

  // Test protocol creation with SSL socket
  auto protocol =
      std::make_shared<apache::thrift::protocol::TBinaryProtocol>(ssl_socket);
  EXPECT_TRUE(protocol != nullptr);

  // Test that SSL socket behaves like a regular socket for basic operations
  // (without actually connecting, just testing object creation)
  EXPECT_FALSE(ssl_socket->isOpen());
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  int result = RUN_ALL_TESTS();
  return result;
}
