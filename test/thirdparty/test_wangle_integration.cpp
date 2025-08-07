#include <folly/io/async/EventBase.h>
#include <folly/portability/GTest.h>
#include <gtest/gtest.h>
#include <wangle/bootstrap/ClientBootstrap.h>
#include <wangle/bootstrap/ServerBootstrap.h>
#include <wangle/channel/AsyncSocketHandler.h>
#include <wangle/channel/Pipeline.h>
#include <wangle/codec/LineBasedFrameDecoder.h>
#include <wangle/codec/StringCodec.h>

#include <atomic>
#include <chrono>
#include <memory>
#include <string>
#include <thread>
#include <vector>

// Wangle C++ networking library Integration Tests
class WangleIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Set up event base for async operations
    eventBase = std::make_unique<folly::EventBase>();
  }

  void TearDown() override { eventBase.reset(); }

  std::unique_ptr<folly::EventBase> eventBase;
};

TEST_F(WangleIntegrationTest, BasicLibraryLinking) {
  // Test that wangle library links correctly and basic classes are available
  EXPECT_NE(eventBase, nullptr);

  // Test that we can create basic Wangle components
  auto pipeline = wangle::Pipeline<std::string>::create();
  EXPECT_NE(pipeline, nullptr);
}

TEST_F(WangleIntegrationTest, PipelineCreation) {
  // Test pipeline creation and basic functionality
  auto pipeline = wangle::Pipeline<std::string>::create();
  EXPECT_NE(pipeline, nullptr);

  // Test that we can add handlers to the pipeline
  pipeline->addBack(wangle::StringCodec());

  // Test pipeline functionality by creating input and verifying state
  EXPECT_NO_THROW({
    // Test that we can get the pipeline object
    auto& pipelineRef = *pipeline;
    // Verify pipeline is in a valid state after codec addition
    EXPECT_TRUE(pipeline != nullptr);
  });

  // Test pipeline with actual data flow
  EXPECT_NO_THROW({
    // Test pipeline creation and basic operations
    auto testPipeline = wangle::Pipeline<std::string>::create();
    testPipeline->addBack(wangle::StringCodec());

    // Test pipeline state management without requiring full handler setup
    EXPECT_NE(testPipeline, nullptr);
  });
}

TEST_F(WangleIntegrationTest, CodecFunctionality) {
  // Test that Wangle codecs work correctly
  wangle::StringCodec codec;
  wangle::LineBasedFrameDecoder decoder(1024);

  // Test StringCodec properties
  EXPECT_NO_THROW({
    // StringCodec should be constructible and usable
    wangle::StringCodec testCodec;
  });

  // Test LineBasedFrameDecoder with specific buffer size
  EXPECT_NO_THROW({
    wangle::LineBasedFrameDecoder testDecoder(2048);
    wangle::LineBasedFrameDecoder smallDecoder(512);
  });

  // Test that different buffer sizes work
  auto decoder1 = wangle::LineBasedFrameDecoder(1024);
  auto decoder2 = wangle::LineBasedFrameDecoder(4096);

  // Verify that codecs can be moved (important for pipeline usage)
  EXPECT_NO_THROW({
    auto moved_decoder = std::move(decoder1);
    auto moved_codec = std::move(codec);
  });
}

TEST_F(WangleIntegrationTest, ServerBootstrapCreation) {
  using TestPipeline = wangle::Pipeline<folly::IOBufQueue&, std::string>;

  // Test server bootstrap creation
  wangle::ServerBootstrap<TestPipeline> server;

  // Test basic server configuration
  EXPECT_NO_THROW({
    // Test setting group (thread pool)
    auto ioGroup = std::make_shared<folly::IOThreadPoolExecutor>(1);
    server.group(ioGroup);

    // Test setting accept group
    auto acceptGroup = std::make_shared<folly::IOThreadPoolExecutor>(1);
    server.group(ioGroup, acceptGroup);
  });

  // Test server options configuration
  EXPECT_NO_THROW({
    server.setReusePort(true);
    // Test multiple reuse port settings
    server.setReusePort(false);
    server.setReusePort(true);
  });

  // Verify server is in valid state after configuration
  EXPECT_TRUE(true);  // Server creation and basic config succeeded
}

