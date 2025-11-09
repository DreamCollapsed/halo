#include <gtest/gtest.h>
#include <jemalloc/jemalloc.h>

#include <atomic>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <thread>
#include <vector>

// Enforce that this test only runs when jemalloc is built in drop-in mode.
// If the build system somehow compiled without JEMALLOC_DROP_IN=1 we hard fail.
#if !defined(JEMALLOC_DROP_IN) || (JEMALLOC_DROP_IN != 1)
#error "This test requires jemalloc drop-in mode (JEMALLOC_DROP_IN=1)."
#endif

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

  // Additional runtime sanity: even if macro says drop-in, verify behavior.
  {
    void* probe = malloc(8);
    ASSERT_NE(probe, nullptr) << "malloc probe failed";
    size_t us = malloc_usable_size(probe);
    free(probe);
    ASSERT_GT(us, 0u) << "jemalloc drop-in runtime verification failed "
                         "(malloc_usable_size=0)";
  }

  // Test malloc/free drop-in replacement
  void* ptr = malloc(1024);
  EXPECT_NE(ptr, nullptr);
  std::cout << "   > malloc(1024) succeeded\n";

  // Key test: if malloc is provided by jemalloc (drop-in),
  // then malloc_usable_size should report a non-zero usable size
  size_t usable_size = malloc_usable_size(ptr);

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

  size_t new_usable = malloc_usable_size(new_ptr);
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
    size_t aligned_usable = malloc_usable_size(aligned_ptr);
    std::cout << "   > aligned_alloc(64, 1024) usable size: " << aligned_usable
              << " bytes\n";
    free(aligned_ptr);
  }
}

// Test 2: Verify jemalloc public API
TEST_F(JemallocComprehensiveTest, VerifyPublicAPI) {
  std::cout << "\n2. Testing jemalloc public API...\n";

  // Use jemalloc extended allocation API (mallocx)
  // Flags: 0 => default tcache & alignment; could add MALLOCX_ZERO if desired.
  void* ptr = mallocx(2048, 0);
  EXPECT_NE(ptr, nullptr);
  std::cout << "   > mallocx(2048, 0) succeeded\n";

  size_t usable_size = malloc_usable_size(ptr);
  EXPECT_GE(usable_size, 2048);
  std::cout << "   > malloc_usable_size: " << usable_size << " bytes\n";

  dallocx(ptr, 0);
  std::cout << "   > dallocx(ptr, 0) succeeded\n";

  // Test jemalloc version information
  const char* version = nullptr;
  size_t version_len = sizeof(version);
  int result = mallctl("version", &version, &version_len, nullptr, 0);

  if (result == 0 && version) {
    std::cout << "   > jemalloc version: " << version << "\n";
  }
}

// Test 3: Verify dual mode compatibility
TEST_F(JemallocComprehensiveTest, VerifyDualModeCompatibility) {
  std::cout << "\n3. Testing dual mode compatibility...\n";

  // Allocate memory using both methods
  void* malloc_ptr = malloc(1000);
  void* mallocx_ptr = mallocx(1000, 0);

  EXPECT_NE(malloc_ptr, nullptr);
  EXPECT_NE(mallocx_ptr, nullptr);

  // Both allocated memories should be tracked by jemalloc
  size_t malloc_usable = malloc_usable_size(malloc_ptr);
  size_t mallocx_usable = malloc_usable_size(mallocx_ptr);

  std::cout << "   malloc() usable size: " << malloc_usable << " bytes\n";
  std::cout << "   mallocx() usable size: " << mallocx_usable << " bytes\n";

  EXPECT_GT(malloc_usable, 0) << "malloc memory not tracked by jemalloc";
  EXPECT_GT(mallocx_usable, 0) << "mallocx memory not tracked by jemalloc";

  // Cross-release test (should both work)
  free(malloc_ptr);         // Release malloc allocation via standard free
  dallocx(mallocx_ptr, 0);  // Release mallocx allocation via dallocx

  std::cout << "   Cross-compatibility verified\n";
}

