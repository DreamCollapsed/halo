#include <google/protobuf/arena.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/message.h>
#include <google/protobuf/message_lite.h>
#include <google/protobuf/text_format.h>
#include <google/protobuf/util/json_util.h>
#include <google/protobuf/util/message_differencer.h>
#include <gtest/gtest.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <memory>
#include <string>

class ProtobufIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Setup code if needed
    test_dir_ = std::filesystem::temp_directory_path() / "protobuf_test";
    std::filesystem::create_directories(test_dir_);

#ifdef PROTOC_EXECUTABLE_PATH
    protoc_path_ = PROTOC_EXECUTABLE_PATH;
#endif
  }

  void TearDown() override {
    // Cleanup code if needed
    std::filesystem::remove_all(test_dir_);
  }

  [[nodiscard]] const std::filesystem::path& GetTestDir() const {
    return test_dir_;
  }

  [[nodiscard]] const std::string& GetProtocPath() const {
    return protoc_path_;
  }

 private:
  std::filesystem::path test_dir_;
  std::string protoc_path_;
};

// Test basic protobuf library initialization
TEST_F(ProtobufIntegrationTest, LibraryInitialization) {
  // Check that protobuf version info is available
  EXPECT_GT(GOOGLE_PROTOBUF_VERSION, 0);
  // In newer protobuf versions, GetVersionString() may not be available
  // Instead, we can test that the version constant is defined properly
  std::cout << "Protobuf version: " << GOOGLE_PROTOBUF_VERSION << "\n";
}

// Test basic descriptor functionality
TEST_F(ProtobufIntegrationTest, DescriptorFunctionality) {
  // Get the descriptor for FileDescriptorProto (built-in message type)
  const google::protobuf::Descriptor* descriptor =
      google::protobuf::FileDescriptorProto::descriptor();

  ASSERT_NE(descriptor, nullptr);
  EXPECT_EQ(descriptor->name(), "FileDescriptorProto");
  EXPECT_GT(descriptor->field_count(), 0);

  // Check some known fields
  const google::protobuf::FieldDescriptor* name_field =
      descriptor->FindFieldByName("name");
  ASSERT_NE(name_field, nullptr);
  EXPECT_EQ(name_field->type(), google::protobuf::FieldDescriptor::TYPE_STRING);
}

// Test dynamic message creation
TEST_F(ProtobufIntegrationTest, DynamicMessageCreation) {
  // Use FileDescriptorProto as our test message type
  const google::protobuf::Descriptor* descriptor =
      google::protobuf::FileDescriptorProto::descriptor();

  google::protobuf::DynamicMessageFactory factory;
  std::unique_ptr<google::protobuf::Message> message(
      factory.GetPrototype(descriptor)->New());

  ASSERT_NE(message, nullptr);
  EXPECT_EQ(message->GetDescriptor(), descriptor);

  // Test setting a field
  const google::protobuf::FieldDescriptor* name_field =
      descriptor->FindFieldByName("name");
  const google::protobuf::Reflection* reflection = message->GetReflection();

  reflection->SetString(message.get(), name_field, "test_file.proto");
  EXPECT_EQ(reflection->GetString(*message, name_field), "test_file.proto");
}

// Test message serialization and deserialization
TEST_F(ProtobufIntegrationTest, MessageSerialization) {
  // Create a FileDescriptorProto message
  google::protobuf::FileDescriptorProto file_desc;
  file_desc.set_name("test.proto");
  file_desc.set_package("test.package");
  file_desc.set_syntax("proto3");

  // Serialize to binary
  std::string binary_data;
  EXPECT_TRUE(file_desc.SerializeToString(&binary_data));
  EXPECT_FALSE(binary_data.empty());

  // Deserialize from binary
  google::protobuf::FileDescriptorProto parsed_desc;
  EXPECT_TRUE(parsed_desc.ParseFromString(binary_data));

  // Verify deserialized data
  EXPECT_EQ(parsed_desc.name(), "test.proto");
  EXPECT_EQ(parsed_desc.package(), "test.package");
  EXPECT_EQ(parsed_desc.syntax(), "proto3");
}

// Test text format functionality
TEST_F(ProtobufIntegrationTest, TextFormatSerialization) {
  // Create a FileDescriptorProto message
  google::protobuf::FileDescriptorProto file_desc;
  file_desc.set_name("test.proto");
  file_desc.set_package("test.package");

  // Serialize to text format
  std::string text_data;
  google::protobuf::TextFormat::PrintToString(file_desc, &text_data);
  EXPECT_FALSE(text_data.empty());
  EXPECT_NE(text_data.find("name: \"test.proto\""), std::string::npos);
  EXPECT_NE(text_data.find("package: \"test.package\""), std::string::npos);

  // Parse from text format
  google::protobuf::FileDescriptorProto parsed_desc;
  EXPECT_TRUE(
      google::protobuf::TextFormat::ParseFromString(text_data, &parsed_desc));

  // Verify parsed data
  EXPECT_EQ(parsed_desc.name(), "test.proto");
  EXPECT_EQ(parsed_desc.package(), "test.package");
}

