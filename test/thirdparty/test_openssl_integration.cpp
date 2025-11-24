#include <gtest/gtest.h>
#include <openssl/crypto.h>
#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/opensslv.h>
#include <openssl/rand.h>

#include <chrono>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

class OpenSSLIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Note: In OpenSSL 3.x, explicit initialization is not required
    // The library initializes itself automatically

    // Set up test data
    test_data_ =
        "Hello, OpenSSL! This is a test message for cryptographic operations.";
  }

  void TearDown() override {
    // Note: In OpenSSL 3.x, explicit cleanup is not required
    // The library cleans up automatically
  }

  [[nodiscard]] const std::string& GetTestData() const { return test_data_; }

 private:
  std::string test_data_;
};

// Test OpenSSL version and basic functionality
TEST_F(OpenSSLIntegrationTest, OpenSSLVersionTest) {
  // Test that we can get the OpenSSL version
  const char* version_text = OpenSSL_version(OPENSSL_VERSION);
  EXPECT_TRUE(version_text != nullptr);

  // Test that we have the expected version (1.1.1w as specified in
  // openssl.cmake)
  std::string version_str(version_text);
  EXPECT_TRUE(version_str.find("1.1.1") != std::string::npos);

  // Test numeric version
  uint64_t version_num = OpenSSL_version_num();
  EXPECT_GT(version_num, 0x1010100FUL);  // OpenSSL 1.1.1w
}

// Test random number generation
TEST_F(OpenSSLIntegrationTest, RandomNumberGenerationTest) {
  // Test random bytes generation
  std::vector<unsigned char> random_bytes(32);
  EXPECT_EQ(
      RAND_bytes(random_bytes.data(), static_cast<int>(random_bytes.size())),
      1);

  // Verify random bytes are not all zeros
  bool all_zeros = true;
  for (const auto& byte : random_bytes) {
    if (byte != 0) {
      all_zeros = false;
      break;
    }
  }
  EXPECT_FALSE(all_zeros);

  // Test that two consecutive calls produce different results
  std::vector<unsigned char> random_bytes2(32);
  EXPECT_EQ(
      RAND_bytes(random_bytes2.data(), static_cast<int>(random_bytes2.size())),
      1);
  EXPECT_NE(
      memcmp(random_bytes.data(), random_bytes2.data(), random_bytes.size()),
      0);
}

// Test SHA256 hash functionality using EVP interface
TEST_F(OpenSSLIntegrationTest, SHA256HashTest) {
  EVP_MD_CTX* mdctx = EVP_MD_CTX_new();
  EXPECT_TRUE(mdctx != nullptr);

  EXPECT_EQ(EVP_DigestInit_ex(mdctx, EVP_sha256(), nullptr), 1);
  EXPECT_EQ(
      EVP_DigestUpdate(mdctx, GetTestData().c_str(), GetTestData().length()),
      1);

  std::vector<unsigned char> hash(EVP_MAX_MD_SIZE);
  unsigned int hash_length = 0;
  EXPECT_EQ(EVP_DigestFinal_ex(mdctx, hash.data(), &hash_length), 1);
  EXPECT_EQ(hash_length, 32U);  // SHA256 produces 32 bytes

  EVP_MD_CTX_free(mdctx);

  // Verify hash is not empty
  bool is_empty = true;
  for (unsigned int i = 0; i < hash_length; ++i) {
    if (hash[i] != 0) {
      is_empty = false;
      break;
    }
  }
  EXPECT_FALSE(is_empty);
}

// Test AES encryption and decryption
TEST_F(OpenSSLIntegrationTest, AESEncryptionTest) {
  // Generate a random key and IV
  std::vector<unsigned char> key(16);          // AES-128 key
  std::vector<unsigned char> init_vector(16);  // AES IV

  EXPECT_EQ(RAND_bytes(key.data(), static_cast<int>(key.size())), 1);
  EXPECT_EQ(
      RAND_bytes(init_vector.data(), static_cast<int>(init_vector.size())), 1);

  // Encrypt data
  EVP_CIPHER_CTX* encrypt_ctx = EVP_CIPHER_CTX_new();
  EXPECT_TRUE(encrypt_ctx != nullptr);

  EXPECT_EQ(EVP_EncryptInit_ex(encrypt_ctx, EVP_aes_128_cbc(), nullptr,
                               key.data(), init_vector.data()),
            1);

  std::vector<unsigned char> encrypted_data(GetTestData().length() +
                                            16);  // Block size is 16 for AES
  int encrypted_len = 0;
  int final_len = 0;

  // Create a buffer for input data to avoid reinterpret_cast
  std::vector<unsigned char> input_data(GetTestData().begin(),
                                        GetTestData().end());

  EXPECT_EQ(
      EVP_EncryptUpdate(encrypt_ctx, encrypted_data.data(), &encrypted_len,
                        input_data.data(), static_cast<int>(input_data.size())),
      1);

  EXPECT_EQ(EVP_EncryptFinal_ex(encrypt_ctx, &encrypted_data[encrypted_len],
                                &final_len),
            1);

  int total_encrypted_len = encrypted_len + final_len;
  encrypted_data.resize(total_encrypted_len);

  EVP_CIPHER_CTX_free(encrypt_ctx);

  // Decrypt data
  EVP_CIPHER_CTX* decrypt_ctx = EVP_CIPHER_CTX_new();
  EXPECT_TRUE(decrypt_ctx != nullptr);

  EXPECT_EQ(EVP_DecryptInit_ex(decrypt_ctx, EVP_aes_128_cbc(), nullptr,
                               key.data(), init_vector.data()),
            1);

  std::vector<unsigned char> decrypted_data(total_encrypted_len);
  int decrypted_len = 0;
  int final_decrypt_len = 0;

  EXPECT_EQ(
      EVP_DecryptUpdate(decrypt_ctx, decrypted_data.data(), &decrypted_len,
                        encrypted_data.data(), total_encrypted_len),
      1);

  EXPECT_EQ(EVP_DecryptFinal_ex(decrypt_ctx, &decrypted_data[decrypted_len],
                                &final_decrypt_len),
            1);

  int total_decrypted_len = decrypted_len + final_decrypt_len;
  decrypted_data.resize(total_decrypted_len);

  EVP_CIPHER_CTX_free(decrypt_ctx);

  // Verify decrypted data matches original
  std::string decrypted_str(decrypted_data.begin(), decrypted_data.end());
  EXPECT_EQ(decrypted_str, GetTestData());
}

