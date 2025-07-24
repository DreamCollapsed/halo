#include <gtest/gtest.h>

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <string>

class BisonIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up test environment
    test_dir = std::filesystem::temp_directory_path() / "bison_test";
    std::filesystem::create_directories(test_dir);

    // Use CMake-provided bison executable path if available
#ifdef BISON_EXECUTABLE_PATH
    bison_path = BISON_EXECUTABLE_PATH;
#endif
    // Create a simple grammar file for testing
    grammar_file = test_dir / "test.y";
    createTestGrammar();
  }

  void TearDown() override {
    // Clean up test files
    std::filesystem::remove_all(test_dir);
  }

  void createTestGrammar() {
    std::ofstream file(grammar_file);
    file << R"(
%{
#include <stdio.h>
#include <stdlib.h>
int yylex(void);
void yyerror(const char *s);
%}

%token NUMBER
%token PLUS MINUS TIMES DIVIDE
%token LPAREN RPAREN
%token NEWLINE

%left PLUS MINUS
%left TIMES DIVIDE
%right UMINUS

%start input

%%

input:
    /* empty */
    | input line
    ;

line:
    NEWLINE
    | exp NEWLINE { printf("Result: %d\n", $1); }
    ;

exp:
    NUMBER
    | exp PLUS exp { $$ = $1 + $3; }
    | exp MINUS exp { $$ = $1 - $3; }
    | exp TIMES exp { $$ = $1 * $3; }
    | exp DIVIDE exp { $$ = $1 / $3; }
    | MINUS exp %prec UMINUS { $$ = -$2; }
    | LPAREN exp RPAREN { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int yylex(void) {
    return 0;  // Dummy implementation
}

int main(void) {
    return 0;
}
)";
    file.close();
  }

  std::filesystem::path test_dir;
  std::filesystem::path grammar_file;
  std::string bison_path;  // Will be set dynamically in SetUp()
};

// Test bison executable availability and version
TEST_F(BisonIntegrationTest, BisonVersionTest) {
  // Test that bison executable is available
  std::string version_command = bison_path + " --version > /dev/null 2>&1";
  int result = std::system(version_command.c_str());
  EXPECT_EQ(result, 0) << "bison executable should be available";

  // Test that we can get version information
  std::string popen_command = bison_path + " --version 2>/dev/null";
  FILE* pipe = popen(popen_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string version_output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    version_output += buffer;
  }
  pclose(pipe);

  // Check that version contains expected version number (3.8.2)
  EXPECT_TRUE(version_output.find("3.8") != std::string::npos)
      << "Version output: " << version_output;
}

// Test bison help output
TEST_F(BisonIntegrationTest, BisonHelpTest) {
  // Test that bison shows help when called with --help
  std::string help_command = bison_path + " --help > /dev/null 2>&1";
  int result = std::system(help_command.c_str());
  EXPECT_EQ(result, 0) << "bison --help should work";

  // Capture help output
  std::string popen_help_command = bison_path + " --help 2>/dev/null";
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

  EXPECT_TRUE(help_output.find("bison") != std::string::npos)
      << "Help should mention bison";
}

// Test basic grammar parsing
TEST_F(BisonIntegrationTest, BasicGrammarParsingTest) {
  ASSERT_TRUE(std::filesystem::exists(grammar_file))
      << "Test grammar file should exist";

  // Test that bison can parse the grammar without errors
  std::string command = bison_path + " --yacc --defines --output=" +
                        (test_dir / "test.tab.c").string() + " " +
                        grammar_file.string() + " 2>&1";

  FILE* pipe = popen(command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    output += buffer;
  }
  int result = pclose(pipe);

  // Check that bison completed successfully
  EXPECT_EQ(result, 0) << "Bison should parse grammar successfully. Output: "
                       << output;

  // Check that output files were generated
  EXPECT_TRUE(std::filesystem::exists(test_dir / "test.tab.c"))
      << "Bison should generate C source file";
  EXPECT_TRUE(std::filesystem::exists(test_dir / "test.tab.h"))
      << "Bison should generate header file";
}

// Test bison with different output formats
TEST_F(BisonIntegrationTest, OutputFormatsTest) {
  ASSERT_TRUE(std::filesystem::exists(grammar_file))
      << "Test grammar file should exist";

  // Test verbose output
  std::string verbose_command = bison_path + " --verbose --output=" +
                                (test_dir / "verbose.tab.c").string() + " " +
                                grammar_file.string() + " 2>&1";

  FILE* pipe = popen(verbose_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    output += buffer;
  }
  int result = pclose(pipe);

  EXPECT_EQ(result, 0) << "Bison verbose mode should work. Output: " << output;

  // Check that verbose output file was generated
  EXPECT_TRUE(std::filesystem::exists(test_dir / "verbose.output"))
      << "Bison should generate verbose output file";
}

// Test bison error handling with invalid grammar
TEST_F(BisonIntegrationTest, ErrorHandlingTest) {
  // Create an invalid grammar file
  std::filesystem::path invalid_grammar = test_dir / "invalid.y";
  std::ofstream file(invalid_grammar);
  file << R"(
%{
// Invalid grammar with syntax errors
%}

%token INVALID_TOKEN

%%

invalid_rule:
    INVALID_TOKEN MISSING_SEMICOLON  // Missing semicolon and action
    | 
    ;

// Missing final %% section
)";
  file.close();

  // Test that bison reports errors for invalid grammar
  std::string command = bison_path + " " + invalid_grammar.string() + " 2>&1";

  FILE* pipe = popen(command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[256];
  std::string output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    output += buffer;
  }
  int result = pclose(pipe);

  // Bison should return non-zero exit code for invalid grammar
  EXPECT_NE(result, 0) << "Bison should fail on invalid grammar";

  // Output should contain error information
  EXPECT_FALSE(output.empty()) << "Bison should provide error output";

  // Verify that the error message contains expected content
  EXPECT_TRUE(output.find("MISSING_SEMICOLON") != std::string::npos)
      << "Error output should mention the undefined symbol";

  // Only show error details in verbose mode or when test fails
  if (::testing::Test::HasFailure()) {
    std::cout << "Expected bison error output (test validation): " << output
              << std::endl;
  }
}

// Test bison feature support
TEST_F(BisonIntegrationTest, FeatureSupportTest) {
  // Test that bison supports expected features by checking help output
  std::string help_command = bison_path + " --help 2>/dev/null";
  FILE* pipe = popen(help_command.c_str(), "r");
  ASSERT_NE(pipe, nullptr);

  char buffer[1024];
  std::string help_output;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    help_output += buffer;
  }
  pclose(pipe);

  // Check for important features
  EXPECT_TRUE(help_output.find("--yacc") != std::string::npos ||
              help_output.find("-y") != std::string::npos)
      << "Bison should support yacc compatibility mode";

  EXPECT_TRUE(help_output.find("--defines") != std::string::npos ||
              help_output.find("-d") != std::string::npos)
      << "Bison should support header file generation";

  EXPECT_TRUE(help_output.find("--verbose") != std::string::npos ||
              help_output.find("-v") != std::string::npos)
      << "Bison should support verbose output";
}
