#include <gtest/gtest.h>
#include <quic/QuicConstants.h>

TEST(Thirdparty, mvfst_headers_and_types) {
  auto v6SendLen = quic::kDefaultV6UDPSendPacketLen;  // from QuicConstants.h
  EXPECT_GT(v6SendLen, 0);

  // Basic enums exist and are usable
  quic::CongestionControlType cc = quic::CongestionControlType::Cubic;
  (void)cc;
  quic::QuicVersion ver = quic::QuicVersion::QUIC_V1;
  (void)ver;

  SUCCEED();
}

TEST(Thirdparty, mvfst_constants_misc) {
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
  EXPECT_STREQ(quic::nodeToString(quic::QuicNodeType::Client).data(), "Client");
  EXPECT_STREQ(quic::nodeToString(quic::QuicNodeType::Server).data(), "Server");
}
