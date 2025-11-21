#include <gflags/gflags.h>
#include <gtest/gtest.h>

#include <chrono>
#include <numbers>
#include <string>
#include <vector>

// Define some command line flags for testing
DEFINE_string(test_string, "default_value", "Test string flag");
DEFINE_int32(test_int, 42, "Test integer flag");
DEFINE_bool(test_bool, false, "Test boolean flag");
DEFINE_double(test_double, 3.14, "Test double flag");

// Test fixture for gflags integration tests
class GflagsIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Reset flags to default values before each test
    FLAGS_test_string = "default_value";
    FLAGS_test_int = 42;
    FLAGS_test_bool = false;
    FLAGS_test_double = 3.14;
  }

  void TearDown() override {
    // Clean up any changes to global flag state
    gflags::FlagSaver flag_saver;
  }

  // Helper method to parse command line arguments
  static void ParseArgs(const std::vector<std::string>& args) {
    // Create mutable copies of strings
    std::vector<std::string> mutable_args;
    mutable_args.reserve(args.size() + 1);
    mutable_args.emplace_back("test_program");
    mutable_args.insert(mutable_args.end(), args.begin(), args.end());

    std::vector<char*> argv;
    argv.reserve(mutable_args.size());
    for (auto& arg : mutable_args) {
      argv.push_back(arg.data());
    }

    int argc = static_cast<int>(argv.size());
    char** argv_ptr = argv.data();
    gflags::ParseCommandLineFlags(&argc, &argv_ptr, true);
  }
};

// Test basic flag definitions and default values
TEST_F(GflagsIntegrationTest, DefaultValues) {
  // Test that flags have their default values
  EXPECT_EQ(FLAGS_test_string, "default_value");
  EXPECT_EQ(FLAGS_test_int, 42);
  EXPECT_FALSE(FLAGS_test_bool);
  EXPECT_DOUBLE_EQ(FLAGS_test_double, 3.14);
}

// Test string flag parsing
TEST_F(GflagsIntegrationTest, StringFlagParsing) {
  // Test parsing string flag
  ParseArgs({"--test_string=hello_world"});
  EXPECT_EQ(FLAGS_test_string, "hello_world");

  // Test string with spaces (should work with quotes in real usage)
  ParseArgs({"--test_string=hello world"});
  EXPECT_EQ(FLAGS_test_string, "hello world");

  // Test empty string
  ParseArgs({"--test_string="});
  EXPECT_EQ(FLAGS_test_string, "");
}

// Test integer flag parsing
TEST_F(GflagsIntegrationTest, IntegerFlagParsing) {
  // Test positive integer
  ParseArgs({"--test_int=100"});
  EXPECT_EQ(FLAGS_test_int, 100);

  // Test negative integer
  ParseArgs({"--test_int=-50"});
  EXPECT_EQ(FLAGS_test_int, -50);

  // Test zero
  ParseArgs({"--test_int=0"});
  EXPECT_EQ(FLAGS_test_int, 0);
}

// Test boolean flag parsing
TEST_F(GflagsIntegrationTest, BooleanFlagParsing) {
  // Test true value
  ParseArgs({"--test_bool=true"});
  EXPECT_TRUE(FLAGS_test_bool);

  // Test false value
  ParseArgs({"--test_bool=false"});
  EXPECT_FALSE(FLAGS_test_bool);

  // Test flag without value (should set to true)
  ParseArgs({"--test_bool"});
  EXPECT_TRUE(FLAGS_test_bool);

  // Test negated flag
  ParseArgs({"--notest_bool"});
  EXPECT_FALSE(FLAGS_test_bool);
}

// Test double flag parsing
TEST_F(GflagsIntegrationTest, DoubleFlagParsing) {
  // Test positive double
  ParseArgs({"--test_double=2.718"});
  EXPECT_DOUBLE_EQ(FLAGS_test_double, 2.718);

  // Test negative double
  ParseArgs({"--test_double=-1.414"});
  EXPECT_DOUBLE_EQ(FLAGS_test_double, -1.414);

  // Test scientific notation
  ParseArgs({"--test_double=1.23e-4"});
  EXPECT_DOUBLE_EQ(FLAGS_test_double, 1.23e-4);
}

// Test multiple flags parsing
TEST_F(GflagsIntegrationTest, MultipleFlagsParsing) {
  ParseArgs({"--test_string=multi_test", "--test_int=999", "--test_bool=true",
             "--test_double=9.99"});

  EXPECT_EQ(FLAGS_test_string, "multi_test");
  EXPECT_EQ(FLAGS_test_int, 999);
  EXPECT_TRUE(FLAGS_test_bool);
  EXPECT_DOUBLE_EQ(FLAGS_test_double, 9.99);
}

// Test flag validation
TEST_F(GflagsIntegrationTest, FlagValidation) {
  // Test that gflags provides access to flag information
  gflags::CommandLineFlagInfo flag_info;

  // Test getting flag info for string flag
  EXPECT_TRUE(gflags::GetCommandLineFlagInfo("test_string", &flag_info));
  EXPECT_EQ(flag_info.name, "test_string");
  EXPECT_EQ(flag_info.type, "string");
  EXPECT_EQ(flag_info.default_value, "default_value");
  EXPECT_EQ(flag_info.current_value, "default_value");

  // Test getting flag info for int flag
  EXPECT_TRUE(gflags::GetCommandLineFlagInfo("test_int", &flag_info));
  EXPECT_EQ(flag_info.name, "test_int");
  EXPECT_EQ(flag_info.type, "int32");
  EXPECT_EQ(flag_info.default_value, "42");
}