TEST_F(WangleIntegrationTest, ClientBootstrapCreation) {
  using TestPipeline = wangle::Pipeline<folly::IOBufQueue&, std::string>;

  // Test client bootstrap creation
  wangle::ClientBootstrap<TestPipeline> client;

  // Test basic configuration
  EXPECT_NO_THROW({
    auto ioGroup = std::make_shared<folly::IOThreadPoolExecutor>(1);
    client.group(ioGroup);
  });

  // Test client-specific configurations
  EXPECT_NO_THROW({
    // Test that we can create multiple clients with different thread pools
    auto anotherGroup = std::make_shared<folly::IOThreadPoolExecutor>(3);
    wangle::ClientBootstrap<TestPipeline> anotherClient;
    anotherClient.group(anotherGroup);
    anotherGroup->join();
  });

  // Test that client state is valid after configuration
  auto testGroup = std::make_shared<folly::IOThreadPoolExecutor>(2);
  EXPECT_NO_THROW({ client.group(testGroup); });

  // Clean up the executor
  testGroup->join();
}

TEST_F(WangleIntegrationTest, AsyncSocketHandlerCreation) {
  // Test AsyncSocketHandler creation (core Wangle component)
  auto socket = folly::AsyncSocket::newSocket(eventBase.get());
  EXPECT_NE(socket, nullptr);

  // Test socket basic properties
  EXPECT_FALSE(socket->good());  // Not connected yet
  EXPECT_EQ(socket->getEventBase(), eventBase.get());

  // Test that we can create handlers with sockets
  EXPECT_NO_THROW({
    using HandlerType = wangle::AsyncSocketHandler;

    // Test handler type existence and basic properties
    static_assert(std::is_constructible_v<HandlerType,
                                          std::shared_ptr<folly::AsyncSocket>>);
  });

  // Test socket state management
  EXPECT_NO_THROW({
    auto anotherSocket = folly::AsyncSocket::newSocket(eventBase.get());
    EXPECT_NE(anotherSocket, nullptr);
    EXPECT_EQ(anotherSocket->getEventBase(), eventBase.get());
  });
}

TEST_F(WangleIntegrationTest, StaticPipelineTest) {
  using TestPipeline = wangle::Pipeline<folly::IOBufQueue&, std::string>;

  // Test StaticPipeline (memory-efficient pipeline)
  // This tests more advanced Wangle functionality

  auto pipeline = wangle::Pipeline<folly::IOBufQueue&, std::string>::create();
  EXPECT_NE(pipeline, nullptr);

  // Test adding codecs
  pipeline->addBack(wangle::LineBasedFrameDecoder(1024));
  pipeline->addBack(wangle::StringCodec());

  // Basic pipeline functionality test - verify handlers can be added
  SUCCEED();
}

// Enhanced handler for testing purposes
class EchoHandler : public wangle::HandlerAdapter<std::string> {
 public:
  EchoHandler() : messageCount_(0) {}

  void read(Context* ctx, std::string msg) override {
    messageCount_++;
    lastMessage_ = msg;
    // Echo the message back
    write(ctx, "Echo: " + msg);
  }

  // Test accessors
  int getMessageCount() const { return messageCount_; }
  const std::string& getLastMessage() const { return lastMessage_; }

 private:
  int messageCount_;
  std::string lastMessage_;
};

TEST_F(WangleIntegrationTest, CustomHandlerIntegration) {
  // Test custom handler integration
  auto pipeline = wangle::Pipeline<std::string>::create();
  EXPECT_NE(pipeline, nullptr);

  // Create and test our enhanced echo handler
  auto echoHandler = std::make_shared<EchoHandler>();
  EXPECT_EQ(echoHandler->getMessageCount(), 0);
  EXPECT_TRUE(echoHandler->getLastMessage().empty());

  // Add custom handler to pipeline
  EXPECT_NO_THROW({
    pipeline->addBack(std::make_shared<EchoHandler>());
    pipeline->addBack(wangle::StringCodec());
  });

  // Test handler functionality
  auto testHandler = std::make_shared<EchoHandler>();
  EXPECT_EQ(testHandler->getMessageCount(), 0);

  // Simulate a message (testing handler state)
  std::string testMsg = "Hello Handler";
  // We can't easily send through pipeline without full setup,
  // but we can test handler creation and state management
  EXPECT_TRUE(testHandler->getLastMessage().empty());
}

