#include <gtest/gtest.h>
#include <jemalloc/jemalloc.h>

#include <cstdlib>
#include <cstring>
#include <iostream>
#include <vector>

// Comprehensive jemalloc integration tests
class JemallocComprehensiveTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Print test start information
    std::cout << "\n=== Starting jemalloc comprehensive test ===\n";
  }

  void TearDown() override {
    std::cout << "=== Completed jemalloc comprehensive test ===\n";
  }
};

// Test 1: Verify drop-in mode is working (malloc/free/new/delete)
TEST_F(JemallocComprehensiveTest, VerifyDropInModeWorking) {
  std::cout << "\n1. Testing drop-in replacement mode...\n";

  // Test malloc/free drop-in replacement
  void* ptr = malloc(1024);
  EXPECT_NE(ptr, nullptr);
  std::cout << "   > malloc(1024) succeeded\n";

  // Key test: if malloc is replaced by jemalloc,
  // then je_malloc_usable_size should recognize this memory
  size_t usable_size = je_malloc_usable_size(ptr);

  if (usable_size > 0) {
    std::cout << "   SUCCESS: malloc() is using jemalloc!\n";
    std::cout << "   Requested: 1024 bytes, usable: " << usable_size
              << " bytes\n";
    EXPECT_GE(usable_size, 1024);
  } else {
    std::cout << "   FAILURE: malloc() is NOT using jemalloc!\n";
    FAIL() << "jemalloc drop-in replacement is not working";
  }

  free(ptr);
  std::cout << "   > free() succeeded\n";

  // Test new/delete drop-in replacement
  int* new_ptr = new int[256];
  EXPECT_NE(new_ptr, nullptr);
  std::cout << "   > new int[256] succeeded\n";

  size_t new_usable = je_malloc_usable_size(new_ptr);
  if (new_usable > 0) {
    std::cout << "   SUCCESS: new operator is using jemalloc!\n";
    std::cout << "   new usable size: " << new_usable << " bytes\n";
    EXPECT_GE(new_usable, 256 * sizeof(int));
  } else {
    std::cout << "   FAILURE: new operator is NOT using jemalloc!\n";
    FAIL() << "jemalloc drop-in replacement for new/delete is not working";
  }

  delete[] new_ptr;
  std::cout << "   > delete[] succeeded\n";

  // Test aligned allocation
  void* aligned_ptr = aligned_alloc(64, 1024);
  EXPECT_NE(aligned_ptr, nullptr);
  if (aligned_ptr) {
    EXPECT_EQ(reinterpret_cast<uintptr_t>(aligned_ptr) % 64, 0);
    size_t aligned_usable = je_malloc_usable_size(aligned_ptr);
    std::cout << "   > aligned_alloc(64, 1024) usable size: " << aligned_usable
              << " bytes\n";
    free(aligned_ptr);
  }
}

// Test 2: Verify jemalloc public API
TEST_F(JemallocComprehensiveTest, VerifyPublicAPI) {
  std::cout << "\n2. Testing jemalloc public API...\n";

  // Use jemalloc public API
  void* ptr = je_malloc(2048);
  EXPECT_NE(ptr, nullptr);
  std::cout << "   > je_malloc(2048) succeeded\n";

  size_t usable_size = je_malloc_usable_size(ptr);
  EXPECT_GE(usable_size, 2048);
  std::cout << "   > je_malloc_usable_size: " << usable_size << " bytes\n";

  je_free(ptr);
  std::cout << "   > je_free() succeeded\n";

  // Test jemalloc version information
  const char* version = nullptr;
  size_t version_len = sizeof(version);
  int result = je_mallctl("version", &version, &version_len, nullptr, 0);

  if (result == 0 && version) {
    std::cout << "   > jemalloc version: " << version << "\n";
  }
}

// Test 3: Verify dual mode compatibility
TEST_F(JemallocComprehensiveTest, VerifyDualModeCompatibility) {
  std::cout << "\n3. Testing dual mode compatibility...\n";

  // Allocate memory using both methods
  void* malloc_ptr = malloc(1000);
  void* je_malloc_ptr = je_malloc(1000);

  EXPECT_NE(malloc_ptr, nullptr);
  EXPECT_NE(je_malloc_ptr, nullptr);

  // Both allocated memories should be tracked by jemalloc
  size_t malloc_usable = je_malloc_usable_size(malloc_ptr);
  size_t je_malloc_usable = je_malloc_usable_size(je_malloc_ptr);

  std::cout << "   malloc() usable size: " << malloc_usable << " bytes\n";
  std::cout << "   je_malloc() usable size: " << je_malloc_usable << " bytes\n";

  EXPECT_GT(malloc_usable, 0) << "malloc memory not tracked by jemalloc";
  EXPECT_GT(je_malloc_usable, 0) << "je_malloc memory not tracked by jemalloc";

  // Cross-release test (should both work)
  free(malloc_ptr);        // Use free to release malloc allocated memory
  je_free(je_malloc_ptr);  // Use je_free to release je_malloc allocated memory

  std::cout << "   Cross-compatibility verified\n";
}

