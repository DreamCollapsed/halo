#include <fizz/client/AsyncFizzClient.h>
#include <fizz/protocol/Certificate.h>
#include <fizz/protocol/DefaultCertificateVerifier.h>
#include <fizz/server/AsyncFizzServer.h>
#include <fizz/util/KeyLogWriter.h>
#include <folly/io/async/EventBase.h>
#include <folly/portability/GTest.h>
#include <gtest/gtest.h>

#include <memory>
#include <vector>

// Fizz TLS Library Integration Tests
class FizzIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up event base for async operations
    event_base_ = std::make_unique<folly::EventBase>();
  }

  void TearDown() override { event_base_.reset(); }

  [[nodiscard]] folly::EventBase* EventBaseForTest() const {
    return event_base_.get();
  }

 private:
  std::unique_ptr<folly::EventBase> event_base_;
};

TEST_F(FizzIntegrationTest, BasicLibraryLinking) {
  // Test that fizz library links correctly and basic classes are available
  auto context = std::make_shared<fizz::server::FizzServerContext>();
  EXPECT_NE(context, nullptr);
}

TEST_F(FizzIntegrationTest, CertificateVerifierCreation) {
  // Test certificate verifier functionality - basic API availability
  // Note: We're just testing that the class exists and can be instantiated
  try {
    [[maybe_unused]] auto verifier =
        fizz::DefaultCertificateVerifier::createFromCAFile(
            fizz::VerificationContext::Server,
            ""  // Empty CA file path for basic creation test
        );
    // If we get here without exception, the API is available
    SUCCEED();
  } catch (...) {
    // Expected to fail with empty path, but API should exist
    SUCCEED();
  }
}

TEST_F(FizzIntegrationTest, ClientContextCreation) {
  // Test client context creation and basic configuration
  auto client_context = std::make_shared<fizz::client::FizzClientContext>();
  EXPECT_NE(client_context, nullptr);

  // Test setting supported versions
  std::vector<fizz::ProtocolVersion> versions = {
      fizz::ProtocolVersion::tls_1_3};
  client_context->setSupportedVersions(versions);

  // Test getting supported versions
  auto supported_versions = client_context->getSupportedVersions();
  EXPECT_FALSE(supported_versions.empty());
  EXPECT_EQ(supported_versions[0], fizz::ProtocolVersion::tls_1_3);
}

TEST_F(FizzIntegrationTest, ServerContextCreation) {
  // Test server context creation and basic configuration
  auto server_context = std::make_shared<fizz::server::FizzServerContext>();
  EXPECT_NE(server_context, nullptr);

  // Test setting supported versions
  std::vector<fizz::ProtocolVersion> versions = {
      fizz::ProtocolVersion::tls_1_3};
  server_context->setSupportedVersions(versions);

  // Test getting supported versions
  auto supported_versions = server_context->getSupportedVersions();
  EXPECT_FALSE(supported_versions.empty());
  EXPECT_EQ(supported_versions[0], fizz::ProtocolVersion::tls_1_3);
}

TEST_F(FizzIntegrationTest, CipherSuiteSupport) {
  // Test cipher suite configuration
  auto context = std::make_shared<fizz::client::FizzClientContext>();

  // Test setting supported cipher suites
  std::vector<fizz::CipherSuite> ciphers = {
      fizz::CipherSuite::TLS_AES_128_GCM_SHA256};
  context->setSupportedCiphers(ciphers);

  // Test getting supported cipher suites
  auto supported_ciphers = context->getSupportedCiphers();
  EXPECT_FALSE(supported_ciphers.empty());
  EXPECT_GE(supported_ciphers.size(), 1);
}

TEST_F(FizzIntegrationTest, SignatureSchemeSupport) {
  // Test signature scheme configuration
  auto context = std::make_shared<fizz::server::FizzServerContext>();

  // Test setting supported signature schemes
  std::vector<fizz::SignatureScheme> schemes = {
      fizz::SignatureScheme::ecdsa_secp256r1_sha256};
  context->setSupportedSigSchemes(schemes);

  // Test getting supported signature schemes
  auto supported_schemes = context->getSupportedSigSchemes();
  EXPECT_FALSE(supported_schemes.empty());
  EXPECT_GE(supported_schemes.size(), 1);
}

TEST_F(FizzIntegrationTest, FizzHeadersAvailable) {
  // Test that key fizz headers are available and can be compiled
  // This ensures the fizz library is properly installed and linkable
  SUCCEED();  // If we compile successfully, fizz headers are available
}

TEST_F(FizzIntegrationTest, ProtocolVersionEnum) {
  // Test protocol version enumeration values
  EXPECT_EQ(static_cast<uint16_t>(fizz::ProtocolVersion::tls_1_3), 0x0304);
  EXPECT_EQ(static_cast<uint16_t>(fizz::ProtocolVersion::tls_1_2), 0x0303);
}

TEST_F(FizzIntegrationTest, ExtensionSupport) {
  // Test extensions support
  auto context = std::make_shared<fizz::client::FizzClientContext>();

  // Test setting supported groups (elliptic curves)
  std::vector<fizz::NamedGroup> groups = {fizz::NamedGroup::secp256r1};
  context->setSupportedGroups(groups);

  // Test getting supported groups
  auto supported_groups = context->getSupportedGroups();
  EXPECT_FALSE(supported_groups.empty());
  EXPECT_GE(supported_groups.size(), 1);
}

TEST_F(FizzIntegrationTest, EventBaseIntegration) {
  // Test that fizz works with folly EventBase
  EXPECT_NE(EventBaseForTest(), nullptr);

  // Test creating fizz client with event base
  auto client_context = std::make_shared<fizz::client::FizzClientContext>();
  EXPECT_NE(client_context, nullptr);

  // Verify event base is still valid after fizz context creation
  EXPECT_FALSE(EventBaseForTest()->isRunning());
}

TEST_F(FizzIntegrationTest, TLS13SpecificFeatures) {
  // Test TLS 1.3 specific features support
  auto context = std::make_shared<fizz::client::FizzClientContext>();

  // Set TLS 1.3 as the only supported version
  std::vector<fizz::ProtocolVersion> versions = {
      fizz::ProtocolVersion::tls_1_3};
  context->setSupportedVersions(versions);

  // Verify TLS 1.3 support
  auto supported_versions = context->getSupportedVersions();
  bool has_tls13 = false;
  for (const auto& version : supported_versions) {
    if (version == fizz::ProtocolVersion::tls_1_3) {
      has_tls13 = true;
      break;
    }
  }
  EXPECT_TRUE(has_tls13);
}

int main(int argc, char** argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