// Test error handling
TEST_F(OpenSSLIntegrationTest, ErrorHandlingTest) {
  // Clear error queue
  ERR_clear_error();

  // Force an error by trying to use invalid parameters
  EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
  EXPECT_TRUE(ctx != nullptr);

  // This should fail and set an error
  int result = EVP_EncryptInit_ex(ctx, nullptr, nullptr, nullptr, nullptr);
  EXPECT_EQ(result, 0);  // Should fail

  // Check that error was set
  uint64_t error = ERR_get_error();
  EXPECT_NE(error, 0UL);

  // Get error string
  std::array<char, 256> error_string{};
  ERR_error_string_n(error, error_string.data(), error_string.size());
  EXPECT_TRUE(strlen(error_string.data()) > 0);

  EVP_CIPHER_CTX_free(ctx);
}

// Integration test with real-world scenario
TEST_F(OpenSSLIntegrationTest, RealWorldScenarioTest) {
  // Simulate a scenario where we need to:
  // 1. Generate a hash of some data
  // 2. Encrypt the data

  std::string sensitive_data =
      "This is sensitive information that needs to be protected.";

  // Step 1: Generate hash
  EVP_MD_CTX* hash_ctx = EVP_MD_CTX_new();
  EXPECT_EQ(EVP_DigestInit_ex(hash_ctx, EVP_sha256(), nullptr), 1);
  EXPECT_EQ(EVP_DigestUpdate(hash_ctx, sensitive_data.c_str(),
                             sensitive_data.length()),
            1);

  std::vector<unsigned char> hash(EVP_MAX_MD_SIZE);
  unsigned int hash_length = 0;
  EXPECT_EQ(EVP_DigestFinal_ex(hash_ctx, hash.data(), &hash_length), 1);
  EVP_MD_CTX_free(hash_ctx);

  // Step 2: Encrypt data with AES
  std::vector<unsigned char> key(32);          // AES-256 key
  std::vector<unsigned char> init_vector(16);  // AES IV

  EXPECT_EQ(RAND_bytes(key.data(), static_cast<int>(key.size())), 1);
  EXPECT_EQ(
      RAND_bytes(init_vector.data(), static_cast<int>(init_vector.size())), 1);

  EVP_CIPHER_CTX* encrypt_ctx = EVP_CIPHER_CTX_new();
  EXPECT_EQ(EVP_EncryptInit_ex(encrypt_ctx, EVP_aes_256_cbc(), nullptr,
                               key.data(), init_vector.data()),
            1);

  std::vector<unsigned char> encrypted_data(sensitive_data.length() + 16);
  int encrypted_len = 0;
  int final_len = 0;

  // Create a buffer for input data to avoid reinterpret_cast
  std::vector<unsigned char> input_data(sensitive_data.begin(),
                                        sensitive_data.end());

  EXPECT_EQ(
      EVP_EncryptUpdate(encrypt_ctx, encrypted_data.data(), &encrypted_len,
                        input_data.data(), static_cast<int>(input_data.size())),
      1);

  EXPECT_EQ(EVP_EncryptFinal_ex(encrypt_ctx, &encrypted_data[encrypted_len],
                                &final_len),
            1);

  int total_encrypted_len = encrypted_len + final_len;
  encrypted_data.resize(total_encrypted_len);

  EVP_CIPHER_CTX_free(encrypt_ctx);

  // Verify that we have valid encrypted data and hash
  EXPECT_GT(total_encrypted_len, 0);
  EXPECT_GT(hash_length, 0U);
  EXPECT_NE(encrypted_data, std::vector<unsigned char>(total_encrypted_len, 0));

  // Performance measurement
  auto start = std::chrono::high_resolution_clock::now();
  for (int i = 0; i < 1000; ++i) {
    EVP_MD_CTX* perf_ctx = EVP_MD_CTX_new();
    EVP_DigestInit_ex(perf_ctx, EVP_sha256(), nullptr);
    EVP_DigestUpdate(perf_ctx, sensitive_data.c_str(), sensitive_data.length());
    std::vector<unsigned char> temp_hash(EVP_MAX_MD_SIZE);
    unsigned int temp_len = 0;
    EVP_DigestFinal_ex(perf_ctx, temp_hash.data(), &temp_len);
    EVP_MD_CTX_free(perf_ctx);
  }
  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::microseconds>(end - start);

  std::cout << "1000 SHA256 operations took: " << duration.count()
            << " microseconds" << "\n";

  // Performance should be reasonable (less than 100ms for 1000 operations)
  EXPECT_LT(duration.count(), 100000);
}
