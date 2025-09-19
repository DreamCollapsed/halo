// Centralized Velox test environment initialization.
// Provides one-time MemoryManager initialization to avoid per-TU duplication
// and to ensure any cache-related types are fully defined in this TU only.

#include <velox/common/memory/Memory.h>

namespace {
struct VeloxTestEnvOnce {
  VeloxTestEnvOnce() {
    using namespace facebook::velox::memory;
    if (!MemoryManager::testInstance()) {
      MemoryManager::initialize(MemoryManager::Options{});
    }
  }
};

static VeloxTestEnvOnce kVeloxTestEnvOnce;
}  // namespace
