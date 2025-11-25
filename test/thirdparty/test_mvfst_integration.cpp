#include <folly/experimental/symbolizer/Symbolizer.h>
#include <gtest/gtest.h>
#include <quic/QuicConstants.h>

TEST(Thirdparty, MvfstHeadersAndTypes) {
  auto v6_send_len = quic::kDefaultV6UDPSendPacketLen;  // from QuicConstants.h
  EXPECT_GT(v6_send_len, 0);

  // Basic enums exist and are usable
  quic::CongestionControlType congestion_control =
      quic::CongestionControlType::Cubic;
  (void)congestion_control;
  quic::QuicVersion ver = quic::QuicVersion::QUIC_V1;
  (void)ver;

  // Check MVFST version constant
  EXPECT_EQ(static_cast<uint32_t>(quic::QuicVersion::MVFST), 0xfaceb002);

  SUCCEED();
}

TEST(Thirdparty, MvfstConstantsMisc) {
  // Test some additional simple constants
  EXPECT_GE(quic::kDefaultUDPSendPacketLen, 1200);
  EXPECT_GE(quic::kDefaultMaxUDPPayload, 1200);
  EXPECT_GE(quic::kDefaultUDPReadBufferSize, 1200);

  EXPECT_GT(quic::kRttAlpha, 0);
  EXPECT_GT(quic::kRttBeta, 0);
  EXPECT_NE(quic::kRttAlpha, quic::kRttBeta);

  EXPECT_GT(quic::kDefaultPacingTickInterval.count(), 0);
  EXPECT_GT(quic::kGranularity.count(), 0);

  // Node string helper is inline
  EXPECT_EQ(quic::nodeToString(quic::QuicNodeType::Client), "Client");
  EXPECT_EQ(quic::nodeToString(quic::QuicNodeType::Server), "Server");
}

TEST(Thirdparty, MvfstLibunwindIntegration) {
  // Ensure libunwind is linked via folly
  folly::symbolizer::SafeStackTracePrinter printer;
  SUCCEED();
}
