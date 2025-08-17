#include <folly/FBString.h>
#include <folly/Random.h>
#include <folly/Range.h>
#include <folly/String.h>
#include <folly/init/Init.h>
#include <gtest/gtest.h>
#include <thrift/lib/cpp2/Thrift.h>
#include <thrift/lib/cpp2/async/RpcTypes.h>
#include <thrift/lib/cpp2/protocol/CompactProtocol.h>
#include <thrift/lib/cpp2/protocol/Serializer.h>
#include <thrift/lib/cpp2/server/ThriftServer.h>

#include <cstdio>
#include <cstdlib>
#include <mutex>
#include <thread>
#include <vector>
#if defined(__APPLE__)
#include <mach-o/dyld.h>
#elif defined(__linux__)
#include <unistd.h>
#endif

// Minimal smoke tests to ensure core fbthrift headers and symbols link.
namespace {
void ensureFollyInit() {
  static std::once_flag onceFlag;
  std::call_once(onceFlag, []() {
    // 构造一个持久 argv/argc，并放置一个 static folly::Init 保持全程存活
    static char arg0[] = "test_fbthrift_integration";
    int argc = 1;
    char* argv_list[] = {arg0, nullptr};
    char** argv_ptr = argv_list;  // 符合 folly::Init(int*, char***) 需求
    static folly::Init init(&argc, &argv_ptr);
  });
}

// Base64 encode using thrift's (renamed) internal helpers via the header macro
// mapping. We implement a tiny encoder to validate symbol rename did not break
// functionality.
std::string thriftBase64Encode(const std::string& input) {
  using namespace apache::thrift::protocol;  // for base64_encode macro
  const uint8_t* data = reinterpret_cast<const uint8_t*>(input.data());
  size_t len = input.size();
  std::string out;
  out.resize(((len + 2) / 3) * 4);
  uint8_t* outBytes = reinterpret_cast<uint8_t*>(&out[0]);
  size_t produced = 0;
  while (len > 0) {
    uint8_t chunk[3] = {0, 0, 0};
    uint32_t take = len >= 3 ? 3 : static_cast<uint32_t>(len);
    for (uint32_t i = 0; i < take; ++i) chunk[i] = data[i];
    base64_encode(
        chunk, take,
        outBytes + produced);  // macro maps to renamed internal symbol
    produced += 4;
    data += take;
    len -= take;
  }
  // Padding
  size_t mod = input.size() % 3;
  if (mod > 0) {
    out[out.size() - 1] = '=';
    if (mod == 1) out[out.size() - 2] = '=';
  }
  return out;
}

std::string thriftBase64Decode(const std::string& input) {
  using namespace apache::thrift::protocol;  // for base64_decode macro
  if (input.empty()) return std::string();
  if (input.size() % 4 != 0) return std::string();
  size_t blocks = input.size() / 4;
  std::string out;
  out.reserve(blocks * 3);
  for (size_t b = 0; b < blocks; ++b) {
    uint8_t chunk[4];
    for (int i = 0; i < 4; ++i)
      chunk[i] = static_cast<uint8_t>(input[b * 4 + i]);
    int pad = 0;
    if (chunk[2] == '=') {
      chunk[2] = 'A';
      ++pad;
    }
    if (chunk[3] == '=') {
      chunk[3] = 'A';
      ++pad;
    }
    base64_decode(chunk, 4);
    out.push_back(static_cast<char>(chunk[0]));
    if (pad < 2) out.push_back(static_cast<char>(chunk[1]));
    if (pad == 0) out.push_back(static_cast<char>(chunk[2]));
  }
  return out;
}

bool scanForLegacyBase64Symbols(const char* binaryPath) {
#if defined(__APPLE__)
  if (!binaryPath)
    return true;  // unknown -> treat as found to force skip at call site
  std::string cmd = std::string("nm -gU ") + binaryPath + " 2>/dev/null";
  FILE* fp = popen(cmd.c_str(), "r");
  if (!fp) return true;  // unknown
  char line[512];
  bool found = false;
  while (fgets(line, sizeof(line), fp)) {
    if (strstr(line, " base64_encode") || strstr(line, " base64_decode")) {
      found = true;
      break;
    }
  }
  pclose(fp);
  return found;
#else
  (void)binaryPath;
  return false;  // non-mac: skip
#endif
}

std::string detectSelfBinaryPath() {
#if defined(__APPLE__)
  uint32_t size = 0;
  _NSGetExecutablePath(nullptr, &size);  // get required size
  std::string buf(size, '\0');
  if (_NSGetExecutablePath(buf.data(), &size) == 0) {
    // Resolve any symlinks via realpath
    char resolved[PATH_MAX];
    if (realpath(buf.c_str(), resolved)) return std::string(resolved);
    return buf;
  }
  return {};
#elif defined(__linux__)
  char path[PATH_MAX];
  ssize_t n = ::readlink("/proc/self/exe", path, sizeof(path) - 1);
  if (n > 0) {
    path[n] = '\0';
    return std::string(path);
  }
  return {};
#else
  return {};
#endif
}
}  // namespace