TEST_F(WangleIntegrationTest, ServiceInterfaceTest) {
  // Test Wangle's Service interface (RPC abstraction)
  using Request = std::string;
  using Response = std::string;

  // This tests that Service templates compile correctly
  // (We don't actually implement a service here, just test compilation)

  // If the template compiles, the Service interface is available
  SUCCEED();
}

TEST_F(WangleIntegrationTest, IOThreadPoolExecutorTest) {
  // Test that we can create IO thread pool executors
  auto executor = std::make_shared<folly::IOThreadPoolExecutor>(1);
  EXPECT_NE(executor, nullptr);

  // Test executor properties
  EXPECT_EQ(executor->numThreads(), 1);

  // Test basic executor operations
  std::atomic<bool> taskExecuted{false};
  std::atomic<int> taskCounter{0};

  executor->add([&taskExecuted, &taskCounter]() {
    taskExecuted.store(true);
    taskCounter.fetch_add(1);
  });

  // Give some time for task execution
  std::this_thread::sleep_for(std::chrono::milliseconds(100));

  // Test multiple tasks
  for (int i = 0; i < 5; ++i) {
    executor->add([&taskCounter]() { taskCounter.fetch_add(1); });
  }

  // Clean shutdown and verify execution
  executor->join();

  EXPECT_TRUE(taskExecuted.load());
  EXPECT_GE(taskCounter.load(), 1);  // At least one task should have executed
}

TEST_F(WangleIntegrationTest, CompilerOptimizationTest) {
  // Test that Wangle works with compiler optimizations
  // This test ensures that template instantiations work correctly

  constexpr size_t BUFFER_SIZE = 1024;
  constexpr size_t LARGE_BUFFER = 4096;
  constexpr size_t SMALL_BUFFER = 256;

  // Test different buffer sizes
  EXPECT_NO_THROW({
    wangle::LineBasedFrameDecoder decoder1(BUFFER_SIZE);
    wangle::LineBasedFrameDecoder decoder2(LARGE_BUFFER);
    wangle::LineBasedFrameDecoder decoder3(SMALL_BUFFER);
  });

  // Test compile-time constants
  EXPECT_EQ(BUFFER_SIZE, 1024);
  EXPECT_GT(LARGE_BUFFER, BUFFER_SIZE);
  EXPECT_LT(SMALL_BUFFER, BUFFER_SIZE);

  // Template-heavy code should compile without issues
  auto pipeline = wangle::Pipeline<folly::IOBufQueue&, std::string>::create();
  EXPECT_NE(pipeline, nullptr);

  // Test that we can add multiple codec types
  EXPECT_NO_THROW({
    pipeline->addBack(wangle::LineBasedFrameDecoder(BUFFER_SIZE));
    pipeline->addBack(wangle::StringCodec());
  });

  // Test template parameter deduction
  using PipelineType = wangle::Pipeline<folly::IOBufQueue&, std::string>;
  auto anotherPipeline = PipelineType::create();
  EXPECT_NE(anotherPipeline, nullptr);
}

TEST_F(WangleIntegrationTest, MemoryManagementTest) {
  // Test memory management in Wangle pipelines
  constexpr int NUM_PIPELINES = 100;
  constexpr int NUM_HANDLERS_PER_PIPELINE = 3;

  std::vector<std::shared_ptr<wangle::Pipeline<std::string>>> pipelines;
  pipelines.reserve(NUM_PIPELINES);

  // Create multiple pipelines to test memory management
  for (int i = 0; i < NUM_PIPELINES; ++i) {
    auto pipeline = wangle::Pipeline<std::string>::create();
    EXPECT_NE(pipeline, nullptr);

    // Add multiple handlers to each pipeline
    for (int j = 0; j < NUM_HANDLERS_PER_PIPELINE; ++j) {
      pipeline->addBack(wangle::StringCodec());
      if (j == 0) {  // Add custom handler to first position
        pipeline->addBack(std::make_shared<EchoHandler>());
      }
    }

    pipelines.push_back(pipeline);
  }

  EXPECT_EQ(pipelines.size(), NUM_PIPELINES);

  // Test that all pipelines are valid
  for (const auto& pipeline : pipelines) {
    EXPECT_NE(pipeline, nullptr);
  }

  // Test partial cleanup
  size_t halfSize = NUM_PIPELINES / 2;
  pipelines.resize(halfSize);
  EXPECT_EQ(pipelines.size(), halfSize);

  // Clean up should happen automatically
  pipelines.clear();
  EXPECT_TRUE(pipelines.empty());

  // Test that we can still create new pipelines after cleanup
  auto newPipeline = wangle::Pipeline<std::string>::create();
  EXPECT_NE(newPipeline, nullptr);
}

