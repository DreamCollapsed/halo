// Modernized c-ares integration test using ares_getaddrinfo instead of
// deprecated ares_gethostbyname()/hostent interfaces.
// NOTE: ares_library_init/cleanup are deprecated on non-Windows platforms;
// we rely solely on ares_init_options + ares_destroy for lifecycle.

#include <ares.h>
#include <arpa/inet.h>
#include <gtest/gtest.h>
#include <sys/select.h>
#include <sys/time.h>
#include <unistd.h>

#include <algorithm>
#include <array>
#include <cstring>
#include <string>
#include <vector>

struct QueryResult {
  int status_code_ = ARES_ECONNREFUSED;  // will be replaced by callback status
  std::vector<std::string> resolved_addresses_;
  bool is_complete_ = false;
};

static void AddrinfoCallback(void* arg, int status, int /*timeouts*/,
                             struct ares_addrinfo* address_info) {
  auto* result = static_cast<QueryResult*>(arg);
  result->status_code_ = status;
  if (status == ARES_SUCCESS && address_info != nullptr) {
    for (auto* node = address_info->nodes; node != nullptr;
         node = node->ai_next) {
      std::array<char, INET6_ADDRSTRLEN> ip_buffer{};
      if (node->ai_family == AF_INET) {
        struct sockaddr_in addr_v4{};
        std::memcpy(&addr_v4, node->ai_addr, sizeof(addr_v4));
        inet_ntop(AF_INET, &addr_v4.sin_addr, ip_buffer.data(),
                  ip_buffer.size());
      } else if (node->ai_family == AF_INET6) {
        struct sockaddr_in6 addr_v6{};
        std::memcpy(&addr_v6, node->ai_addr, sizeof(addr_v6));
        inet_ntop(AF_INET6, &addr_v6.sin6_addr, ip_buffer.data(),
                  ip_buffer.size());
      }
      if (ip_buffer.front() != '\0') {
        result->resolved_addresses_.emplace_back(ip_buffer.data());
      }
    }
  }
  if (address_info != nullptr) {
    ares_freeaddrinfo(address_info);
  }
  result->is_complete_ = true;
}

// Helper state for socket callback driven loop
struct LoopState {
  std::vector<ares_socket_t> active_sockets_;
};

// NOLINTBEGIN(readability-suspicious-call-argument)
// NOLINTBEGIN(bugprone-easily-swappable-parameters)
static void SocketStateCallback(void* data, ares_socket_t socket_fd,
                                int readable_flag, int writable_flag) {
  auto* loop_state = static_cast<LoopState*>(data);
  auto socket_iter = std::ranges::find(loop_state->active_sockets_, socket_fd);
  if (readable_flag == 0 && writable_flag == 0) {
    if (socket_iter != loop_state->active_sockets_.end()) {
      loop_state->active_sockets_.erase(socket_iter);
    }
  } else if (socket_iter == loop_state->active_sockets_.end()) {
    loop_state->active_sockets_.push_back(socket_fd);
  }
}
// NOLINTEND(bugprone-easily-swappable-parameters)
// NOLINTEND(readability-suspicious-call-argument)

TEST(CaresIntegration, CanResolveLocalhostWithGetAddrInfo) {
  ares_channel channel = nullptr;
  LoopState loop_state;
  ares_options options{};  // zero-init
  options.sock_state_cb = SocketStateCallback;
  options.sock_state_cb_data = &loop_state;
  int optmask = ARES_OPT_SOCK_STATE_CB;  // enable socket state callback
  ASSERT_EQ(ARES_SUCCESS, ares_init_options(&channel, &options, optmask));

  QueryResult result;

  ares_addrinfo_hints hints{};  // zero-init -> AF_UNSPEC, any socktype/proto
  hints.ai_family = AF_UNSPEC;
  ares_getaddrinfo(channel, "localhost", nullptr, &hints, AddrinfoCallback,
                   &result);

  for (int iter = 0; iter < 50 && !result.is_complete_; ++iter) {
    if (loop_state.active_sockets_.empty()) {
      // No sockets registered, wait a tiny bit (could be immediate completion)
      struct timeval tiny{.tv_sec = 0, .tv_usec = 50 * 1000};  // 50ms
      select(0, nullptr, nullptr, nullptr, &tiny);
      continue;
    }

    fd_set read_fds;
    fd_set write_fds;
    FD_ZERO(&read_fds);
    FD_ZERO(&write_fds);
    ares_socket_t max_socket_fd = ARES_SOCKET_BAD;
    for (auto socket_fd : loop_state.active_sockets_) {
      // We don't know per-socket readability/writability flags directly here;
      // select for both
      FD_SET(socket_fd, &read_fds);
      FD_SET(socket_fd, &write_fds);
      max_socket_fd = std::max(max_socket_fd, socket_fd);
    }
    if (max_socket_fd == ARES_SOCKET_BAD) {
      break;
    }

    struct timeval timeout_value{.tv_sec = 0, .tv_usec = 0};
    struct timeval* timeout_ptr =
        ares_timeout(channel, nullptr, &timeout_value);
    (void)select(static_cast<int>(max_socket_fd) + 1, &read_fds, &write_fds,
                 nullptr, timeout_ptr);

    // Process each socket according to readiness
    for (auto socket_fd : loop_state.active_sockets_) {
      ares_socket_t read_fd =
          FD_ISSET(socket_fd, &read_fds) ? socket_fd : ARES_SOCKET_BAD;
      ares_socket_t write_fd =
          FD_ISSET(socket_fd, &write_fds) ? socket_fd : ARES_SOCKET_BAD;
      if (read_fd != ARES_SOCKET_BAD || write_fd != ARES_SOCKET_BAD) {
        ares_process_fd(channel, read_fd, write_fd);
      }
    }
  }

  ASSERT_TRUE(result.is_complete_);
  ASSERT_NE(result.status_code_, ARES_ECONNREFUSED);
  if (result.status_code_ == ARES_SUCCESS) {
    ASSERT_FALSE(result.resolved_addresses_.empty());
  }

  ares_destroy(channel);
}