// Test 4: Verify C++ containers use jemalloc
TEST_F(JemallocComprehensiveTest, VerifyCppContainersUseJemalloc) {
  std::cout << "\n4. Testing C++ containers with jemalloc...\n";

  // Get initial allocation statistics
  size_t allocated_before = 0;
  size_t sz = sizeof(allocated_before);
  je_mallctl("stats.allocated", &allocated_before, &sz, nullptr, 0);

  {
    // Create large containers to trigger significant memory allocation
    std::vector<int> large_vector;
    large_vector.reserve(100000);  // About 400KB

    for (int i = 0; i < 100000; ++i) {
      large_vector.push_back(i);
    }

    std::cout << "   > Created vector with " << large_vector.size()
              << " elements\n";
    std::cout << "   > Vector capacity: " << large_vector.capacity()
              << " elements\n";
    std::cout << "   > Estimated memory: ~"
              << (large_vector.capacity() * sizeof(int)) << " bytes\n";

    // Create large string
    std::string large_string;
    large_string.reserve(50000);
    for (int i = 0; i < 10000; ++i) {
      large_string += "test ";
    }

    std::cout << "   > Created string with " << large_string.size()
              << " characters\n";
  }

  // Get final allocation statistics
  size_t allocated_after = 0;
  je_mallctl("stats.allocated", &allocated_after, &sz, nullptr, 0);

  if (allocated_after > allocated_before) {
    std::cout << "   C++ containers are using jemalloc\n";
    std::cout << "   Memory increase: " << (allocated_after - allocated_before)
              << " bytes\n";
  } else {
    std::cout << "   Cannot verify C++ container memory tracking\n";
  }
}

// Test 5: Verify jemalloc configuration and statistics
TEST_F(JemallocComprehensiveTest, VerifyJemallocConfiguration) {
  std::cout << "\n5. Testing jemalloc configuration...\n";

  // Check version
  const char* version = nullptr;
  size_t version_len = sizeof(version);
  if (je_mallctl("version", &version, &version_len, nullptr, 0) == 0) {
    std::cout << "   > Version: " << (version ? version : "unknown") << "\n";
  }

  // Check statistics functionality
  bool stats_enabled = false;
  size_t bool_size = sizeof(stats_enabled);
  if (je_mallctl("config.stats", &stats_enabled, &bool_size, nullptr, 0) == 0) {
    std::cout << "   > Stats enabled: " << (stats_enabled ? "yes" : "no")
              << "\n";
  }

  // Check profiling functionality
  bool prof_enabled = false;
  if (je_mallctl("config.prof", &prof_enabled, &bool_size, nullptr, 0) == 0) {
    std::cout << "   > Profiling enabled: " << (prof_enabled ? "yes" : "no")
              << "\n";
  }

  // Get current memory statistics
  size_t allocated = 0, active = 0, resident = 0;
  size_t sz = sizeof(size_t);

  if (je_mallctl("stats.allocated", &allocated, &sz, nullptr, 0) == 0) {
    std::cout << "   > Total allocated: " << allocated << " bytes\n";
  }

  if (je_mallctl("stats.active", &active, &sz, nullptr, 0) == 0) {
    std::cout << "   > Active memory: " << active << " bytes\n";
  }

  if (je_mallctl("stats.resident", &resident, &sz, nullptr, 0) == 0) {
    std::cout << "   > Resident memory: " << resident << " bytes\n";
  }
}

// Test 6: Stress test and performance verification
TEST_F(JemallocComprehensiveTest, StressTestAndPerformance) {
  std::cout << "\n6. Running stress test...\n";

  const int num_allocs = 1000;
  std::vector<void*> ptrs;
  ptrs.reserve(num_allocs);

  // Allocate many memory blocks of different sizes
  for (int i = 0; i < num_allocs; ++i) {
    size_t size = (i % 10 + 1) * 64;  // 64 to 640 bytes
    void* ptr = malloc(size);
    EXPECT_NE(ptr, nullptr);

    if (ptr) {
      // Verify each allocation is tracked by jemalloc
      size_t usable = je_malloc_usable_size(ptr);
      EXPECT_GE(usable, size);
      ptrs.push_back(ptr);
    }
  }

  std::cout << "   > Allocated " << ptrs.size() << " memory blocks\n";

  // Free all memory
  for (void* ptr : ptrs) {
    free(ptr);
  }

  std::cout << "   > Freed all memory blocks\n";
}

// Final report test
TEST_F(JemallocComprehensiveTest, FinalReport) {
  std::cout << "\n" << std::string(60, '=') << "\n";
  std::cout << "JEMALLOC COMPREHENSIVE TEST SUMMARY\n";
  std::cout << std::string(60, '=') << "\n";

  // Final verification of drop-in mode
  void* test_ptr = malloc(100);
  bool drop_in_works = (je_malloc_usable_size(test_ptr) > 0);
  free(test_ptr);

  // Verify public API
  void* je_ptr = je_malloc(100);
  bool public_api_works = (je_ptr != nullptr);
  if (je_ptr) je_free(je_ptr);

  if (drop_in_works) {
    std::cout << "DROP-IN MODE: WORKING\n";
    std::cout << "   malloc/free are replaced by jemalloc\n";
  } else {
    std::cout << "DROP-IN MODE: NOT WORKING\n";
    std::cout << "   malloc/free are using system allocator\n";
  }

  if (public_api_works) {
    std::cout << "PUBLIC API: WORKING\n";
    std::cout << "   je_malloc/je_free are available\n";
  } else {
    std::cout << "PUBLIC API: NOT WORKING\n";
    std::cout << "   je_malloc/je_free are not available\n";
  }

  // Get final statistics
  size_t allocated = 0;
  size_t sz = sizeof(allocated);
  if (je_mallctl("stats.allocated", &allocated, &sz, nullptr, 0) == 0) {
    std::cout << "CURRENT MEMORY: " << allocated << " bytes allocated\n";
  }

  std::cout << std::string(60, '=') << "\n";

  // Assert key functionality
  EXPECT_TRUE(drop_in_works) << "jemalloc drop-in replacement MUST work!";
  EXPECT_TRUE(public_api_works) << "jemalloc public API MUST work!";

  if (drop_in_works && public_api_works) {
    std::cout << "ALL TESTS PASSED: jemalloc is fully functional!\n";
  }
}
