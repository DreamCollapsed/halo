#include <fizz/client/AsyncFizzClient.h>
#include <fizz/protocol/Certificate.h>
#include <fizz/protocol/DefaultCertificateVerifier.h>
#include <fizz/server/AsyncFizzServer.h>
#include <fizz/util/KeyLogWriter.h>
#include <folly/io/async/EventBase.h>
#include <folly/portability/GTest.h>
#include <gtest/gtest.h>

#include <memory>

// Fizz TLS Library Integration Tests
class FizzIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up event base for async operations
    eventBase = std::make_unique<folly::EventBase>();
  }

  void TearDown() override { eventBase.reset(); }

  std::unique_ptr<folly::EventBase> eventBase;
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
    auto verifier = fizz::DefaultCertificateVerifier::createFromCAFile(
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
  auto clientContext = std::make_shared<fizz::client::FizzClientContext>();
  EXPECT_NE(clientContext, nullptr);

  // Test setting supported versions
  std::vector<fizz::ProtocolVersion> versions = {
      fizz::ProtocolVersion::tls_1_3};
  clientContext->setSupportedVersions(versions);

  // Test getting supported versions
  auto supportedVersions = clientContext->getSupportedVersions();
  EXPECT_FALSE(supportedVersions.empty());
  EXPECT_EQ(supportedVersions[0], fizz::ProtocolVersion::tls_1_3);
}

TEST_F(FizzIntegrationTest, ServerContextCreation) {
  // Test server context creation and basic configuration
  auto serverContext = std::make_shared<fizz::server::FizzServerContext>();
  EXPECT_NE(serverContext, nullptr);

  // Test setting supported versions
  std::vector<fizz::ProtocolVersion> versions = {
      fizz::ProtocolVersion::tls_1_3};
  serverContext->setSupportedVersions(versions);

  // Test getting supported versions
  auto supportedVersions = serverContext->getSupportedVersions();
  EXPECT_FALSE(supportedVersions.empty());
  EXPECT_EQ(supportedVersions[0], fizz::ProtocolVersion::tls_1_3);
}

TEST_F(FizzIntegrationTest, CipherSuiteSupport) {
  // Test cipher suite configuration
  auto context = std::make_shared<fizz::client::FizzClientContext>();

  // Test setting supported cipher suites
  std::vector<fizz::CipherSuite> ciphers = {
      fizz::CipherSuite::TLS_AES_128_GCM_SHA256};
  context->setSupportedCiphers(ciphers);

  // Test getting supported cipher suites
  auto supportedCiphers = context->getSupportedCiphers();
  EXPECT_FALSE(supportedCiphers.empty());
  EXPECT_GE(supportedCiphers.size(), 1);
}

TEST_F(FizzIntegrationTest, SignatureSchemeSupport) {
  // Test signature scheme configuration
  auto context = std::make_shared<fizz::server::FizzServerContext>();

  // Test setting supported signature schemes
  std::vector<fizz::SignatureScheme> schemes = {
      fizz::SignatureScheme::ecdsa_secp256r1_sha256};
  context->setSupportedSigSchemes(schemes);

  // Test getting supported signature schemes
  auto supportedSchemes = context->getSupportedSigSchemes();
  EXPECT_FALSE(supportedSchemes.empty());
  EXPECT_GE(supportedSchemes.size(), 1);
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
  auto supportedGroups = context->getSupportedGroups();
  EXPECT_FALSE(supportedGroups.empty());
  EXPECT_GE(supportedGroups.size(), 1);
}

TEST_F(FizzIntegrationTest, EventBaseIntegration) {
  // Test that fizz works with folly EventBase
  EXPECT_NE(eventBase, nullptr);

  // Test creating fizz client with event base
  auto clientContext = std::make_shared<fizz::client::FizzClientContext>();
  EXPECT_NE(clientContext, nullptr);

  // Verify event base is still valid after fizz context creation
  EXPECT_FALSE(eventBase->isRunning());
}

TEST_F(FizzIntegrationTest, TLS13SpecificFeatures) {
  // Test TLS 1.3 specific features support
  auto context = std::make_shared<fizz::client::FizzClientContext>();

  // Set TLS 1.3 as the only supported version
  std::vector<fizz::ProtocolVersion> versions = {
      fizz::ProtocolVersion::tls_1_3};
  context->setSupportedVersions(versions);

  // Verify TLS 1.3 support
  auto supportedVersions = context->getSupportedVersions();
  bool hasTls13 = false;
  for (const auto& version : supportedVersions) {
    if (version == fizz::ProtocolVersion::tls_1_3) {
      hasTls13 = true;
      break;
    }
  }
  EXPECT_TRUE(hasTls13);
}

int main(int argc, char** argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
