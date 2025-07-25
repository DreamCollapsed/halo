#include <gtest/gtest.h>
#include <sodium.h>

#include <cstring>
#include <random>
#include <string>
#include <vector>

// Test fixture for libsodium integration tests
class LibsodiumIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Initialize libsodium
    if (sodium_init() < 0) {
      FAIL() << "Failed to initialize libsodium";
    }
  }

  void TearDown() override {
    // libsodium doesn't require explicit cleanup
  }
};

// Test basic libsodium initialization
TEST_F(LibsodiumIntegrationTest, BasicInitialization) {
  // Test that sodium_init() was successful
  EXPECT_GE(sodium_init(), 0);

  // Test basic version information
  EXPECT_NE(sodium_version_string(), nullptr);
  std::string version(sodium_version_string());
  EXPECT_FALSE(version.empty());

  std::cout << "libsodium version: " << version << std::endl;
}

// Test random number generation
TEST_F(LibsodiumIntegrationTest, RandomGeneration) {
  constexpr size_t BUFFER_SIZE = 32;

  // Test random bytes generation
  std::vector<unsigned char> random_bytes1(BUFFER_SIZE);
  std::vector<unsigned char> random_bytes2(BUFFER_SIZE);

  randombytes_buf(random_bytes1.data(), BUFFER_SIZE);
  randombytes_buf(random_bytes2.data(), BUFFER_SIZE);

  // The two random buffers should be different
  EXPECT_NE(random_bytes1, random_bytes2);

  // Test random uint32 generation
  uint32_t random_uint1 = randombytes_random();
  uint32_t random_uint2 = randombytes_random();

  // Should be different (extremely unlikely to be the same)
  EXPECT_NE(random_uint1, random_uint2);
}

// Test secret key box (authenticated encryption)
TEST_F(LibsodiumIntegrationTest, SecretKeyBox) {
  const std::string message = "Hello, libsodium!";

  // Generate a random key and nonce
  std::vector<unsigned char> key(crypto_secretbox_KEYBYTES);
  std::vector<unsigned char> nonce(crypto_secretbox_NONCEBYTES);

  crypto_secretbox_keygen(key.data());
  randombytes_buf(nonce.data(), crypto_secretbox_NONCEBYTES);

  // Encrypt the message
  std::vector<unsigned char> ciphertext(message.size() +
                                        crypto_secretbox_MACBYTES);
  int encrypt_result = crypto_secretbox_easy(
      ciphertext.data(),
      reinterpret_cast<const unsigned char*>(message.c_str()), message.size(),
      nonce.data(), key.data());

  EXPECT_EQ(encrypt_result, 0);

  // Decrypt the message
  std::vector<unsigned char> decrypted(message.size());
  int decrypt_result =
      crypto_secretbox_open_easy(decrypted.data(), ciphertext.data(),
                                 ciphertext.size(), nonce.data(), key.data());

  EXPECT_EQ(decrypt_result, 0);

  // Verify decrypted message matches original
  std::string decrypted_message(reinterpret_cast<char*>(decrypted.data()),
                                message.size());
  EXPECT_EQ(decrypted_message, message);
}

// Test public key cryptography (key exchange)
TEST_F(LibsodiumIntegrationTest, PublicKeyCryptography) {
  // Generate Alice's keypair
  std::vector<unsigned char> alice_pk(crypto_box_PUBLICKEYBYTES);
  std::vector<unsigned char> alice_sk(crypto_box_SECRETKEYBYTES);
  crypto_box_keypair(alice_pk.data(), alice_sk.data());

  // Generate Bob's keypair
  std::vector<unsigned char> bob_pk(crypto_box_PUBLICKEYBYTES);
  std::vector<unsigned char> bob_sk(crypto_box_SECRETKEYBYTES);
  crypto_box_keypair(bob_pk.data(), bob_sk.data());

  const std::string message = "Secret message from Alice to Bob";

  // Generate nonce
  std::vector<unsigned char> nonce(crypto_box_NONCEBYTES);
  randombytes_buf(nonce.data(), crypto_box_NONCEBYTES);

  // Alice encrypts message for Bob
  std::vector<unsigned char> ciphertext(message.size() + crypto_box_MACBYTES);
  int encrypt_result =
      crypto_box_easy(ciphertext.data(),
                      reinterpret_cast<const unsigned char*>(message.c_str()),
                      message.size(), nonce.data(),
                      bob_pk.data(),   // Bob's public key
                      alice_sk.data()  // Alice's secret key
      );

  EXPECT_EQ(encrypt_result, 0);

  // Bob decrypts message from Alice
  std::vector<unsigned char> decrypted(message.size());
  int decrypt_result = crypto_box_open_easy(
      decrypted.data(), ciphertext.data(), ciphertext.size(), nonce.data(),
      alice_pk.data(),  // Alice's public key
      bob_sk.data()     // Bob's secret key
  );

  EXPECT_EQ(decrypt_result, 0);

  // Verify decrypted message matches original
  std::string decrypted_message(reinterpret_cast<char*>(decrypted.data()),
                                message.size());
  EXPECT_EQ(decrypted_message, message);
}

