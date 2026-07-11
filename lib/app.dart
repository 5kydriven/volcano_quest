import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/audio/audio_controller.dart';
import 'core/audio/mission_audio_profile.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'features/leaderboard/application/leaderboard_controller.dart';

class VolcanoQuestApp extends ConsumerStatefulWidget {
  const VolcanoQuestApp({super.key});

  @override
  ConsumerState<VolcanoQuestApp> createState() => _VolcanoQuestAppState();
}

class _VolcanoQuestAppState extends ConsumerState<VolcanoQuestApp> {
  GoRouter? _router;
  String? _lastLocation;

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_handleRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    ref.watch(audioControllerProvider);
    ref.watch(leaderboardAutoSyncProvider);

    _attachRouter(router);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        ref.read(audioControllerProvider).retryAfterUserInteraction();
      },
      child: MaterialApp.router(
        title: 'Volcano Quest',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }

  void _attachRouter(GoRouter router) {
    if (identical(_router, router)) {
      return;
    }

    _router?.routerDelegate.removeListener(_handleRouteChanged);
    _router = router;
    _router?.routerDelegate.addListener(_handleRouteChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleRouteChanged();
      }
    });
  }

  void _handleRouteChanged() {
    final router = _router;
    if (router == null || !mounted) {
      return;
    }

    final location = router.routerDelegate.currentConfiguration.uri.toString();
    if (_lastLocation == location) {
      return;
    }

    _lastLocation = location;
    final track = MissionAudioProfile.bgmForLocation(location);
    ref.read(audioControllerProvider).setDesiredBgm(track);
  }
}
