import 'package:drift/drift.dart';

QueryExecutor openNativeDatabaseConnection() {
  return LazyDatabase(() async {
    throw UnsupportedError(
      'Leaderboard cache is only configured for native platforms.',
    );
  });
}
