#include <gtest/gtest.h>
#include <libunwind.h>
#include <unwind.h>

#include <iostream>
#include <memory>
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
  do {
    step_count++;
    ret = unw_step(&cursor);
  } while (ret > 0 && step_count < 100);  // Limit steps to avoid infinite loops

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
  char proc_name[256];
  unw_word_t offset;

  ret = unw_get_proc_name(&cursor, proc_name, sizeof(proc_name), &offset);
  if (ret == 0) {
    // Successfully got procedure name
    EXPECT_GT(strlen(proc_name), 0) << "Procedure name should not be empty";
    std::cout << "Current procedure: " << proc_name << " (offset: " << offset
              << ")" << std::endl;
  } else {
    // Procedure name might not be available in all cases
    std::cout << "Procedure name not available (ret=" << ret << ")"
              << std::endl;
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
  unw_word_t ip;
  ret = unw_get_reg(&cursor, UNW_REG_IP, &ip);
  EXPECT_EQ(ret, 0) << "Should be able to get instruction pointer";

  if (ret == 0) {
    EXPECT_NE(ip, 0) << "Instruction pointer should not be null";
    std::cout << "Instruction pointer: 0x" << std::hex << ip << std::dec
              << std::endl;
  }

  // Try to get stack pointer
  unw_word_t sp;
  ret = unw_get_reg(&cursor, UNW_REG_SP, &sp);
  EXPECT_EQ(ret, 0) << "Should be able to get stack pointer";

  if (ret == 0) {
    EXPECT_NE(sp, 0) << "Stack pointer should not be null";
    std::cout << "Stack pointer: 0x" << std::hex << sp << std::dec << std::endl;
  }
}

// Helper function to create a stack trace
std::vector<std::string> capture_stack_trace() {
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
  do {
    unw_word_t ip;
    if (unw_get_reg(&cursor, UNW_REG_IP, &ip) == 0) {
      char proc_name[256];
      unw_word_t offset;

      std::stringstream ss;
      ss << "Frame " << frame_count << ": 0x" << std::hex << ip;

      if (unw_get_proc_name(&cursor, proc_name, sizeof(proc_name), &offset) ==
          0) {
        ss << " (" << proc_name << "+0x" << std::hex << offset << ")";
      }

      trace.push_back(ss.str());
    }

    frame_count++;
  } while (unw_step(&cursor) > 0 && frame_count < 50);

  return trace;
}

// Test function to create nested calls for stack trace testing
void level3_function() {
  auto trace = capture_stack_trace();

  // Should have multiple frames
  EXPECT_GE(trace.size(), 3) << "Should have at least 3 stack frames";

  // Print stack trace
  std::cout << "Stack trace from level3_function:" << std::endl;
  for (size_t i = 0; i < trace.size(); ++i) {
    std::cout << "  " << trace[i] << std::endl;
  }
}

void level2_function() { level3_function(); }

void level1_function() { level2_function(); }

// Test stack trace capture through nested function calls
TEST_F(LibunwindIntegrationTest, StackTraceTest) { level1_function(); }

// Test C-style unwinding interface
struct UnwindInfo {
  std::vector<void*> addresses;
  int count;
};

_Unwind_Reason_Code unwind_callback(struct _Unwind_Context* context,
                                    void* arg) {
  UnwindInfo* info = static_cast<UnwindInfo*>(arg);

  void* ip = (void*)_Unwind_GetIP(context);
  if (ip != nullptr) {
    info->addresses.push_back(ip);
    info->count++;
  }

  // Continue unwinding (stop after 50 frames to avoid infinite loops)
  return (info->count < 50) ? _URC_NO_REASON : _URC_END_OF_STACK;
}

TEST_F(LibunwindIntegrationTest, CStyleUnwindTest) {
  UnwindInfo info;
  info.count = 0;

  _Unwind_Reason_Code result = _Unwind_Backtrace(unwind_callback, &info);

  // Should succeed or reach end of stack
  EXPECT_TRUE(result == _URC_NO_REASON || result == _URC_END_OF_STACK)
      << "Unwind should succeed or reach end of stack";

  EXPECT_GT(info.addresses.size(), 0) << "Should capture at least one address";
  EXPECT_EQ(info.addresses.size(), static_cast<size_t>(info.count));

  std::cout << "C-style unwind captured " << info.count << " frames"
            << std::endl;
}

// Test exception unwinding capabilities
class TestException : public std::exception {
 public:
  const char* what() const noexcept override {
    return "Test exception for unwinding";
  }
};

void throwing_function() { throw TestException(); }

void catching_function() {
  try {
    throwing_function();
  } catch (const TestException& e) {
    // Capture stack trace during exception handling
    auto trace = capture_stack_trace();

    EXPECT_GT(trace.size(), 0)
        << "Should be able to unwind during exception handling";

    std::cout << "Stack trace during exception handling:" << std::endl;
    for (const auto& frame : trace) {
      std::cout << "  " << frame << std::endl;
    }
  }
}

TEST_F(LibunwindIntegrationTest, ExceptionUnwindTest) {
  EXPECT_NO_THROW(catching_function());
}

// Performance test for unwinding
TEST_F(LibunwindIntegrationTest, PerformanceTest) {
  const int num_iterations = 1000;
  auto start = std::chrono::high_resolution_clock::now();

  for (int i = 0; i < num_iterations; ++i) {
    unw_context_t context;
    unw_cursor_t cursor;

    if (unw_getcontext(&context) == 0 &&
        unw_init_local(&cursor, &context) == 0) {
      // Count frames
      int frame_count = 0;
      while (unw_step(&cursor) > 0 && frame_count < 20) {
        frame_count++;
      }
    }
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::microseconds>(end - start);

  std::cout << "Unwinding performance: " << duration.count()
            << " microseconds for " << num_iterations << " iterations"
            << std::endl;
  std::cout << "Average: " << (duration.count() / num_iterations)
            << " microseconds per unwind" << std::endl;

  // Should complete in reasonable time (less than 1 second total)
  EXPECT_LT(duration.count(), 1000000);
}

// Test libunwind version and capabilities
TEST_F(LibunwindIntegrationTest, LibunwindCapabilitiesTest) {
  std::cout << "Testing libunwind capabilities:" << std::endl;

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

      std::cout << "  Local unwinding: SUPPORTED" << std::endl;
    }
  }

  // Test C-style interface
  UnwindInfo info;
  info.count = 0;
  _Unwind_Reason_Code c_result = _Unwind_Backtrace(unwind_callback, &info);

  if (c_result == _URC_NO_REASON || c_result == _URC_END_OF_STACK) {
    std::cout << "  C-style unwinding: SUPPORTED" << std::endl;
  } else {
    std::cout << "  C-style unwinding: LIMITED" << std::endl;
  }
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);

  std::cout << "Starting libunwind integration tests" << std::endl;

  return RUN_ALL_TESTS();
}