// Test JSON format functionality
TEST_F(ProtobufIntegrationTest, JsonFormatSerialization) {
  // Create a FileDescriptorProto message
  google::protobuf::FileDescriptorProto file_desc;
  file_desc.set_name("test.proto");
  file_desc.set_package("test.package");

  // Serialize to JSON
  std::string json_data;
  google::protobuf::util::JsonPrintOptions options;
  options.add_whitespace = true;
  // Note: always_print_primitive_fields may not be available in all versions
  // options.always_print_primitive_fields = true;

  auto status = google::protobuf::util::MessageToJsonString(
      file_desc, &json_data, options);
  EXPECT_TRUE(status.ok()) << "JSON serialization failed: " << status.message();
  EXPECT_FALSE(json_data.empty());

  // Parse from JSON
  google::protobuf::FileDescriptorProto parsed_desc;
  status = google::protobuf::util::JsonStringToMessage(json_data, &parsed_desc);
  EXPECT_TRUE(status.ok()) << "JSON parsing failed: " << status.message();

  // Verify parsed data
  EXPECT_EQ(parsed_desc.name(), "test.proto");
  EXPECT_EQ(parsed_desc.package(), "test.package");
}

// Test message comparison functionality
TEST_F(ProtobufIntegrationTest, MessageComparison) {
  // Create two identical messages
  google::protobuf::FileDescriptorProto file_desc1;
  file_desc1.set_name("test.proto");
  file_desc1.set_package("test.package");

  google::protobuf::FileDescriptorProto file_desc2;
  file_desc2.set_name("test.proto");
  file_desc2.set_package("test.package");

  // Test equality using MessageDifferencer
  google::protobuf::util::MessageDifferencer differencer;
  EXPECT_TRUE(differencer.Compare(file_desc1, file_desc2));

  // Modify one message and test inequality
  file_desc2.set_name("different.proto");
  EXPECT_FALSE(differencer.Compare(file_desc1, file_desc2));
}

// Test arena allocation for performance
TEST_F(ProtobufIntegrationTest, ArenaAllocation) {
  google::protobuf::Arena arena;

  // Allocate message on arena - use the correct API for protobuf v31
  auto* file_desc =
      google::protobuf::Arena::Create<google::protobuf::FileDescriptorProto>(
          &arena);
  ASSERT_NE(file_desc, nullptr);

  // Set some data
  file_desc->set_name("arena_test.proto");
  file_desc->set_package("arena.test");

  // Verify data
  EXPECT_EQ(file_desc->name(), "arena_test.proto");
  EXPECT_EQ(file_desc->package(), "arena.test");

  // Arena automatically cleans up when it goes out of scope
}

// Test protobuf lite functionality (if available)
TEST_F(ProtobufIntegrationTest, ProtobufLiteFunctionality) {
  // FileDescriptorProto is not a lite message, but we can test basic lite
  // functionality by checking that the lite runtime works

  // This test mainly verifies that protobuf-lite headers compile and link
  // correctly In a real scenario, you'd test with actual lite messages

  // Test that we can access lite-specific functionality
  google::protobuf::FileDescriptorProto message;
  message.set_name("test.proto");  // Add some content so size > 0
  EXPECT_GT(message.ByteSizeLong(),
            0);  // This method is available in both full and lite

  // Test lite serialization methods
  std::string serialized;
  EXPECT_TRUE(message.SerializeToString(&serialized));

  google::protobuf::FileDescriptorProto parsed;
  EXPECT_TRUE(parsed.ParseFromString(serialized));
  EXPECT_EQ(parsed.name(), "test.proto");
}

// Test reflection capabilities
TEST_F(ProtobufIntegrationTest, ReflectionCapabilities) {
  google::protobuf::FileDescriptorProto file_desc;
  const google::protobuf::Reflection* reflection =
      google::protobuf::FileDescriptorProto::GetReflection();
  const google::protobuf::Descriptor* descriptor =
      google::protobuf::FileDescriptorProto::descriptor();

  ASSERT_NE(reflection, nullptr);
  ASSERT_NE(descriptor, nullptr);

  // Test field enumeration
  std::vector<const google::protobuf::FieldDescriptor*> fields;
  reflection->ListFields(file_desc, &fields);
  EXPECT_GE(fields.size(),
            0);  // Should be 0 for empty message, but method should work

  // Test getting/setting fields dynamically
  const google::protobuf::FieldDescriptor* name_field =
      descriptor->FindFieldByName("name");
  ASSERT_NE(name_field, nullptr);

  reflection->SetString(&file_desc, name_field, "reflection_test.proto");
  EXPECT_EQ(reflection->GetString(file_desc, name_field),
            "reflection_test.proto");

  // Test field presence
  EXPECT_TRUE(reflection->HasField(file_desc, name_field));
  reflection->ClearField(&file_desc, name_field);
  EXPECT_FALSE(reflection->HasField(file_desc, name_field));
}

