#include <gtest/gtest.h>
#include <libunwind.h>
#include <unwind.h>

#include <cstdint>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

// Test fixture for libunwind integration tests
class LibunwindIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Setup test environment
  }

  void TearDown() override {
    // Cleanup test environment
  }
};

// Test basic libunwind functionality
TEST_F(LibunwindIntegrationTest, BasicUnwindTest) {
  unw_context_t context;
  unw_cursor_t cursor;

  // Get the current context
  int ret = unw_getcontext(&context);
  EXPECT_EQ(ret, 0) << "Failed to get unwind context";

  // Initialize cursor
  ret = unw_init_local(&cursor, &context);
  EXPECT_EQ(ret, 0) << "Failed to initialize unwind cursor";

  // Should be able to step at least once (current function)
  int step_count = 0;
  while (step_count < 100) {
    step_count++;
    ret = unw_step(&cursor);
    if (ret <= 0) {
      break;
    }
  }

  EXPECT_GT(step_count, 0) << "Should have at least one stack frame";
}

// Test getting procedure names
TEST_F(LibunwindIntegrationTest, ProcedureNameTest) {
  unw_context_t context;
  unw_cursor_t cursor;

  int ret = unw_getcontext(&context);
  ASSERT_EQ(ret, 0);

  ret = unw_init_local(&cursor, &context);
  ASSERT_EQ(ret, 0);

  // Try to get procedure name for current frame
  std::array<char, 256> proc_name{};
  unw_word_t offset = 0;

  ret = unw_get_proc_name(&cursor, proc_name.data(), proc_name.size(), &offset);
  if (ret == 0) {
    // Successfully got procedure name
    EXPECT_GT(strlen(proc_name.data()), 0)
        << "Procedure name should not be empty";
    std::cout << "Current procedure: " << proc_name.data()
              << " (offset: " << offset << ")" << '\n';
  } else {
    // Procedure name might not be available in all cases
    std::cout << "Procedure name not available (ret=" << ret << ")" << '\n';
  }
}

// Test getting register values
TEST_F(LibunwindIntegrationTest, RegisterValueTest) {
  unw_context_t context;
  unw_cursor_t cursor;

  int ret = unw_getcontext(&context);
  ASSERT_EQ(ret, 0);

  ret = unw_init_local(&cursor, &context);
  ASSERT_EQ(ret, 0);

  // Try to get instruction pointer
  unw_word_t instruction_pointer = 0;
  ret = unw_get_reg(&cursor, UNW_REG_IP, &instruction_pointer);
  EXPECT_EQ(ret, 0) << "Should be able to get instruction pointer";

  if (ret == 0) {
    EXPECT_NE(instruction_pointer, 0)
        << "Instruction pointer should not be null";
    std::cout << "Instruction pointer: 0x" << std::hex << instruction_pointer
              << std::dec << '\n';
  }

  // Try to get stack pointer
  unw_word_t stack_pointer = 0;
  ret = unw_get_reg(&cursor, UNW_REG_SP, &stack_pointer);
  EXPECT_EQ(ret, 0) << "Should be able to get stack pointer";

  if (ret == 0) {
    EXPECT_NE(stack_pointer, 0) << "Stack pointer should not be null";
    std::cout << "Stack pointer: 0x" << std::hex << stack_pointer << std::dec
              << '\n';
  }
}

// Helper function to create a stack trace
std::vector<std::string> CaptureStackTrace() {
  std::vector<std::string> trace;
  unw_context_t context;
  unw_cursor_t cursor;

  if (unw_getcontext(&context) != 0) {
    return trace;
  }

  if (unw_init_local(&cursor, &context) != 0) {
    return trace;
  }

  int frame_count = 0;
  while (frame_count < 50) {
    unw_word_t instruction_pointer = 0;
    if (unw_get_reg(&cursor, UNW_REG_IP, &instruction_pointer) == 0) {
      std::array<char, 256> proc_name{};
      unw_word_t offset = 0;

      std::stringstream string_stream;
      string_stream << "Frame " << frame_count << ": 0x" << std::hex
                    << instruction_pointer;

      if (unw_get_proc_name(&cursor, proc_name.data(), proc_name.size(),
                            &offset) == 0) {
        string_stream << " (" << proc_name.data() << "+0x" << std::hex << offset
                      << ")";
      }

      trace.push_back(string_stream.str());
    }

    frame_count++;
    if (unw_step(&cursor) <= 0) {
      break;
    }
  }

  return trace;
}

// Test function to create nested calls for stack trace testing
void Level3Function() {
  auto trace = CaptureStackTrace();

  // Should have multiple frames
  EXPECT_GE(trace.size(), 3) << "Should have at least 3 stack frames";

  // Print stack trace
  std::cout << "Stack trace from Level3Function:" << '\n';
  for (const auto& frame : trace) {
    std::cout << "  " << frame << '\n';
  }
}

