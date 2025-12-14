#include <absl/strings/str_cat.h>
#include <jemalloc/jemalloc.h>
#include <velox/type/Type.h>
#include <velox/vector/BaseVector.h>
#include <velox/vector/SimpleVector.h>

#include <duckdb.hpp>
#include <iostream>

int main() {
  std::cout << absl::StrCat("Message: ", "Halo Start...") << '\n';

  // Simple Velox integration test
  try {
    auto int_type = facebook::velox::TypeFactory<
        facebook::velox::TypeKind::INTEGER>::create();
    std::cout << "Velox integration successful!" << '\n';
  } catch (const std::exception& e) {
    std::cout << "Velox integration error: " << e.what() << '\n';
    return 1;
  }

  // Simple DuckDB integration test
  duckdb::DuckDB db(nullptr);
  duckdb::Connection con(db);
  auto result = con.Query("SELECT 'DuckDB integration successful!'");
  if (!result->HasError()) {
    std::cout << result->GetValue(0, 0).ToString() << '\n';
  } else {
    std::cout << "DuckDB query error: " << result->GetError() << '\n';
  }

  return 0;
}
