#include <gtest/gtest.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>

class FlexIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up test environment
    test_dir = std::filesystem::temp_directory_path() / "flex_test";
    std::filesystem::create_directories(test_dir);

    // Use CMake-provided flex executable path if available
#ifdef FLEX_EXECUTABLE_PATH
    flex_path = FLEX_EXECUTABLE_PATH;
#endif

    // Create a simple lexer file for testing
    lexer_file = test_dir / "test.l";
    createTestLexer();
  }

  void TearDown() override {
    // Clean up test files
    std::filesystem::remove_all(test_dir);
  }

  void createTestLexer() {
    std::ofstream file(lexer_file);
    file << R"FLEX(
%{
#include <stdio.h>
#include <stdlib.h>
int yylex(void);
%}

%option noinput
%option nounput

%%

[0-9]+          { printf("NUMBER: %s\n", yytext); return 1; }
[a-zA-Z_][a-zA-Z0-9_]*  { printf("IDENTIFIER: %s\n", yytext); return 2; }
"+"             { printf("PLUS\n"); return 3; }
"-"             { printf("MINUS\n"); return 4; }
"*"             { printf("TIMES\n"); return 5; }
"/"             { printf("DIVIDE\n"); return 6; }
"("             { printf("LPAREN\n"); return 7; }
")"             { printf("RPAREN\n"); return 8; }
[ \t]+          { /* skip whitespace */ }
\n              { printf("NEWLINE\n"); return 9; }
.               { printf("UNKNOWN: %s\n", yytext); return 10; }

%%

int yywrap(void) {
    return 1;
}

int main(void) {
    printf("Starting lexical analysis...\n");
    yylex();
    return 0;
}
)FLEX";
    file.close();
  }

  std::filesystem::path test_dir;
  std::filesystem::path lexer_file;
  std::string flex_path;
};

// Test flex executable availability and version
TEST_F(FlexIntegrationTest, FlexVersionTest) {
  // Test that flex executable is available
  std::string version_command = flex_path + " --version > /dev/null 2>&1";
  int result = std::system(version_command.c_str());
  EXPECT_EQ(result, 0) << "flex executable should be available";

  // Test that we can get version information
  std::string popen_command = flex_path + " --version 2>/dev/null";
  FILE* pipe = popen(popen_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string version_output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    version_output += buffer;
  }
  pclose(pipe);

  // Check that version contains expected version number (2.6.4)
  EXPECT_TRUE(version_output.find("2.6") != std::string::npos)
      << "Version output: " << version_output;
}

// Test flex help output
TEST_F(FlexIntegrationTest, FlexHelpTest) {
  // Test that flex shows help when called with --help
  std::string help_command = flex_path + " --help > /dev/null 2>&1";
  int result = std::system(help_command.c_str());
  EXPECT_EQ(result, 0) << "flex --help should work";

  // Capture help output
  std::string popen_help_command = flex_path + " --help 2>/dev/null";
  FILE* pipe = popen(popen_help_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string help_output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    help_output += buffer;
  }
  pclose(pipe);

  // Check that help output contains expected content
  EXPECT_TRUE(help_output.find("Usage:") != std::string::npos ||
              help_output.find("usage:") != std::string::npos)
      << "Help should contain usage information";

  EXPECT_TRUE(help_output.find("flex") != std::string::npos)
      << "Help should mention flex";
}

// Test basic lexer generation
TEST_F(FlexIntegrationTest, BasicLexerGenerationTest) {
  ASSERT_TRUE(std::filesystem::exists(lexer_file))
      << "Test lexer file should exist";

  // Test that flex can generate lexer without errors
  std::string command = flex_path +
                        " --outfile=" + (test_dir / "lex.yy.c").string() + " " +
                        lexer_file.string() + " 2>&1";

  FILE* pipe = popen(command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    output += buffer;
  }
  int result = pclose(pipe);

  // Check that flex completed successfully
  EXPECT_EQ(result, 0) << "Flex should generate lexer successfully. Output: "
                       << output;

  // Check that output file was generated
  EXPECT_TRUE(std::filesystem::exists(test_dir / "lex.yy.c"))
      << "Flex should generate C source file";
}

// Test flex with different output formats
TEST_F(FlexIntegrationTest, OutputFormatsTest) {
  ASSERT_TRUE(std::filesystem::exists(lexer_file))
      << "Test lexer file should exist";

  // Test header file generation
  std::string header_command =
      flex_path + " --header-file=" + (test_dir / "lex.yy.h").string() +
      " --outfile=" + (test_dir / "header_test.c").string() + " " +
      lexer_file.string() + " 2>&1";

  FILE* pipe = popen(header_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    output += buffer;
  }
  int result = pclose(pipe);

  EXPECT_EQ(result, 0) << "Flex header generation should work. Output: "
                       << output;

  // Check that header file was generated
  EXPECT_TRUE(std::filesystem::exists(test_dir / "lex.yy.h"))
      << "Flex should generate header file";
}

// Test flex error handling with invalid lexer
TEST_F(FlexIntegrationTest, ErrorHandlingTest) {
  // Create an invalid lexer file
  std::filesystem::path invalid_lexer = test_dir / "invalid.l";
  std::ofstream file(invalid_lexer);
  file << R"FLEX(
%{
#include <stdio.h>
%}

%%

[0-9]+          { printf("NUMBER: %s\n", yytext); return 1; }
INVALID_PATTERN { /* This pattern has syntax errors */
// Missing closing brace and action

%%

int yywrap(void) {
    return 1;
}
)FLEX";
  file.close();

  // Test that flex reports errors for invalid lexer
  std::string command = flex_path + " " + invalid_lexer.string() + " 2>&1";

  FILE* pipe = popen(command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    output += buffer;
  }
  int result = pclose(pipe);

  // Flex should return non-zero exit code for invalid lexer
  EXPECT_NE(result, 0) << "Flex should fail on invalid lexer";

  // Output should contain error information
  EXPECT_FALSE(output.empty()) << "Flex should provide error output";

  // Verify that the error message contains expected content
  EXPECT_TRUE(output.find("error") != std::string::npos ||
              output.find("Error") != std::string::npos ||
              output.find("EOF") != std::string::npos)
      << "Error output should mention error or EOF: " << output;

  // Only show error details in verbose mode or when test fails
  if (::testing::Test::HasFailure()) {
    std::cout << "Expected flex error output (test validation): " << output
              << std::endl;
  }
}

// Test flex feature support
TEST_F(FlexIntegrationTest, FeatureSupportTest) {
  // Test that flex supports expected features by checking help output
  std::string help_command = flex_path + " --help 2>/dev/null";
  FILE* pipe = popen(help_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[1024];
  std::string help_output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    help_output += buffer;
  }
  pclose(pipe);

  // Check for common flex features
  EXPECT_TRUE(help_output.find("--outfile") != std::string::npos ||
              help_output.find("-o") != std::string::npos)
      << "Flex should support output file specification";

  EXPECT_TRUE(help_output.find("--header-file") != std::string::npos ||
              help_output.find("--header") != std::string::npos)
      << "Flex should support header file generation";

  EXPECT_TRUE(help_output.find("--version") != std::string::npos ||
              help_output.find("-V") != std::string::npos)
      << "Flex should support version output";
}