// Test digital signatures
TEST_F(LibsodiumIntegrationTest, DigitalSignatures) {
  // Generate signing keypair
  std::vector<unsigned char> pk(crypto_sign_PUBLICKEYBYTES);
  std::vector<unsigned char> sk(crypto_sign_SECRETKEYBYTES);
  crypto_sign_keypair(pk.data(), sk.data());

  const std::string message = "This message needs to be signed";

  // Sign the message
  std::vector<unsigned char> signed_message(message.size() + crypto_sign_BYTES);
  unsigned long long signed_message_len;

  int sign_result =
      crypto_sign(signed_message.data(), &signed_message_len,
                  reinterpret_cast<const unsigned char*>(message.c_str()),
                  message.size(), sk.data());

  EXPECT_EQ(sign_result, 0);
  EXPECT_EQ(signed_message_len, message.size() + crypto_sign_BYTES);

  // Verify the signature
  std::vector<unsigned char> verified_message(message.size());
  unsigned long long verified_message_len;

  int verify_result =
      crypto_sign_open(verified_message.data(), &verified_message_len,
                       signed_message.data(), signed_message_len, pk.data());

  EXPECT_EQ(verify_result, 0);
  EXPECT_EQ(verified_message_len, message.size());

  // Verify the message content
  std::string verified_message_str(
      reinterpret_cast<char*>(verified_message.data()), verified_message_len);
  EXPECT_EQ(verified_message_str, message);
}

// Test hashing functionality
TEST_F(LibsodiumIntegrationTest, Hashing) {
  const std::string message = "Message to hash";

  // Test generic hash (BLAKE2b-based)
  std::vector<unsigned char> hash1(crypto_generichash_BYTES);
  crypto_generichash(hash1.data(), crypto_generichash_BYTES,
                     reinterpret_cast<const unsigned char*>(message.c_str()),
                     message.size(), nullptr, 0);

  // Hash the same message again
  std::vector<unsigned char> hash2(crypto_generichash_BYTES);
  crypto_generichash(hash2.data(), crypto_generichash_BYTES,
                     reinterpret_cast<const unsigned char*>(message.c_str()),
                     message.size(), nullptr, 0);

  // Hashes should be identical
  EXPECT_EQ(hash1, hash2);

  // Hash a different message
  const std::string different_message = "Different message to hash";
  std::vector<unsigned char> hash3(crypto_generichash_BYTES);
  crypto_generichash(
      hash3.data(), crypto_generichash_BYTES,
      reinterpret_cast<const unsigned char*>(different_message.c_str()),
      different_message.size(), nullptr, 0);

  // Hash should be different
  EXPECT_NE(hash1, hash3);
}

// Test password hashing and verification
TEST_F(LibsodiumIntegrationTest, PasswordHashing) {
  const std::string password = "my_super_secret_password";

  // Hash the password
  std::vector<char> hashed_password(crypto_pwhash_STRBYTES);
  int hash_result = crypto_pwhash_str(
      hashed_password.data(), password.c_str(), password.length(),
      crypto_pwhash_OPSLIMIT_INTERACTIVE, crypto_pwhash_MEMLIMIT_INTERACTIVE);

  EXPECT_EQ(hash_result, 0);

  // Verify the password
  int verify_result = crypto_pwhash_str_verify(
      hashed_password.data(), password.c_str(), password.length());

  EXPECT_EQ(verify_result, 0);

  // Try with wrong password
  const std::string wrong_password = "wrong_password";
  int wrong_verify_result = crypto_pwhash_str_verify(
      hashed_password.data(), wrong_password.c_str(), wrong_password.length());

  EXPECT_NE(wrong_verify_result, 0);
}