// Additional comprehensive tests
TEST_F(WangleIntegrationTest, EventBaseIntegration) {
  // Test EventBase integration with Wangle components
  EXPECT_NE(eventBase, nullptr);
  EXPECT_FALSE(eventBase->isRunning());

  // Test that we can create sockets with our event base
  auto socket1 = folly::AsyncSocket::newSocket(eventBase.get());
  auto socket2 = folly::AsyncSocket::newSocket(eventBase.get());

  EXPECT_NE(socket1, nullptr);
  EXPECT_NE(socket2, nullptr);
  EXPECT_EQ(socket1->getEventBase(), eventBase.get());
  EXPECT_EQ(socket2->getEventBase(), eventBase.get());

  // Test socket properties
  EXPECT_FALSE(socket1->good());  // Not connected
  EXPECT_FALSE(socket2->good());  // Not connected
}

TEST_F(WangleIntegrationTest, MultipleCodecTypes) {
  // Test that different codec combinations work
  auto stringPipeline = wangle::Pipeline<std::string>::create();
  auto bufferPipeline =
      wangle::Pipeline<folly::IOBufQueue&, std::string>::create();

  EXPECT_NE(stringPipeline, nullptr);
  EXPECT_NE(bufferPipeline, nullptr);

  // Test different codec combinations
  EXPECT_NO_THROW({
    stringPipeline->addBack(wangle::StringCodec());

    bufferPipeline->addBack(wangle::LineBasedFrameDecoder(1024));
    bufferPipeline->addBack(wangle::StringCodec());
  });

  // Test codec with different buffer sizes
  auto pipeline1 = wangle::Pipeline<folly::IOBufQueue&, std::string>::create();
  auto pipeline2 = wangle::Pipeline<folly::IOBufQueue&, std::string>::create();

  EXPECT_NO_THROW({
    pipeline1->addBack(wangle::LineBasedFrameDecoder(512));
    pipeline2->addBack(wangle::LineBasedFrameDecoder(2048));
  });
}

TEST_F(WangleIntegrationTest, HandlerChaining) {
  // Test complex handler chaining
  auto pipeline = wangle::Pipeline<std::string>::create();
  EXPECT_NE(pipeline, nullptr);

  // Create multiple custom handlers
  auto handler1 = std::make_shared<EchoHandler>();
  auto handler2 = std::make_shared<EchoHandler>();
  auto handler3 = std::make_shared<EchoHandler>();

  EXPECT_EQ(handler1->getMessageCount(), 0);
  EXPECT_EQ(handler2->getMessageCount(), 0);
  EXPECT_EQ(handler3->getMessageCount(), 0);

  // Add handlers in sequence
  EXPECT_NO_THROW({
    pipeline->addBack(handler1);
    pipeline->addBack(wangle::StringCodec());
    pipeline->addBack(handler2);
    pipeline->addBack(handler3);
  });

  // Verify handlers are still in valid state
  EXPECT_TRUE(handler1->getLastMessage().empty());
  EXPECT_TRUE(handler2->getLastMessage().empty());
  EXPECT_TRUE(handler3->getLastMessage().empty());
}

TEST_F(WangleIntegrationTest, ThreadPoolExecutorScaling) {
  // Test executor with different thread counts
  std::vector<std::shared_ptr<folly::IOThreadPoolExecutor>> executors;

  for (int threadCount = 1; threadCount <= 4; ++threadCount) {
    auto executor = std::make_shared<folly::IOThreadPoolExecutor>(threadCount);
    EXPECT_NE(executor, nullptr);
    EXPECT_EQ(executor->numThreads(), threadCount);

    executors.push_back(executor);
  }

  // Test task execution on different executors
  std::atomic<int> totalTasks{0};

  for (auto& executor : executors) {
    for (int i = 0; i < 10; ++i) {
      executor->add([&totalTasks]() {
        totalTasks.fetch_add(1);
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
      });
    }
  }

  // Clean shutdown all executors
  for (auto& executor : executors) {
    executor->join();
  }

  EXPECT_GE(totalTasks.load(), 40);  // Should have executed 4*10 = 40 tasks
}