// Test 4: Verify C++ containers use jemalloc
TEST_F(JemallocComprehensiveTest, VerifyCppContainersUseJemalloc) {
  std::cout << "\n4. Testing C++ containers with jemalloc...\n";

  // Get initial allocation statistics
  size_t allocated_before = 0;
  size_t sz = sizeof(allocated_before);
  mallctl("stats.allocated", &allocated_before, &sz, nullptr, 0);

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
  mallctl("stats.allocated", &allocated_after, &sz, nullptr, 0);

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
  if (mallctl("version", &version, &version_len, nullptr, 0) == 0) {
    std::cout << "   > Version: " << (version ? version : "unknown") << "\n";
  }

  // Check statistics functionality
  bool stats_enabled = false;
  size_t bool_size = sizeof(stats_enabled);
  if (mallctl("config.stats", &stats_enabled, &bool_size, nullptr, 0) == 0) {
    std::cout << "   > Stats enabled: " << (stats_enabled ? "yes" : "no")
              << "\n";
  }

  // Check profiling functionality
  bool prof_enabled = false;
  if (mallctl("config.prof", &prof_enabled, &bool_size, nullptr, 0) == 0) {
    std::cout << "   > Profiling enabled: " << (prof_enabled ? "yes" : "no")
              << "\n";
  }

  // Get current memory statistics
  size_t allocated = 0, active = 0, resident = 0;
  size_t sz = sizeof(size_t);

  if (mallctl("stats.allocated", &allocated, &sz, nullptr, 0) == 0) {
    std::cout << "   > Total allocated: " << allocated << " bytes\n";
  }

  if (mallctl("stats.active", &active, &sz, nullptr, 0) == 0) {
    std::cout << "   > Active memory: " << active << " bytes\n";
  }

  if (mallctl("stats.resident", &resident, &sz, nullptr, 0) == 0) {
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
      size_t usable = malloc_usable_size(ptr);
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

// Test 7: Advanced allocator frontends (calloc, realloc, posix_memalign,
// mallctl negative)
TEST_F(JemallocComprehensiveTest, AdvancedAllocatorFrontends) {
  std::cout << "\n7. Testing advanced allocator frontends...\n";

  // calloc zero-initialization
  void* cptr = calloc(128, 32);  // 4096 bytes
  ASSERT_NE(cptr, nullptr);
  bool zero = true;
  for (size_t i = 0; i < 4096; ++i) {
    if (static_cast<unsigned char*>(cptr)[i] != 0) {
      zero = false;
      break;
    }
  }
  EXPECT_TRUE(zero) << "calloc did not zero-initialize memory";
  size_t cusable = malloc_usable_size(cptr);
  EXPECT_GE(cusable, 4096u);

  // realloc growth & preserve prefix
  memset(cptr, 0xAB, 256);
  void* rptr = realloc(cptr, 16384);  // grow
  ASSERT_NE(rptr, nullptr);
  size_t rusable = malloc_usable_size(rptr);
  EXPECT_GE(rusable, 16384u);
  unsigned char* uc = static_cast<unsigned char*>(rptr);
  bool preserved = true;
  for (int i = 0; i < 256; ++i) {
    if (uc[i] != 0xAB) {
      preserved = false;
      break;
    }
  }
  EXPECT_TRUE(preserved) << "realloc did not preserve initial content";

  // posix_memalign alignment
  void* aptr = nullptr;
  int pa_rc = posix_memalign(&aptr, 256, 4096);
  ASSERT_EQ(pa_rc, 0) << "posix_memalign failed";
  ASSERT_NE(aptr, nullptr);
  EXPECT_EQ(reinterpret_cast<uintptr_t>(aptr) % 256, 0u)
      << "posix_memalign alignment failed";
  size_t ausable = malloc_usable_size(aptr);
  EXPECT_GE(ausable, 4096u);

  // Negative mallctl query
  int bad_rc = mallctl("nonexistent.node", nullptr, nullptr, nullptr, 0);
  EXPECT_NE(bad_rc, 0) << "mallctl for nonexistent node unexpectedly succeeded";

  // Epoch refresh validation: ensure stats.allocated changes after allocations
  size_t epoch = 1;
  size_t esz = sizeof(epoch);
  mallctl("epoch", &epoch, &esz, &epoch, sizeof(epoch));
  size_t before = 0;
  size_t ssz = sizeof(before);
  mallctl("stats.allocated", &before, &ssz, nullptr, 0);
  // allocate some memory
  std::vector<void*> blocks;
  blocks.reserve(64);
  for (int i = 0; i < 64; ++i) blocks.push_back(malloc(1024));
  mallctl("epoch", &epoch, &esz, &epoch, sizeof(epoch));
  size_t after = 0;
  mallctl("stats.allocated", &after, &ssz, nullptr, 0);
  EXPECT_GT(after, before)
      << "stats.allocated did not increase after allocations";
  for (void* b : blocks) free(b);
  free(rptr);
  free(aptr);
}

// Test 8: Multithreaded allocation stress (arena/tcache concurrency sanity)
TEST_F(JemallocComprehensiveTest, MultithreadedAllocationStress) {
  std::cout << "\n8. Multithreaded allocation stress...\n";
  unsigned hc = std::thread::hardware_concurrency();
  // Fallback if hardware_concurrency returns 0.
  if (hc == 0) hc = 4;
  // Bound threads to avoid oversubscription on very large systems.
  const unsigned threads = std::min<unsigned>(hc, 16);
  // Scale iterations modestly with threads but cap to keep test fast.
  const int iters = (threads <= 4 ? 2500 : 2000);
  std::cout << "   > Using " << threads << " threads (hw_conc=" << hc << ")"
            << std::endl;
  std::atomic<size_t> totalAllocated{0};
  auto worker = [&]() {
    size_t local = 0;
    for (int i = 0; i < iters; ++i) {
      size_t sz = ((i % 13) + 1) * 48;  // variable size
      void* p = malloc(sz);
      if (!p) continue;
      size_t us = malloc_usable_size(p);
      EXPECT_GE(us, sz);
      local += us;
      if ((i % 5) == 0) {
        // occasional realloc
        void* np = realloc(p, sz * 2);
        if (np) {
          p = np;
          size_t us2 = malloc_usable_size(p);
          EXPECT_GE(us2, sz * 2);
          local += us2;
        }
      }
      free(p);
    }
    totalAllocated.fetch_add(local, std::memory_order_relaxed);
  };

  std::vector<std::thread> pool;
  pool.reserve(threads);
  for (int t = 0; t < threads; ++t) pool.emplace_back(worker);
  for (auto& th : pool) th.join();

  std::cout << "   > Total (approx) allocated/checked over threads: "
            << totalAllocated.load() << " bytes\n";
  EXPECT_GT(totalAllocated.load(), 0u);
}

// Final report test
TEST_F(JemallocComprehensiveTest, FinalReport) {
  std::cout << "\n" << std::string(60, '=') << "\n";
  std::cout << "JEMALLOC COMPREHENSIVE TEST SUMMARY\n";
  std::cout << std::string(60, '=') << "\n";

  // Final verification of drop-in mode
  void* test_ptr = malloc(100);
  bool drop_in_works = (malloc_usable_size(test_ptr) > 0);
  free(test_ptr);

  // Verify public API
  void* ext_ptr = mallocx(100, 0);
  bool public_api_works = (ext_ptr != nullptr);
  if (ext_ptr) dallocx(ext_ptr, 0);

  if (drop_in_works) {
    std::cout << "DROP-IN MODE: WORKING\n";
    std::cout << "   malloc/free are replaced by jemalloc\n";
  } else {
    std::cout << "DROP-IN MODE: NOT WORKING\n";
    std::cout << "   malloc/free are using system allocator\n";
  }

  if (public_api_works) {
    std::cout << "PUBLIC API: WORKING\n";
    std::cout << "   mallocx/dallocx are available\n";
  } else {
    std::cout << "PUBLIC API: NOT WORKING\n";
    std::cout << "   mallocx/dallocx are not available\n";
  }

  // Get final statistics
  size_t allocated = 0;
  size_t sz = sizeof(allocated);
  if (mallctl("stats.allocated", &allocated, &sz, nullptr, 0) == 0) {
    std::cout << "CURRENT MEMORY: " << allocated << " bytes allocated\n";
  }

  std::cout << std::string(60, '=') << "\n";

  // Assert key functionality
  EXPECT_TRUE(drop_in_works) << "jemalloc drop-in replacement MUST work!";
  EXPECT_TRUE(public_api_works)
      << "jemalloc extended API (mallocx/dallocx) MUST work!";

  if (drop_in_works && public_api_works) {
    std::cout << "ALL TESTS PASSED: jemalloc is fully functional!\n";
  }
}