// Test memory utilities
TEST_F(LibsodiumIntegrationTest, MemoryUtilities) {
  constexpr size_t BUFFER_SIZE = 64;

  // Test secure memory allocation
  unsigned char* secure_buffer =
      static_cast<unsigned char*>(sodium_malloc(BUFFER_SIZE));
  EXPECT_NE(secure_buffer, nullptr);

  // Fill with some data
  randombytes_buf(secure_buffer, BUFFER_SIZE);

  // Test memory protection (make read-only)
  int protect_result = sodium_mprotect_readonly(secure_buffer);
  EXPECT_EQ(protect_result, 0);

  // Make it writable again for cleanup
  int noaccess_result = sodium_mprotect_readwrite(secure_buffer);
  EXPECT_EQ(noaccess_result, 0);

  // Free secure memory
  sodium_free(secure_buffer);

  // Test constant-time memory comparison
  unsigned char buffer1[16] = {1, 2,  3,  4,  5,  6,  7,  8,
                               9, 10, 11, 12, 13, 14, 15, 16};
  unsigned char buffer2[16] = {1, 2,  3,  4,  5,  6,  7,  8,
                               9, 10, 11, 12, 13, 14, 15, 16};
  unsigned char buffer3[16] = {1, 2,  3,  4,  5,  6,  7,  8,
                               9, 10, 11, 12, 13, 14, 15, 17};

  EXPECT_EQ(sodium_memcmp(buffer1, buffer2, 16), 0);
  EXPECT_NE(sodium_memcmp(buffer1, buffer3, 16), 0);
}

// Test constant-time operations
TEST_F(LibsodiumIntegrationTest, ConstantTimeOperations) {
  // Test constant-time comparison
  EXPECT_EQ(sodium_is_zero(nullptr, 0), 1);

  unsigned char zero_buffer[16] = {0};
  unsigned char nonzero_buffer[16] = {0, 0, 0, 0, 0, 0, 0, 0,
                                      0, 0, 0, 0, 0, 0, 0, 1};

  EXPECT_EQ(sodium_is_zero(zero_buffer, 16), 1);
  EXPECT_EQ(sodium_is_zero(nonzero_buffer, 16), 0);

  // Test increment function
  unsigned char counter[8] = {255, 0, 0, 0, 0, 0, 0, 0};
  sodium_increment(counter, 8);

  // Should have carried over to the next byte (little-endian)
  EXPECT_EQ(counter[0], 0);
  EXPECT_EQ(counter[1], 1);
}

// Performance and stress test
TEST_F(LibsodiumIntegrationTest, PerformanceTest) {
  constexpr size_t NUM_ITERATIONS = 1000;
  constexpr size_t MESSAGE_SIZE = 1024;

  // Generate test data
  std::vector<unsigned char> message(MESSAGE_SIZE);
  randombytes_buf(message.data(), MESSAGE_SIZE);

  // Generate key for secret box
  std::vector<unsigned char> key(crypto_secretbox_KEYBYTES);
  crypto_secretbox_keygen(key.data());

  auto start_time = std::chrono::high_resolution_clock::now();

  // Perform multiple encrypt/decrypt cycles
  for (size_t i = 0; i < NUM_ITERATIONS; ++i) {
    std::vector<unsigned char> nonce(crypto_secretbox_NONCEBYTES);
    randombytes_buf(nonce.data(), crypto_secretbox_NONCEBYTES);

    std::vector<unsigned char> ciphertext(MESSAGE_SIZE +
                                          crypto_secretbox_MACBYTES);
    crypto_secretbox_easy(ciphertext.data(), message.data(), MESSAGE_SIZE,
                          nonce.data(), key.data());

    std::vector<unsigned char> decrypted(MESSAGE_SIZE);
    int result =
        crypto_secretbox_open_easy(decrypted.data(), ciphertext.data(),
                                   ciphertext.size(), nonce.data(), key.data());

    ASSERT_EQ(result, 0);
    ASSERT_EQ(std::memcmp(message.data(), decrypted.data(), MESSAGE_SIZE), 0);
  }

  auto end_time = std::chrono::high_resolution_clock::now();
  auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
      end_time - start_time);

  std::cout << "Performed " << NUM_ITERATIONS << " encrypt/decrypt cycles of "
            << MESSAGE_SIZE << " bytes in " << duration.count() << " ms"
            << std::endl;

  // Should complete within reasonable time (adjust as needed)
  EXPECT_LT(duration.count(), 10000);  // Less than 10 seconds
}
