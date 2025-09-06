#include <geos_c.h>
#include <gtest/gtest.h>

#include <cstdio>
#include <string>

// Simple RAII wrapper for GEOS context
struct GeosContext {
  GEOSContextHandle_t ctx;
  GeosContext() : ctx(GEOS_init_r()) {}
  ~GeosContext() {
    if (ctx) GEOS_finish_r(ctx);
  }
};

TEST(GeosIntegrationTest, VersionAndPointArea) {
  GeosContext gc;
  ASSERT_NE(gc.ctx, nullptr) << "Failed to init GEOS context";

  const char* ver = GEOSversion();
  ASSERT_NE(ver, nullptr);
  // Accept any 3.x version; don't hardcode minor/patch.
  std::string v(ver);
  int maj = 0, min = 0, pat = 0;
  if (std::sscanf(v.c_str(), "%d.%d.%d", &maj, &min, &pat) >= 1) {
    EXPECT_GE(maj, 3) << "GEOS version: " << v;
  } else {
    // Fallback: at least version string should be non-empty
    EXPECT_FALSE(v.empty());
  }

  // Create a WKT reader
  GEOSWKTReader* reader = GEOSWKTReader_create_r(gc.ctx);
  ASSERT_NE(reader, nullptr);

  // Create geometry from WKT (a triangle polygon)
  const char* wkt =
      "POLYGON((0 0, 10 0, 0 10, 0 0))";  // Right triangle area should be 50
  GEOSGeometry* geom = GEOSWKTReader_read_r(gc.ctx, reader, wkt);
  ASSERT_NE(geom, nullptr) << "Failed to parse WKT";

  double area = 0.0;
  int rc = GEOSArea_r(gc.ctx, geom, &area);
  EXPECT_EQ(rc, 1);
  EXPECT_NEAR(area, 50.0, 1e-9);

  // Compute envelope area should be 100 (bounding box 0,0 to 10,10)
  GEOSGeometry* env = GEOSEnvelope_r(gc.ctx, geom);
  ASSERT_NE(env, nullptr);
  area = 0.0;
  rc = GEOSArea_r(gc.ctx, env, &area);
  EXPECT_EQ(rc, 1);
  EXPECT_NEAR(area, 100.0, 1e-9);

  GEOSGeom_destroy_r(gc.ctx, env);
  GEOSGeom_destroy_r(gc.ctx, geom);
  GEOSWKTReader_destroy_r(gc.ctx, reader);
}

TEST(GeosIntegrationTest, BufferOperation) {
  GeosContext gc;
  ASSERT_NE(gc.ctx, nullptr);

  GEOSCoordSequence* seq = GEOSCoordSeq_create_r(gc.ctx, 1, 2);
  ASSERT_NE(seq, nullptr);
  GEOSCoordSeq_setX_r(gc.ctx, seq, 0, 0.0);
  GEOSCoordSeq_setY_r(gc.ctx, seq, 0, 0.0);

  GEOSGeometry* pt = GEOSGeom_createPoint_r(gc.ctx, seq);
  ASSERT_NE(pt, nullptr);

  // Buffer with radius 1.0 (approximate circle as polygon)
  GEOSGeometry* buf = GEOSBuffer_r(gc.ctx, pt, 1.0, 8);
  ASSERT_NE(buf, nullptr);

  double area = 0.0;
  int rc = GEOSArea_r(gc.ctx, buf, &area);
  EXPECT_EQ(rc, 1);
  // Area of circle pi*r^2 ~ 3.14159; polygon approximation will be close
  EXPECT_GT(area, 2.5);
  EXPECT_LT(area, 3.5);

  GEOSGeom_destroy_r(gc.ctx, buf);
  GEOSGeom_destroy_r(gc.ctx, pt);
}
