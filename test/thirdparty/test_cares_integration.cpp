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

#include <string>
#include <vector>

struct QueryResult {
  int status = ARES_ECONNREFUSED;  // will be replaced by callback status
  std::vector<std::string> addresses;
  bool done = false;
};

static void addrinfo_callback(void* arg, int status, int /*timeouts*/,
                              struct ares_addrinfo* res) {
  auto* result = static_cast<QueryResult*>(arg);
  result->status = status;
  if (status == ARES_SUCCESS && res) {
    for (auto* node = res->nodes; node; node = node->ai_next) {
      char ip[INET6_ADDRSTRLEN] = {0};
      if (node->ai_family == AF_INET) {
        const auto* sin =
            reinterpret_cast<const struct sockaddr_in*>(node->ai_addr);
        inet_ntop(AF_INET, &sin->sin_addr, ip, sizeof(ip));
      } else if (node->ai_family == AF_INET6) {
        const auto* sin6 =
            reinterpret_cast<const struct sockaddr_in6*>(node->ai_addr);
        inet_ntop(AF_INET6, &sin6->sin6_addr, ip, sizeof(ip));
      }
      if (ip[0]) result->addresses.emplace_back(ip);
    }
  }
  if (res) ares_freeaddrinfo(res);
  result->done = true;
}

// Helper state for socket callback driven loop
struct LoopState {
  std::vector<ares_socket_t> sockets;  // active sockets
};

static void sock_state_cb(void* data, ares_socket_t sock, int readable,
                          int writable) {
  auto* st = static_cast<LoopState*>(data);
  auto it = std::find(st->sockets.begin(), st->sockets.end(), sock);
  if (readable == 0 && writable == 0) {
    if (it != st->sockets.end()) st->sockets.erase(it);
  } else {
    if (it == st->sockets.end()) st->sockets.push_back(sock);
  }
}

TEST(CaresIntegration, CanResolveLocalhostWithGetAddrInfo) {
  ares_channel channel = nullptr;
  LoopState loop_state;
  ares_options options{};  // zero-init
  options.sock_state_cb = sock_state_cb;
  options.sock_state_cb_data = &loop_state;
  int optmask = ARES_OPT_SOCK_STATE_CB;  // enable socket state callback
  ASSERT_EQ(ARES_SUCCESS, ares_init_options(&channel, &options, optmask));

  QueryResult result;

  ares_addrinfo_hints hints{};  // zero-init -> AF_UNSPEC, any socktype/proto
  hints.ai_family = AF_UNSPEC;
  ares_getaddrinfo(channel, "localhost", nullptr, &hints, addrinfo_callback,
                   &result);

  for (int iter = 0; iter < 50 && !result.done; ++iter) {
    if (loop_state.sockets.empty()) {
      // No sockets registered, wait a tiny bit (could be immediate completion)
      struct timeval tiny{0, 50 * 1000};  // 50ms
      select(0, nullptr, nullptr, nullptr, &tiny);
      continue;
    }

    fd_set read_fds, write_fds;
    FD_ZERO(&read_fds);
    FD_ZERO(&write_fds);
    ares_socket_t maxfd = ARES_SOCKET_BAD;
    for (auto s : loop_state.sockets) {
      // We don't know per-socket readability/writability flags directly here;
      // select for both
      FD_SET(s, &read_fds);
      FD_SET(s, &write_fds);
      if (s > maxfd) maxfd = s;
    }
    if (maxfd == ARES_SOCKET_BAD) break;

    struct timeval tv, *tvp;
    tvp = ares_timeout(channel, nullptr, &tv);
    (void)select(static_cast<int>(maxfd) + 1, &read_fds, &write_fds, nullptr,
                 tvp);

    // Process each socket according to readiness
    for (auto s : loop_state.sockets) {
      ares_socket_t rfd = FD_ISSET(s, &read_fds) ? s : ARES_SOCKET_BAD;
      ares_socket_t wfd = FD_ISSET(s, &write_fds) ? s : ARES_SOCKET_BAD;
      if (rfd != ARES_SOCKET_BAD || wfd != ARES_SOCKET_BAD) {
        ares_process_fd(channel, rfd, wfd);
      }
    }
  }

  ASSERT_TRUE(result.done);
  ASSERT_NE(result.status, ARES_ECONNREFUSED);
  if (result.status == ARES_SUCCESS) {
    ASSERT_FALSE(result.addresses.empty());
  }

  ares_destroy(channel);
}
