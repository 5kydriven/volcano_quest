import 'package:drift/drift.dart';

import 'database_connection_unsupported.dart'
    if (dart.library.io) 'database_connection_io.dart';

QueryExecutor openDatabaseConnection() {
  return openNativeDatabaseConnection();
}
