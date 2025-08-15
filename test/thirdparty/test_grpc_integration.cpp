#include <grpcpp/generic/async_generic_service.h>
#include <grpcpp/grpcpp.h>
#include <grpcpp/health_check_service_interface.h>
#include <gtest/gtest.h>

#include <atomic>
#include <chrono>
#include <future>
#include <iostream>
#include <string>
#include <vector>

// Comprehensive gRPC integration tests
class GrpcIntegrationTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Create a server with health check and async generic service
    grpc::EnableDefaultHealthCheckService(true);
    builder_.AddListeningPort("127.0.0.1:0", grpc::InsecureServerCredentials(),
                              &selected_port_);

    async_generic_service_ = std::make_unique<grpc::AsyncGenericService>();
    builder_.RegisterAsyncGenericService(async_generic_service_.get());
    cq_ = builder_.AddCompletionQueue();

    server_ = builder_.BuildAndStart();
    ASSERT_NE(server_, nullptr);
    ASSERT_GT(selected_port_, 0);

    // Create client channel
    std::string target = "127.0.0.1:" + std::to_string(selected_port_);
    channel_ = grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
    ASSERT_NE(channel_, nullptr);
  }

  void TearDown() override {
    if (server_) {
      server_->Shutdown();
      server_.reset();
    }
    if (cq_) {
      cq_->Shutdown();
      void* tag;
      bool ok;
      while (cq_->Next(&tag, &ok)) {
        // Drain completion queue
      }
    }
  }

  grpc::ServerBuilder builder_;
  std::unique_ptr<grpc::AsyncGenericService> async_generic_service_;
  std::unique_ptr<grpc::CompletionQueue> cq_;
  std::unique_ptr<grpc::Server> server_;
  std::shared_ptr<grpc::Channel> channel_;
  int selected_port_ = 0;
};

// Basic channel creation and connection tests
TEST_F(GrpcIntegrationTest, ChannelCreation) {
  EXPECT_NE(channel_, nullptr);

  // Test channel state
  auto state = channel_->GetState(false);
  EXPECT_TRUE(state == GRPC_CHANNEL_IDLE || state == GRPC_CHANNEL_READY ||
              state == GRPC_CHANNEL_CONNECTING);
}

TEST_F(GrpcIntegrationTest, ChannelStateTransitions) {
  auto initial_state = channel_->GetState(false);

  // Try to connect
  bool state_changed = channel_->WaitForStateChange(
      initial_state,
      std::chrono::system_clock::now() + std::chrono::seconds(5));

  // Should either change state or timeout
  auto final_state = channel_->GetState(false);
  if (state_changed) {
    EXPECT_NE(initial_state, final_state);
  }
}

TEST_F(GrpcIntegrationTest, MultipleChannelsToSameServer) {
  std::string target = "127.0.0.1:" + std::to_string(selected_port_);

  std::vector<std::shared_ptr<grpc::Channel>> channels;
  const int num_channels = 5;

  for (int i = 0; i < num_channels; ++i) {
    auto chan = grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
    ASSERT_NE(chan, nullptr);
    channels.push_back(chan);
  }

  // All channels should be valid
  for (const auto& chan : channels) {
    auto state = chan->GetState(false);
    EXPECT_TRUE(state != GRPC_CHANNEL_SHUTDOWN);
  }
}

TEST_F(GrpcIntegrationTest, ChannelWithDifferentCredentials) {
  std::string target = "127.0.0.1:" + std::to_string(selected_port_);

  // Test different credential types
  auto insecure_channel =
      grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
  EXPECT_NE(insecure_channel, nullptr);

  // Test custom insecure credentials with args
  grpc::ChannelArguments args;
  args.SetMaxReceiveMessageSize(1024 * 1024);
  args.SetMaxSendMessageSize(1024 * 1024);

  auto custom_channel = grpc::CreateCustomChannel(
      target, grpc::InsecureChannelCredentials(), args);
  EXPECT_NE(custom_channel, nullptr);
}

TEST_F(GrpcIntegrationTest, ChannelArguments) {
  std::string target = "127.0.0.1:" + std::to_string(selected_port_);

  grpc::ChannelArguments args;
  args.SetMaxReceiveMessageSize(2 * 1024 * 1024);  // 2MB
  args.SetMaxSendMessageSize(2 * 1024 * 1024);     // 2MB
  args.SetCompressionAlgorithm(GRPC_COMPRESS_GZIP);
  args.SetString("grpc.keepalive_time_ms", "30000");
  args.SetInt("grpc.keepalive_timeout_ms", 5000);

  auto channel_with_args = grpc::CreateCustomChannel(
      target, grpc::InsecureChannelCredentials(), args);
  EXPECT_NE(channel_with_args, nullptr);

  // Channel should be in a valid state
  auto state = channel_with_args->GetState(false);
  EXPECT_TRUE(state != GRPC_CHANNEL_SHUTDOWN);
}

