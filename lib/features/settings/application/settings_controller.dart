import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/shared_preferences_provider.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

class AppSettings {
  final bool masterMuted;
  final bool bgmMuted;
  final bool sfxMuted;
  final double bgmVolume;
  final double sfxVolume;

  const AppSettings({
    required this.masterMuted,
    required this.bgmMuted,
    required this.sfxMuted,
    required this.bgmVolume,
    required this.sfxVolume,
  });

  const AppSettings.defaults()
    : masterMuted = false,
      bgmMuted = false,
      sfxMuted = false,
      bgmVolume = 0.7,
      sfxVolume = 0.85;

  bool get bgmEnabled => !masterMuted && !bgmMuted;
  bool get sfxEnabled => !masterMuted && !sfxMuted;

  AppSettings copyWith({
    bool? masterMuted,
    bool? bgmMuted,
    bool? sfxMuted,
    double? bgmVolume,
    double? sfxVolume,
  }) {
    return AppSettings(
      masterMuted: masterMuted ?? this.masterMuted,
      bgmMuted: bgmMuted ?? this.bgmMuted,
      sfxMuted: sfxMuted ?? this.sfxMuted,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(const AppSettings.defaults()) {
    state = AppSettings(
      masterMuted:
          _prefs.getBool(AppConstants.prefSettingsMasterMuted) ?? false,
      bgmMuted: _prefs.getBool(AppConstants.prefSettingsBgmMuted) ?? false,
      sfxMuted: _prefs.getBool(AppConstants.prefSettingsSfxMuted) ?? false,
      bgmVolume: _readVolume(AppConstants.prefSettingsBgmVolume, 0.7),
      sfxVolume: _readVolume(AppConstants.prefSettingsSfxVolume, 0.85),
    );
  }

  double _readVolume(String key, double fallback) {
    return (_prefs.getDouble(key) ?? fallback).clamp(0.0, 1.0);
  }

  Future<void> setMasterMuted(bool value) async {
    state = state.copyWith(masterMuted: value);
    await _prefs.setBool(AppConstants.prefSettingsMasterMuted, value);
  }

  Future<void> setBgmMuted(bool value) async {
    state = state.copyWith(bgmMuted: value);
    await _prefs.setBool(AppConstants.prefSettingsBgmMuted, value);
  }

  Future<void> setSfxMuted(bool value) async {
    state = state.copyWith(sfxMuted: value);
    await _prefs.setBool(AppConstants.prefSettingsSfxMuted, value);
  }

  Future<void> setBgmVolume(double value) async {
    final volume = value.clamp(0.0, 1.0);
    state = state.copyWith(bgmVolume: volume);
    await _prefs.setDouble(AppConstants.prefSettingsBgmVolume, volume);
  }

  Future<void> setSfxVolume(double value) async {
    final volume = value.clamp(0.0, 1.0);
    state = state.copyWith(sfxVolume: volume);
    await _prefs.setDouble(AppConstants.prefSettingsSfxVolume, volume);
  }
}
