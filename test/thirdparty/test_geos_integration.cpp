#include <geos_c.h>
#include <gtest/gtest.h>

#include <sstream>
#include <string>

// Simple RAII wrapper for GEOS context
struct GeosContext {
  GEOSContextHandle_t ctx_;
  GeosContext() : ctx_(GEOS_init_r()) {}
  ~GeosContext() {
    if (ctx_ != nullptr) {
      GEOS_finish_r(ctx_);
    }
  }

  GeosContext(const GeosContext&) = delete;
  GeosContext& operator=(const GeosContext&) = delete;
  GeosContext(GeosContext&&) = delete;
  GeosContext& operator=(GeosContext&&) = delete;
};

TEST(GeosIntegrationTest, VersionAndPointArea) {
  GeosContext geos_context;
  ASSERT_NE(geos_context.ctx_, nullptr) << "Failed to init GEOS context";

  const char* ver = GEOSversion();
  ASSERT_NE(ver, nullptr);
  // Accept any 3.x version; don't hardcode minor/patch.
  std::string version_str(ver);
  int major = 0;
  int minor = 0;
  int patch = 0;
  char dot1 = 0;
  char dot2 = 0;
  std::istringstream iss(version_str);

  if (iss >> major >> dot1 >> minor >> dot2 >> patch) {
    EXPECT_GE(major, 3) << "GEOS version: " << version_str;
  } else {
    // Fallback: at least version string should be non-empty
    EXPECT_FALSE(version_str.empty());
  }

  // Create a WKT reader
  GEOSWKTReader* reader = GEOSWKTReader_create_r(geos_context.ctx_);
  ASSERT_NE(reader, nullptr);

  // Create geometry from WKT (a triangle polygon)
  const char* wkt =
      "POLYGON((0 0, 10 0, 0 10, 0 0))";  // Right triangle area should be 50
  GEOSGeometry* geom = GEOSWKTReader_read_r(geos_context.ctx_, reader, wkt);
  ASSERT_NE(geom, nullptr) << "Failed to parse WKT";

  double area = 0.0;
  int result_code = GEOSArea_r(geos_context.ctx_, geom, &area);
  EXPECT_EQ(result_code, 1);
  EXPECT_NEAR(area, 50.0, 1e-9);

  // Compute envelope area should be 100 (bounding box 0,0 to 10,10)
  GEOSGeometry* env = GEOSEnvelope_r(geos_context.ctx_, geom);
  ASSERT_NE(env, nullptr);
  area = 0.0;
  result_code = GEOSArea_r(geos_context.ctx_, env, &area);
  EXPECT_EQ(result_code, 1);
  EXPECT_NEAR(area, 100.0, 1e-9);

  GEOSGeom_destroy_r(geos_context.ctx_, env);
  GEOSGeom_destroy_r(geos_context.ctx_, geom);
  GEOSWKTReader_destroy_r(geos_context.ctx_, reader);
}

TEST(GeosIntegrationTest, BufferOperation) {
  GeosContext geos_context;
  ASSERT_NE(geos_context.ctx_, nullptr);

  GEOSCoordSequence* seq = GEOSCoordSeq_create_r(geos_context.ctx_, 1, 2);
  ASSERT_NE(seq, nullptr);
  GEOSCoordSeq_setX_r(geos_context.ctx_, seq, 0, 0.0);
  GEOSCoordSeq_setY_r(geos_context.ctx_, seq, 0, 0.0);

  GEOSGeometry* point = GEOSGeom_createPoint_r(geos_context.ctx_, seq);
  ASSERT_NE(point, nullptr);

  // Buffer with radius 1.0 (approximate circle as polygon)
  GEOSGeometry* buf = GEOSBuffer_r(geos_context.ctx_, point, 1.0, 8);
  ASSERT_NE(buf, nullptr);

  double area = 0.0;
  int result_code = GEOSArea_r(geos_context.ctx_, buf, &area);
  EXPECT_EQ(result_code, 1);
  // Area of circle pi*r^2 ~ 3.14159; polygon approximation will be close
  EXPECT_GT(area, 2.5);
  EXPECT_LT(area, 3.5);

  GEOSGeom_destroy_r(geos_context.ctx_, buf);
  GEOSGeom_destroy_r(geos_context.ctx_, point);
}

TEST(GeosIntegrationTest, VersionCheck) {
  EXPECT_EQ(GEOS_VERSION_MAJOR, 3);
  EXPECT_EQ(GEOS_VERSION_MINOR, 11);
  EXPECT_EQ(GEOS_VERSION_PATCH, 5);
  EXPECT_STREQ(GEOS_VERSION, "3.11.5");
  EXPECT_STREQ(GEOS_JTS_PORT, "1.18.0");
}