// Test protoc executable availability and version
TEST_F(ProtobufIntegrationTest, ProtocVersionTest) {
  ASSERT_FALSE(GetProtocPath().empty())
      << "protoc executable path must be configured";

  ASSERT_TRUE(std::filesystem::exists(GetProtocPath()))
      << "protoc executable must exist at: " << GetProtocPath();
  // Test that protoc executable is available
  std::string version_command = GetProtocPath() + " --version > /dev/null 2>&1";
  int result = std::system(version_command.c_str());
  EXPECT_EQ(result, 0) << "protoc executable should be available";

  // Test that we can get version information
  std::string popen_command = GetProtocPath() + " --version 2>/dev/null";
  FILE* pipe = popen(popen_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  std::array<char, 256> buffer{};
  std::string version_output;
  while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) !=
         nullptr) {
    version_output += buffer.data();
  }
  pclose(pipe);

  // Check that version contains protobuf information
  EXPECT_TRUE(version_output.find("libprotoc") != std::string::npos)
      << "Version output: " << version_output;
}

// Test protoc help output
TEST_F(ProtobufIntegrationTest, ProtocHelpTest) {
  ASSERT_FALSE(GetProtocPath().empty())
      << "protoc executable path must be configured";

  ASSERT_TRUE(std::filesystem::exists(GetProtocPath()))
      << "protoc executable must exist at: " << GetProtocPath();
  // Test that protoc shows help when called with --help
  std::string help_command = GetProtocPath() + " --help > /dev/null 2>&1";
  int result = std::system(help_command.c_str());
  EXPECT_EQ(result, 0) << "protoc --help should work";

  // Capture help output
  std::string popen_help_command = GetProtocPath() + " --help 2>/dev/null";
  FILE* pipe = popen(popen_help_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  std::array<char, 1024> buffer{};
  std::string help_output;
  while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) !=
         nullptr) {
    help_output += buffer.data();
  }
  pclose(pipe);

  // Check that help output contains expected content
  EXPECT_TRUE(help_output.find("Usage:") != std::string::npos ||
              help_output.find("usage:") != std::string::npos)
      << "Help should contain usage information";

  EXPECT_TRUE(help_output.find("cpp_out") != std::string::npos)
      << "Help should mention C++ output option";
}

// Test basic proto file compilation
TEST_F(ProtobufIntegrationTest, BasicProtoCompilationTest) {
  ASSERT_FALSE(GetProtocPath().empty())
      << "protoc executable path must be configured";

  ASSERT_TRUE(std::filesystem::exists(GetProtocPath()))
      << "protoc executable must exist at: " << GetProtocPath();
  // Create a simple .proto file
  std::filesystem::path proto_file = GetTestDir() / "test.proto";
  std::ofstream file(proto_file);
  file << R"(
syntax = "proto3";

package test;

message TestMessage {
  string name = 1;
  int32 id = 2;
  repeated string tags = 3;
}

service TestService {
  rpc GetTest(TestMessage) returns (TestMessage);
}
)";
  file.close();

  ASSERT_TRUE(std::filesystem::exists(proto_file))
      << "Test proto file should exist";

  // Test that protoc can compile the proto without errors
  std::string command = GetProtocPath() +
                        " --cpp_out=" + GetTestDir().string() +
                        " --proto_path=" + GetTestDir().string() + " " +
                        proto_file.filename().string() + " 2>&1";

  FILE* pipe = popen(command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  std::array<char, 256> buffer{};
  std::string output;
  while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) !=
         nullptr) {
    output += buffer.data();
  }
  int result = pclose(pipe);

  // Check that protoc completed successfully
  EXPECT_EQ(result, 0) << "protoc should compile proto successfully. Output: "
                       << output;

  // Check that output files were generated
  EXPECT_TRUE(std::filesystem::exists(GetTestDir() / "test.pb.h"))
      << "protoc should generate header file";
  EXPECT_TRUE(std::filesystem::exists(GetTestDir() / "test.pb.cc"))
      << "protoc should generate source file";
}
