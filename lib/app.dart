import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/leaderboard/application/leaderboard_controller.dart';

class VolcanoQuestApp extends ConsumerWidget {
  const VolcanoQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(leaderboardAutoSyncProvider);
    return MaterialApp.router(
      title: 'Volcano Quest',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