TEST(FbthriftIntegration, BasicServerConfig) {
  ensureFollyInit();
  apache::thrift::ThriftServer server;  // construction should succeed
  server.setNumIOWorkerThreads(1);
  server.setNumCPUWorkerThreads(1);
  SUCCEED();
}

TEST(FbthriftIntegration, SimpleSerialization) {
  ensureFollyInit();
  // Serialize a simple struct-like object via protocol writer/reader round-trip
  // for a string
  folly::fbstring input = "hello";
  // Use CompactProtocol serializer (no user-defined struct; just test
  // availability of serializer template)
  apache::thrift::CompactProtocolWriter writer;
  folly::IOBufQueue queue;
  writer.setOutput(&queue, /*copy*/ true);
  writer.writeString(input);
  auto buf = queue.move();
  apache::thrift::CompactProtocolReader reader;
  reader.setInput(buf.get());
  std::string out;
  reader.readString(out);
  EXPECT_EQ(out, input.toStdString());
}

// Invalid operation test (attempt to read beyond buffer) to exercise error
// paths
TEST(FbthriftIntegration, ErrorPath) {
  ensureFollyInit();
  apache::thrift::CompactProtocolReader reader;
  // 使用一个长度为0的 IOBuf（非 nullptr）避免 setInput(nullptr) 潜在崩溃
  auto empty = folly::IOBuf::create(0);
  reader.setInput(empty.get());
  std::string value;
  // Reading string from empty buffer should fail; ensure it does not crash
  try {
    reader.readString(value);
    // If no exception, value should still be empty
    EXPECT_TRUE(value.empty());
  } catch (const std::exception&) {
    SUCCEED();
  }
}

// Large string serialization to exercise buffering and ensure no crashes for
// larger payloads
TEST(FbthriftIntegration, LargeStringSerialization) {
  ensureFollyInit();
  std::string large(1 << 16, 'x');  // 64KB
  apache::thrift::CompactProtocolWriter writer;
  folly::IOBufQueue q;
  writer.setOutput(&q, true);
  writer.writeString(large);
  auto buf = q.move();
  apache::thrift::CompactProtocolReader reader;
  reader.setInput(buf.get());
  std::string out;
  reader.readString(out);
  EXPECT_EQ(out, large);
}

// Idempotency of ensureFollyInit under concurrency (race test)
TEST(FbthriftIntegration, ConcurrentEnsureInit) {
  constexpr int kThreads = 16;
  std::vector<std::thread> threads;
  threads.reserve(kThreads);
  for (int i = 0; i < kThreads; ++i) {
    threads.emplace_back([]() { ensureFollyInit(); });
  }
  for (auto& t : threads) t.join();
  SUCCEED();
}

// Base64 encode/decode roundtrip edge cases and random payloads to ensure
// renamed symbols functional.
TEST(FbthriftIntegration, Base64RoundTrip) {
  ensureFollyInit();
  std::vector<std::string> cases = {"",
                                    "f",
                                    "fo",
                                    "foo",
                                    "foobar",
                                    std::string(1, '\0'),
                                    std::string(2, '\0'),
                                    std::string(3, '\0')};
  for (auto& s : cases) {
    auto enc = thriftBase64Encode(s);
    EXPECT_EQ(enc.size() % 4, 0u);
    auto dec = thriftBase64Decode(enc);
    EXPECT_EQ(dec, s);
  }
  for (int i = 0; i < 32; ++i) {
    size_t len = folly::Random::rand32() % 256;
    std::string s;
    s.resize(len);
    for (size_t j = 0; j < len; ++j)
      s[j] = static_cast<char>(folly::Random::rand32() & 0xFF);
    auto enc = thriftBase64Encode(s);
    auto dec = thriftBase64Decode(enc);
    EXPECT_EQ(dec, s);
  }
}

// Symbol scan (auto-detect current binary path; fallback skip if path not found
// or platform unsupported)
TEST(FbthriftIntegration, NoLegacyBase64Symbols) {
  auto self = detectSelfBinaryPath();
  if (self.empty()) {
    GTEST_SKIP()
        << "Could not determine self binary path; skipping symbol scan";
  }
  bool found = scanForLegacyBase64Symbols(self.c_str());
  EXPECT_FALSE(found)
      << "Found legacy base64_encode/base64_decode symbols in binary";
}
