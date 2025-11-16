// Centralized Velox test environment initialization.
// Provides one-time MemoryManager initialization to avoid per-TU duplication
// and to ensure any cache-related types are fully defined in this TU only.

#include <velox/common/memory/Memory.h>

namespace {
struct VeloxTestEnvOnce {
  VeloxTestEnvOnce() {
    using facebook::velox::memory::MemoryManager;
    if (!MemoryManager::testInstance()) {
      MemoryManager::initialize(MemoryManager::Options{});
    }
  }
};

const VeloxTestEnvOnce VELOX_TEST_ENV_ONCE;
}  // namespace
