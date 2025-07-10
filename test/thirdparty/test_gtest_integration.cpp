#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <memory>
#include <string>
#include <vector>

using ::testing::_;
using ::testing::AtLeast;
using ::testing::ContainerEq;
using ::testing::ElementsAre;
using ::testing::HasSubstr;
using ::testing::InSequence;
using ::testing::NiceMock;
using ::testing::Return;
using ::testing::StrictMock;

// Mock interface for testing
class MockDatabase {
 public:
  virtual ~MockDatabase() = default;
  virtual bool Connect(const std::string& connection_string) = 0;
  virtual std::string Query(const std::string& sql) = 0;
  virtual int ExecuteUpdate(const std::string& sql) = 0;
  virtual void Disconnect() = 0;
};

// Mock implementation
class MockDatabaseImpl : public MockDatabase {
 public:
  MOCK_METHOD(bool, Connect, (const std::string& connection_string),
              (override));
  MOCK_METHOD(std::string, Query, (const std::string& sql), (override));
  MOCK_METHOD(int, ExecuteUpdate, (const std::string& sql), (override));
  MOCK_METHOD(void, Disconnect, (), (override));
};

// Service class that uses the database
class DatabaseService {
 public:
  explicit DatabaseService(std::unique_ptr<MockDatabase> db)
      : database_(std::move(db)) {}

  bool Initialize(const std::string& connection_string) {
    return database_->Connect(connection_string);
  }

  std::vector<std::string> GetUsers() {
    std::string result = database_->Query("SELECT * FROM users");
    if (result.empty()) {
      return {};
    }
    // Simplified parsing
    return {"user1", "user2", "user3"};
  }

  bool AddUser(const std::string& username) {
    std::string sql = "INSERT INTO users (name) VALUES ('" + username + "')";
    int affected = database_->ExecuteUpdate(sql);
    return affected > 0;
  }

  void Shutdown() { database_->Disconnect(); }

 private:
  std::unique_ptr<MockDatabase> database_;
};

// Test fixture for GTest/GMock integration tests
class GTestIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    mock_db_ = std::make_unique<MockDatabaseImpl>();
    raw_mock_db_ = mock_db_.get();  // Keep raw pointer for expectations
    service_ = std::make_unique<DatabaseService>(std::move(mock_db_));
  }

  void TearDown() override {
    service_.reset();
    raw_mock_db_ = nullptr;
  }

  std::unique_ptr<MockDatabaseImpl> mock_db_;
  MockDatabaseImpl*
      raw_mock_db_;  // Non-owning pointer for setting expectations
  std::unique_ptr<DatabaseService> service_;
};

// Test basic GTest functionality
TEST_F(GTestIntegrationTest, BasicAssertions) {
  // Test basic assertions
  EXPECT_TRUE(true);
  EXPECT_FALSE(false);
  EXPECT_EQ(42, 42);
  EXPECT_NE(1, 2);
  EXPECT_LT(1, 2);
  EXPECT_LE(1, 1);
  EXPECT_GT(2, 1);
  EXPECT_GE(2, 2);

  // Test string assertions
  std::string hello = "Hello, World!";
  EXPECT_STREQ("test", "test");
  EXPECT_STRNE("test", "different");
  EXPECT_THAT(hello, HasSubstr("World"));

  // Test floating point assertions
  EXPECT_FLOAT_EQ(1.0f, 1.0f);
  EXPECT_DOUBLE_EQ(1.0, 1.0);
  EXPECT_NEAR(1.0, 1.1, 0.2);
}

// Test container matchers
TEST_F(GTestIntegrationTest, ContainerMatchers) {
  std::vector<int> numbers = {1, 2, 3, 4, 5};
  std::vector<int> expected = {1, 2, 3, 4, 5};

  EXPECT_THAT(numbers, ContainerEq(expected));
  EXPECT_THAT(numbers, ElementsAre(1, 2, 3, 4, 5));

  std::vector<std::string> words = {"hello", "world", "test"};
  EXPECT_THAT(words, ElementsAre("hello", "world", "test"));
}

// Test exception handling
TEST_F(GTestIntegrationTest, ExceptionHandling) {
  // Test that exceptions are properly caught
  EXPECT_THROW(
      { throw std::runtime_error("Test exception"); }, std::runtime_error);

  EXPECT_NO_THROW({
    int x = 42;
    x = x + 1;
  });

  // Test specific exception message
  try {
    throw std::invalid_argument("Invalid parameter");
  } catch (const std::exception& e) {
    EXPECT_THAT(e.what(), HasSubstr("Invalid"));
  }
}