void Level2Function() { Level3Function(); }

void Level1Function() { Level2Function(); }

// Test stack trace capture through nested function calls
TEST_F(LibunwindIntegrationTest, StackTraceTest) { Level1Function(); }

// Test C-style unwinding interface
struct UnwindInfo {
  std::vector<uintptr_t> addresses_;
  int count_ = 0;
};

_Unwind_Reason_Code UnwindCallback(struct _Unwind_Context* context, void* arg) {
  auto* info = static_cast<UnwindInfo*>(arg);

  uintptr_t instruction_pointer = _Unwind_GetIP(context);
  if (instruction_pointer != 0) {
    info->addresses_.push_back(instruction_pointer);
    info->count_++;
  }

  // Continue unwinding (stop after 50 frames to avoid infinite loops)
  return (info->count_ < 50) ? _URC_NO_REASON : _URC_END_OF_STACK;
}

TEST_F(LibunwindIntegrationTest, CStyleUnwindTest) {
  UnwindInfo info;
  info.count_ = 0;

  _Unwind_Reason_Code result = _Unwind_Backtrace(UnwindCallback, &info);

  // Should succeed or reach end of stack
  EXPECT_TRUE(result == _URC_NO_REASON || result == _URC_END_OF_STACK)
      << "Unwind should succeed or reach end of stack";

  EXPECT_GT(info.addresses_.size(), 0) << "Should capture at least one address";
  EXPECT_EQ(info.addresses_.size(), static_cast<size_t>(info.count_));

  std::cout << "C-style unwind captured " << info.count_ << " frames" << '\n';
}

// Test exception unwinding capabilities
class TestException : public std::exception {
 public:
  [[nodiscard]] const char* what() const noexcept override {
    return "Test exception for unwinding";
  }
};

void ThrowingFunction() { throw TestException(); }

void CatchingFunction() {
  try {
    ThrowingFunction();
  } catch (const TestException& e) {
    // Capture stack trace during exception handling
    auto trace = CaptureStackTrace();

    EXPECT_GT(trace.size(), 0)
        << "Should be able to unwind during exception handling";

    std::cout << "Stack trace during exception handling:" << '\n';
    for (const auto& frame : trace) {
      std::cout << "  " << frame << '\n';
    }
  }
}

TEST_F(LibunwindIntegrationTest, ExceptionUnwindTest) {
  EXPECT_NO_THROW(CatchingFunction());
}

// Performance test for unwinding
TEST_F(LibunwindIntegrationTest, PerformanceTest) {
  constexpr int NUM_ITERATIONS = 1000;
  auto start = std::chrono::high_resolution_clock::now();

  for (int i = 0; i < NUM_ITERATIONS; ++i) {
    unw_context_t context;
    unw_cursor_t cursor;

    if (unw_getcontext(&context) == 0 &&
        unw_init_local(&cursor, &context) == 0) {
      // Count frames
      int frame_count = 0;
      while (frame_count < 20) {
        frame_count++;
        if (unw_step(&cursor) <= 0) {
          break;
        }
      }
    }
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::microseconds>(end - start);

  std::cout << "Unwinding performance: " << duration.count()
            << " microseconds for " << NUM_ITERATIONS << " iterations" << '\n';
  std::cout << "Average: " << (duration.count() / NUM_ITERATIONS)
            << " microseconds per unwind" << '\n';

  // Should complete in reasonable time (less than 1 second total)
  EXPECT_LT(duration.count(), 1000000);
}

// Test libunwind version and capabilities
TEST_F(LibunwindIntegrationTest, LibunwindCapabilitiesTest) {
  std::cout << "Testing libunwind capabilities:" << '\n';

  // Test if we can unwind local context
  unw_context_t context;
  int ret = unw_getcontext(&context);
  EXPECT_EQ(ret, 0) << "Local context unwinding should be supported";

  // Test basic cursor operations
  if (ret == 0) {
    unw_cursor_t cursor;
    ret = unw_init_local(&cursor, &context);
    EXPECT_EQ(ret, 0) << "Local cursor initialization should work";

    if (ret == 0) {
      // Test if we can step
      ret = unw_step(&cursor);
      EXPECT_GE(ret, 0)
          << "Cursor stepping should work or indicate end of stack";

      std::cout << "  Local unwinding: SUPPORTED" << '\n';
    }
  }

  // Test C-style interface
  UnwindInfo info;
  info.count_ = 0;
  _Unwind_Reason_Code c_result = _Unwind_Backtrace(UnwindCallback, &info);

  if (c_result == _URC_NO_REASON || c_result == _URC_END_OF_STACK) {
    std::cout << "  C-style unwinding: SUPPORTED" << '\n';
  } else {
    std::cout << "  C-style unwinding: LIMITED" << '\n';
  }
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);

  std::cout << "Starting libunwind integration tests" << '\n';

  return RUN_ALL_TESTS();
}
