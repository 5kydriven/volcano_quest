import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/settings/application/settings_controller.dart';
import 'audio_catalog.dart';

final audioControllerProvider = Provider<AudioController>((ref) {
  final controller = AudioController(ref.read(settingsProvider));

  ref.listen<AppSettings>(settingsProvider, (_, next) {
    controller.updateSettings(next);
  });
  ref.onDispose(controller.dispose);

  return controller;
});

class AudioController {
  static const _sfxPoolSize = 4;

  late final bool _isNoop;
  late final AudioPlayer? _bgmPlayer;
  late final List<AudioPlayer> _sfxPlayers;
  final Map<SfxCue, int> _sfxVariantCursor = {};

  AppSettings _settings;
  BgmTrack? _desiredTrack;
  BgmTrack? _currentTrack;
  String? _currentAsset;
  var _bgmRequestId = 0;
  var _sfxCursor = 0;
  var _needsUserGestureRetry = false;
  var _disposed = false;

  AudioController(
    this._settings, {
    AudioPlayer? bgmPlayer,
    List<AudioPlayer>? sfxPlayers,
  }) {
    _isNoop =
        bgmPlayer == null &&
        sfxPlayers == null &&
        _isAutomatedTestBinding(WidgetsBinding.instance);
    _bgmPlayer = _isNoop ? null : bgmPlayer ?? AudioPlayer();
    _sfxPlayers = _isNoop
        ? const []
        : sfxPlayers ?? List.generate(_sfxPoolSize, (_) => AudioPlayer());

    if (!_isNoop) {
      _configurePlayers();
    }
  }

  void setDesiredBgm(BgmTrack track) {
    if (_disposed || _isNoop) {
      return;
    }

    _desiredTrack = track;
    if (_currentTrack == track &&
        _currentAsset == AudioCatalog.bgmAsset(track)) {
      _applyBgmSettings();
      return;
    }

    unawaited(_loadBgm(track));
  }

  void retryAfterUserInteraction() {
    if (!_needsUserGestureRetry || _disposed || _isNoop) {
      return;
    }

    final track = _desiredTrack;
    if (track == null) {
      return;
    }

    if (_currentTrack == track) {
      _playBgm();
      return;
    }

    unawaited(_loadBgm(track));
  }

  void updateSettings(AppSettings settings) {
    if (_disposed || _isNoop) {
      return;
    }

    _settings = settings;
    _applyBgmSettings();
    _applySfxVolume();
  }

  Future<void> playSfx(SfxCue cue) async {
    if (_disposed || _isNoop || !_settings.sfxEnabled) {
      return;
    }

    final assets = AudioCatalog.sfxAssets(cue);
    if (assets.isEmpty) {
      return;
    }

    final player = _nextSfxPlayer();
    final asset = _nextSfxAsset(cue, assets);

    try {
      await player.stop();
      await player.setVolume(_settings.sfxVolume);
      await player.setAsset(asset);
      await player.seek(Duration.zero);
      unawaited(player.play().catchError((Object _) {}));
    } catch (_) {
      // Audio should never break gameplay or widget tests.
    }
  }

  void dispose() {
    _disposed = true;
    final bgmPlayer = _bgmPlayer;
    if (bgmPlayer != null) {
      unawaited(bgmPlayer.dispose());
    }
    for (final player in _sfxPlayers) {
      unawaited(player.dispose());
    }
  }

  void _configurePlayers() {
    final bgmPlayer = _bgmPlayer;
    if (bgmPlayer == null) {
      return;
    }

    unawaited(bgmPlayer.setLoopMode(LoopMode.one).catchError((Object _) {}));
    unawaited(
      bgmPlayer.setVolume(_settings.bgmVolume).catchError((Object _) {}),
    );
    _applySfxVolume();
  }

  Future<void> _loadBgm(BgmTrack track) async {
    final bgmPlayer = _bgmPlayer;
    if (bgmPlayer == null) {
      return;
    }

    final requestId = ++_bgmRequestId;
    final asset = AudioCatalog.bgmAsset(track);

    try {
      await bgmPlayer.stop();
      if (_disposed || requestId != _bgmRequestId) {
        return;
      }

      await bgmPlayer.setAsset(asset);
      if (_disposed || requestId != _bgmRequestId) {
        return;
      }

      await bgmPlayer.setLoopMode(LoopMode.one);
      await bgmPlayer.setVolume(_settings.bgmVolume);

      _currentTrack = track;
      _currentAsset = asset;
      _applyBgmSettings();
    } catch (_) {
      // Keep route/audio state recoverable; a later route change or tap can retry.
      _needsUserGestureRetry = true;
    }
  }

  void _applyBgmSettings() {
    final bgmPlayer = _bgmPlayer;
    if (bgmPlayer == null) {
      return;
    }

    if (!_settings.bgmEnabled) {
      unawaited(bgmPlayer.pause().catchError((Object _) {}));
      return;
    }

    unawaited(
      bgmPlayer.setVolume(_settings.bgmVolume).catchError((Object _) {}),
    );
    _playBgm();
  }

  void _playBgm() {
    final bgmPlayer = _bgmPlayer;
    if (bgmPlayer == null || !_settings.bgmEnabled || _currentTrack == null) {
      return;
    }

    unawaited(
      bgmPlayer
          .play()
          .then((_) {
            _needsUserGestureRetry = false;
          })
          .catchError((Object _) {
            _needsUserGestureRetry = true;
          }),
    );
  }

  void _applySfxVolume() {
    final volume = _settings.sfxEnabled ? _settings.sfxVolume : 0.0;
    for (final player in _sfxPlayers) {
      unawaited(player.setVolume(volume).catchError((Object _) {}));
    }
  }

  AudioPlayer _nextSfxPlayer() {
    final player = _sfxPlayers[_sfxCursor % _sfxPlayers.length];
    _sfxCursor++;
    return player;
  }

  String _nextSfxAsset(SfxCue cue, List<String> assets) {
    final index = _sfxVariantCursor[cue] ?? 0;
    _sfxVariantCursor[cue] = index + 1;
    return assets[index % assets.length];
  }

  static bool _isAutomatedTestBinding(WidgetsBinding binding) {
    final bindingType = binding.runtimeType.toString();
    return bindingType.contains('TestWidgetsFlutterBinding') ||
        bindingType.contains('AutomatedTestWidgetsFlutterBinding');
  }
}