// Test flag listing
TEST_F(GflagsIntegrationTest, FlagListing) {
  std::vector<gflags::CommandLineFlagInfo> all_flags;
  gflags::GetAllFlags(&all_flags);

  // Should have at least our test flags
  EXPECT_GE(all_flags.size(), 4);

  // Check that our flags are in the list
  bool found_test_string = false;
  bool found_test_int = false;
  bool found_test_bool = false;
  bool found_test_double = false;

  for (const auto& flag : all_flags) {
    if (flag.name == "test_string") {
      found_test_string = true;
    }
    if (flag.name == "test_int") {
      found_test_int = true;
    }
    if (flag.name == "test_bool") {
      found_test_bool = true;
    }
    if (flag.name == "test_double") {
      found_test_double = true;
    }
  }

  EXPECT_TRUE(found_test_string);
  EXPECT_TRUE(found_test_int);
  EXPECT_TRUE(found_test_bool);
  EXPECT_TRUE(found_test_double);
}

// Test programmatic flag setting
TEST_F(GflagsIntegrationTest, ProgrammaticFlagSetting) {
  // Test setting flags programmatically
  std::string result =
      gflags::SetCommandLineOption("test_string", "programmatic_value");
  EXPECT_FALSE(result.empty());
  EXPECT_EQ(FLAGS_test_string, "programmatic_value");

  result = gflags::SetCommandLineOption("test_int", "777");
  EXPECT_FALSE(result.empty());
  EXPECT_EQ(FLAGS_test_int, 777);

  result = gflags::SetCommandLineOption("test_bool", "true");
  EXPECT_FALSE(result.empty());
  EXPECT_TRUE(FLAGS_test_bool);

  result = gflags::SetCommandLineOption("test_double", "1.618");
  EXPECT_FALSE(result.empty());
  EXPECT_DOUBLE_EQ(FLAGS_test_double, 1.618);
}

// Test flag saver functionality
TEST_F(GflagsIntegrationTest, FlagSaver) {
  // Save current flag state
  gflags::FlagSaver flag_saver;

  // Modify flags
  FLAGS_test_string = "modified";
  FLAGS_test_int = 999;
  FLAGS_test_bool = true;
  FLAGS_test_double = std::numbers::e;

  // Verify modifications
  EXPECT_EQ(FLAGS_test_string, "modified");
  EXPECT_EQ(FLAGS_test_int, 999);
  EXPECT_TRUE(FLAGS_test_bool);
  EXPECT_DOUBLE_EQ(FLAGS_test_double, std::numbers::e);

  // FlagSaver destructor should restore original values when it goes out of
  // scope
  {
    gflags::FlagSaver local_saver;
    FLAGS_test_string = "temporary";
  }

  // Flags should still be modified (only the local_saver restored)
  EXPECT_EQ(FLAGS_test_string, "modified");
}

// Performance test
TEST_F(GflagsIntegrationTest, PerformanceTest) {
  // Test that flag access is fast
  auto start = std::chrono::high_resolution_clock::now();

  std::string result;
  for (int i = 0; i < 10000; ++i) {
    result += FLAGS_test_string;
    if (FLAGS_test_int > 0) {
      result += std::to_string(FLAGS_test_int);
    }
    if (FLAGS_test_bool) {
      result += "true";
    }
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

  // Should complete in reasonable time (less than 100ms)
  EXPECT_LT(duration.count(), 100);
  EXPECT_FALSE(result.empty());  // Ensure the loop actually did something
}

// Integration test combining gflags with other functionality
TEST_F(GflagsIntegrationTest, IntegrationWithStdLibrary) {
  // Test that gflags works well with standard library containers
  std::vector<std::string> config_values;

  // Simulate reading configuration from flags
  config_values.push_back(FLAGS_test_string);
  config_values.push_back(std::to_string(FLAGS_test_int));
  config_values.emplace_back(FLAGS_test_bool ? "enabled" : "disabled");
  config_values.push_back(std::to_string(FLAGS_test_double));

  EXPECT_EQ(config_values.size(), 4);
  EXPECT_EQ(config_values[0], "default_value");
  EXPECT_EQ(config_values[1], "42");
  EXPECT_EQ(config_values[2], "disabled");
  EXPECT_DOUBLE_EQ(std::stod(config_values[3]), 3.14);

  // Test with modified flags
  ParseArgs({"--test_string=integration_test", "--test_int=123",
             "--test_bool=true", "--test_double=1.23"});

  config_values.clear();
  config_values.push_back(FLAGS_test_string);
  config_values.push_back(std::to_string(FLAGS_test_int));
  config_values.emplace_back(FLAGS_test_bool ? "enabled" : "disabled");
  config_values.push_back(std::to_string(FLAGS_test_double));

  EXPECT_EQ(config_values[0], "integration_test");
  EXPECT_EQ(config_values[1], "123");
  EXPECT_EQ(config_values[2], "enabled");
  EXPECT_DOUBLE_EQ(std::stod(config_values[3]), 1.23);
}

int main(int argc, char** argv) {
  // Initialize gflags
  gflags::ParseCommandLineFlags(&argc, &argv, true);

  // Initialize Google Test
  ::testing::InitGoogleTest(&argc, argv);

  int result = RUN_ALL_TESTS();

  // Clean up gflags
  gflags::ShutDownCommandLineFlags();

  return result;
}