// Test basic mock functionality
TEST_F(GTestIntegrationTest, BasicMockFunctionality) {
  // Set up expectations
  EXPECT_CALL(*raw_mock_db_, Connect("test_connection")).WillOnce(Return(true));

  EXPECT_CALL(*raw_mock_db_, Query("SELECT * FROM users"))
      .WillOnce(Return("user1,user2,user3"));

  EXPECT_CALL(*raw_mock_db_, Disconnect()).Times(1);

  // Test the service
  EXPECT_TRUE(service_->Initialize("test_connection"));

  std::vector<std::string> users = service_->GetUsers();
  EXPECT_EQ(users.size(), 3);

  service_->Shutdown();
}

// Test mock with multiple calls
TEST_F(GTestIntegrationTest, MockMultipleCalls) {
  // Set up expectations for multiple calls
  EXPECT_CALL(*raw_mock_db_, Connect(_))
      .Times(AtLeast(1))
      .WillRepeatedly(Return(true));

  EXPECT_CALL(*raw_mock_db_, ExecuteUpdate(_))
      .Times(3)
      .WillOnce(Return(1))
      .WillOnce(Return(1))
      .WillOnce(Return(0));  // Third call fails

  // Test multiple operations
  EXPECT_TRUE(service_->Initialize("connection1"));
  EXPECT_TRUE(service_->AddUser("user1"));
  EXPECT_TRUE(service_->AddUser("user2"));
  EXPECT_FALSE(service_->AddUser("user3"));  // Should fail
}

// Test strict mock (all calls must be expected)
TEST_F(GTestIntegrationTest, StrictMockTest) {
  auto strict_mock = std::make_unique<StrictMock<MockDatabaseImpl>>();
  auto* strict_raw = strict_mock.get();
  auto strict_service =
      std::make_unique<DatabaseService>(std::move(strict_mock));

  // With StrictMock, we must expect all calls
  EXPECT_CALL(*strict_raw, Connect("strict_connection")).WillOnce(Return(true));

  EXPECT_TRUE(strict_service->Initialize("strict_connection"));
  // Any unexpected call would cause test failure
}

// Test nice mock (unexpected calls are allowed)
TEST_F(GTestIntegrationTest, NiceMockTest) {
  auto nice_mock = std::make_unique<NiceMock<MockDatabaseImpl>>();
  auto* nice_raw = nice_mock.get();
  auto nice_service = std::make_unique<DatabaseService>(std::move(nice_mock));

  // With NiceMock, unexpected calls return default values
  EXPECT_CALL(*nice_raw, Connect(_)).WillOnce(Return(true));

  EXPECT_TRUE(nice_service->Initialize("nice_connection"));

  // This call is not expected but won't fail the test
  nice_service->GetUsers();  // Returns empty vector by default
}

// Test call sequence
TEST_F(GTestIntegrationTest, CallSequenceTest) {
  InSequence seq;  // Calls must happen in the specified order

  EXPECT_CALL(*raw_mock_db_, Connect(_)).WillOnce(Return(true));

  EXPECT_CALL(*raw_mock_db_, Query(_)).WillOnce(Return("data"));

  EXPECT_CALL(*raw_mock_db_, ExecuteUpdate(_)).WillOnce(Return(1));

  EXPECT_CALL(*raw_mock_db_, Disconnect());

  // Execute in the expected order
  service_->Initialize("test");
  service_->GetUsers();
  service_->AddUser("test_user");
  service_->Shutdown();
}

// Performance test for GTest/GMock
TEST_F(GTestIntegrationTest, PerformanceTest) {
  const int iterations = 1000;

  // Set up expectations for many calls
  EXPECT_CALL(*raw_mock_db_, Query(_))
      .Times(iterations)
      .WillRepeatedly(Return("test_result"));

  auto start = std::chrono::high_resolution_clock::now();

  for (int i = 0; i < iterations; ++i) {
    service_->GetUsers();
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

  // Should complete in reasonable time (less than 1 second)
  EXPECT_LT(duration.count(), 1000);
}

// Test parameter matching
TEST_F(GTestIntegrationTest, ParameterMatching) {
  using ::testing::EndsWith;
  using ::testing::MatchesRegex;
  using ::testing::StartsWith;

  // Test different parameter matchers
  EXPECT_CALL(*raw_mock_db_, Connect(StartsWith("mysql://")))
      .WillOnce(Return(true));

  EXPECT_CALL(*raw_mock_db_, Query(HasSubstr("SELECT")))
      .WillOnce(Return("result"));

  EXPECT_CALL(*raw_mock_db_, ExecuteUpdate(MatchesRegex("INSERT.*users.*")))
      .WillOnce(Return(1));

  // Execute with matching parameters
  service_->Initialize("mysql://localhost:3306/test");
  service_->GetUsers();       // Will call Query with SELECT
  service_->AddUser("test");  // Will call ExecuteUpdate with INSERT
}

int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);

  // Print version and feature information
  std::cout << "Testing GTest/GMock integration..." << std::endl;
  std::cout << "Death tests supported: " << GTEST_HAS_DEATH_TEST << std::endl;
  std::cout << "Typed tests supported: " << GTEST_HAS_TYPED_TEST << std::endl;

  return RUN_ALL_TESTS();
}