// Compression and encoding tests
TEST_F(GrpcIntegrationTest, CompressionAlgorithms) {
  grpc::ChannelArguments args;
  std::string target = "127.0.0.1:" + std::to_string(selected_port_);

  // Test different compression algorithms
  std::vector<grpc_compression_algorithm> algorithms = {
      GRPC_COMPRESS_NONE, GRPC_COMPRESS_DEFLATE, GRPC_COMPRESS_GZIP};

  for (auto alg : algorithms) {
    args.SetCompressionAlgorithm(alg);
    auto channel = grpc::CreateCustomChannel(
        target, grpc::InsecureChannelCredentials(), args);
    EXPECT_NE(channel, nullptr);
  }
}

// Load and performance tests
TEST_F(GrpcIntegrationTest, ConcurrentChannelCreation) {
  const int num_threads = 10;
  const int channels_per_thread = 5;
  std::string target = "127.0.0.1:" + std::to_string(selected_port_);

  std::vector<std::future<void>> futures;
  std::atomic<int> success_count{0};

  for (int t = 0; t < num_threads; ++t) {
    futures.emplace_back(std::async(std::launch::async, [&, t]() {
      for (int c = 0; c < channels_per_thread; ++c) {
        auto channel =
            grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
        if (channel) {
          success_count++;
        }
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }

  EXPECT_EQ(success_count.load(), num_threads * channels_per_thread);
}

TEST_F(GrpcIntegrationTest, ChannelMemoryStress) {
  std::string target = "127.0.0.1:" + std::to_string(selected_port_);
  std::vector<std::shared_ptr<grpc::Channel>> channels;

  const int num_channels = 100;
  channels.reserve(num_channels);

  // Create many channels
  for (int i = 0; i < num_channels; ++i) {
    auto channel =
        grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
    ASSERT_NE(channel, nullptr);
    channels.push_back(channel);
  }

  // Verify all are still valid
  for (const auto& channel : channels) {
    auto state = channel->GetState(false);
    EXPECT_TRUE(state != GRPC_CHANNEL_SHUTDOWN);
  }

  // Clear all at once
  channels.clear();
}

TEST_F(GrpcIntegrationTest, ChannelLifecycleManagement) {
  std::string target = "127.0.0.1:" + std::to_string(selected_port_);

  {
    // Create channel in scope
    auto scoped_channel =
        grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
    EXPECT_NE(scoped_channel, nullptr);

    auto state = scoped_channel->GetState(false);
    EXPECT_TRUE(state != GRPC_CHANNEL_SHUTDOWN);
  }  // Channel should be destroyed here

  // Create another channel to ensure resources are properly cleaned up
  auto new_channel =
      grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
  EXPECT_NE(new_channel, nullptr);
}

// Server configuration tests
TEST_F(GrpcIntegrationTest, ServerResourceLimits) {
  // Test that server handles resource constraints gracefully
  grpc::ServerBuilder test_builder;
  test_builder.SetMaxReceiveMessageSize(1024);
  test_builder.SetMaxSendMessageSize(1024);
  test_builder.SetMaxMessageSize(1024);

  int test_port = 0;
  test_builder.AddListeningPort("127.0.0.1:0",
                                grpc::InsecureServerCredentials(), &test_port);

  // Add a generic service and completion queue to satisfy gRPC requirements
  grpc::AsyncGenericService test_generic_service;
  test_builder.RegisterAsyncGenericService(&test_generic_service);
  auto test_cq = test_builder.AddCompletionQueue();

  auto test_server = test_builder.BuildAndStart();
  EXPECT_NE(test_server, nullptr);
  EXPECT_GT(test_port, 0);

  test_server->Shutdown();
  test_cq->Shutdown();
  void* tag;
  bool ok;
  while (test_cq->Next(&tag, &ok)) {
    // Drain completion queue
  }
}

TEST_F(GrpcIntegrationTest, ServerStartupShutdownCycle) {
  // Test multiple server start/shutdown cycles
  for (int cycle = 0; cycle < 3; ++cycle) {
    grpc::ServerBuilder cycle_builder;
    int cycle_port = 0;
    cycle_builder.AddListeningPort(
        "127.0.0.1:0", grpc::InsecureServerCredentials(), &cycle_port);

    // Add required services for proper server operation
    grpc::AsyncGenericService cycle_generic_service;
    cycle_builder.RegisterAsyncGenericService(&cycle_generic_service);
    auto cycle_cq = cycle_builder.AddCompletionQueue();

    auto cycle_server = cycle_builder.BuildAndStart();
    ASSERT_NE(cycle_server, nullptr);
    ASSERT_GT(cycle_port, 0);

    // Immediate shutdown
    cycle_server->Shutdown();
    cycle_cq->Shutdown();
    void* tag;
    bool ok;
    while (cycle_cq->Next(&tag, &ok)) {
      // Drain completion queue
    }
  }
}

// Error condition tests
TEST_F(GrpcIntegrationTest, InvalidServerAddress) {
  // Test connection to non-existent server
  auto bad_channel = grpc::CreateChannel("127.0.0.1:99999",
                                         grpc::InsecureChannelCredentials());
  EXPECT_NE(bad_channel, nullptr);

  // Channel should be created but connection will fail
  auto state = bad_channel->GetState(false);
  EXPECT_TRUE(state == GRPC_CHANNEL_IDLE ||
              state == GRPC_CHANNEL_TRANSIENT_FAILURE);
}

TEST_F(GrpcIntegrationTest, ChannelTimeout) {
  auto timeout_channel = grpc::CreateChannel(
      "192.0.2.1:50051", grpc::InsecureChannelCredentials());
  EXPECT_NE(timeout_channel, nullptr);

  auto initial_state = timeout_channel->GetState(false);

  // Wait for a short time - should timeout or fail to connect
  bool changed = timeout_channel->WaitForStateChange(
      initial_state,
      std::chrono::system_clock::now() + std::chrono::milliseconds(100));

  // Either changed to a failure state or timed out
  if (changed) {
    auto final_state = timeout_channel->GetState(false);
    EXPECT_TRUE(final_state == GRPC_CHANNEL_TRANSIENT_FAILURE ||
                final_state == GRPC_CHANNEL_CONNECTING);
  }
}

// Performance measurement tests
TEST_F(GrpcIntegrationTest, ChannelCreationPerformance) {
  std::string target = "127.0.0.1:" + std::to_string(selected_port_);
  const int num_channels = 100;

  auto start = std::chrono::high_resolution_clock::now();

  std::vector<std::shared_ptr<grpc::Channel>> perf_channels;
  perf_channels.reserve(num_channels);

  for (int i = 0; i < num_channels; ++i) {
    auto channel =
        grpc::CreateChannel(target, grpc::InsecureChannelCredentials());
    perf_channels.push_back(channel);
  }

  auto end = std::chrono::high_resolution_clock::now();
  auto duration =
      std::chrono::duration_cast<std::chrono::microseconds>(end - start);

  std::cout << "Created " << num_channels << " channels in " << duration.count()
            << " microseconds" << std::endl;

  // Should be able to create channels reasonably quickly
  EXPECT_LT(duration.count(), 10000000);  // Less than 10 seconds

  // Verify all channels are valid
  for (const auto& channel : perf_channels) {
    EXPECT_NE(channel, nullptr);
  }
}

// Integration with health check service
TEST_F(GrpcIntegrationTest, HealthCheckService) {
  // Since we enabled health check service, it should be available
  // This is mainly testing that the server starts correctly with health check
  // enabled
  EXPECT_NE(server_, nullptr);
  EXPECT_GT(selected_port_, 0);

  // Channel to the server should be valid
  auto state = channel_->GetState(false);
  EXPECT_TRUE(state != GRPC_CHANNEL_SHUTDOWN);
}

// Original basic integration tests for continuity
TEST(ThirdpartyGrpcIntegration, CreateInsecureChannel) {
  auto channel = grpc::CreateChannel("localhost:50051",
                                     grpc::InsecureChannelCredentials());
  ASSERT_NE(channel, nullptr);
}

TEST(ThirdpartyGrpcIntegration, BuildServerAndShutdown) {
  grpc::EnableDefaultHealthCheckService(true);
  grpc::ServerBuilder builder;
  int selected_port = 0;
  builder.AddListeningPort("127.0.0.1:0", grpc::InsecureServerCredentials(),
                           &selected_port);

  grpc::AsyncGenericService async_generic_service;
  builder.RegisterAsyncGenericService(&async_generic_service);
  auto cq = builder.AddCompletionQueue();

  std::unique_ptr<grpc::Server> server = builder.BuildAndStart();
  ASSERT_NE(server, nullptr);
  ASSERT_GT(selected_port, 0);

  server->Shutdown();
  cq->Shutdown();
  void* tag;
  bool ok;
  while (cq->Next(&tag, &ok)) {
    // Drain completion queue
  }
}
