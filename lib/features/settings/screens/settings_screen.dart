import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_screen_background.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _settingsTopBar(context),
                  const SizedBox(height: 28),
                  _labelText('AUDIO CONTROL', fontSize: 18),
                  const SizedBox(height: 18),
                  _labelText('LAB SYSTEM PREFERENCES', fontSize: 13),
                  const SizedBox(height: 24),
                  _lavaDivider(),
                  const SizedBox(height: 24),
                  _settingsPanel(
                    children: [
                      _settingSwitchRow(
                        assetPath: settings.masterMuted
                            ? Assets.settingMute
                            : Assets.settingUnmute,
                        title: 'Mute all audio',
                        subtitle: settings.masterMuted
                            ? 'BGM and SFX output disabled'
                            : 'BGM and SFX follow channel settings',
                        value: settings.masterMuted,
                        onChanged: notifier.setMasterMuted,
                      ),
                      _panelDivider(),
                      _audioChannelRow(
                        assetPath: Assets.settingBgm,
                        title: 'BGM',
                        subtitle: settings.bgmEnabled
                            ? 'Background music enabled'
                            : 'Background music muted',
                        enabled: !settings.masterMuted,
                        switchValue: !settings.bgmMuted,
                        volume: settings.bgmVolume,
                        onSwitchChanged: (value) =>
                            notifier.setBgmMuted(!value),
                        onVolumeChanged: notifier.setBgmVolume,
                      ),
                      _panelDivider(),
                      _audioChannelRow(
                        assetPath: Assets.settingSfx,
                        title: 'SFX',
                        subtitle: settings.sfxEnabled
                            ? 'Interaction sounds enabled'
                            : 'Interaction sounds muted',
                        enabled: !settings.masterMuted,
                        switchValue: !settings.sfxMuted,
                        volume: settings.sfxVolume,
                        onSwitchChanged: (value) =>
                            notifier.setSfxMuted(!value),
                        onVolumeChanged: notifier.setSfxVolume,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _settingsPanel(
                    children: [_quitRow(onTap: () => _confirmQuit(context))],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingsTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          MissionBackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(AppRoutes.menu);
            },
          ),
          const Spacer(),
          _lavaHeading('SETTINGS', size: 32),
          const Spacer(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _labelText(String text, {required double fontSize}) {
    return Text(
      text,
      style: TextStyle(
        color: text == 'AUDIO CONTROL'
            ? const Color(0xFFFF7A1A)
            : const Color(0xFFC7B7A7),
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        shadows: const [Shadow(color: Colors.black, offset: Offset(2, 2))],
      ),
    );
  }

  Widget _lavaHeading(String text, {required double size}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFFFB13A), Color(0xFFFF6416), Color(0xFFC43110)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromLTWH(0, 0, 420, 90)),
          shadows: const [
            Shadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
            Shadow(color: Color(0xFF6C2500), offset: Offset(2, 2)),
          ],
        ),
      ),
    );
  }

  Widget _lavaDivider() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFF4D2A1B),
            Color(0xFFFF7A14),
            Color(0xFF4D2A1B),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _settingsPanel({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 24, 24, 24).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF8E4526), width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 10),
          BoxShadow(color: Color(0x33FF5C00), blurRadius: 5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(children: children),
      ),
    );
  }

  Widget _settingSwitchRow({
    required String assetPath,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          _settingsAssetIcon(assetPath),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _settingsTitle(title),
                const SizedBox(height: 6),
                _settingsSubtitle(subtitle),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _settingsToggle(
            value: value,
            onTap: onChanged == null ? null : () => onChanged(!value),
          ),
        ],
      ),
    );
  }

  Widget _audioChannelRow({
    required String assetPath,
    required String title,
    required String subtitle,
    required bool enabled,
    required bool switchValue,
    required double volume,
    required ValueChanged<bool> onSwitchChanged,
    required ValueChanged<double> onVolumeChanged,
  }) {
    final channelActive = enabled && switchValue;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Row(
            children: [
              _settingsAssetIcon(assetPath),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _settingsTitle(title),
                    const SizedBox(height: 6),
                    _settingsSubtitle(
                      enabled ? subtitle : 'Disabled by mute all audio',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _settingsToggle(
                value: channelActive,
                onTap: enabled ? () => onSwitchChanged(!switchValue) : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _croppedAsset(
                Assets.settingUnmute,
                width: 34,
                height: 28,
                scale: 1.35,
              ),
              Expanded(
                child: _lavaSlider(
                  value: volume,
                  onChanged: channelActive ? onVolumeChanged : null,
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '${(volume * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFFF7A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(color: Colors.black, offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Opacity(opacity: enabled ? 1 : 0.48, child: content);
  }

  Widget _settingsAssetIcon(String assetPath) {
    return _croppedAsset(assetPath, width: 66, height: 66, scale: 1.35);
  }

  Widget _settingsToggle({required bool value, required VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: _croppedAsset(
          value ? Assets.settingToggleOn : Assets.settingToggleOff,
          width: 74,
          height: 42,
          scale: 1.35,
        ),
      ),
    );
  }

  Widget _croppedAsset(
    String assetPath, {
    required double width,
    required double height,
    required double scale,
  }) {
    return ClipRect(
      child: SizedBox(
        width: width,
        height: height,
        child: Transform.scale(
          scale: scale,
          child: Image.asset(assetPath, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _settingsTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFFFF7A1A),
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))],
      ),
    );
  }

  Widget _settingsSubtitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD0C2B5),
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
      ),
    );
  }

  Widget _lavaSlider({
    required double value,
    required ValueChanged<double>? onChanged,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: const Color(0xFFFF6A12),
        inactiveTrackColor: const Color(0xFF32241C),
        thumbColor: const Color(0xFFFF7A1A),
        overlayColor: const Color(0x33FF7A1A),
        disabledActiveTrackColor: const Color(0xFF7A3518),
        disabledInactiveTrackColor: const Color(0xFF2A211D),
        disabledThumbColor: const Color(0xFF6D4B36),
      ),
      child: Slider(
        value: value,
        min: 0,
        max: 1,
        divisions: 10,
        onChanged: onChanged,
      ),
    );
  }

  Widget _quitRow({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x22FF7A1A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            _powerPlate(),
            const SizedBox(width: 16),
            Expanded(child: _settingsTitle('QUIT APP')),
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF16110E),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF8E4526), width: 1),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Color(0xFFFF7A1A),
                size: 28,
                shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _powerPlate() {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF16110E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8E4526), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x33FF5C00), blurRadius: 6)],
      ),
      child: const Icon(
        Icons.power_settings_new,
        color: Color(0xFFFF7A1A),
        size: 30,
        shadows: [Shadow(color: Colors.black, offset: Offset(2, 2))],
      ),
    );
  }

  Widget _panelDivider() {
    return const Divider(color: Color(0xFF6C351F), thickness: 1, height: 0);
  }

  Future<void> _confirmQuit(BuildContext context) async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Quit Volcano Quest?'),
          content: const Text('Your mission progress is saved locally.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('QUIT'),
            ),
          ],
        );
      },
    );

    if (shouldQuit == true && context.mounted) {
      context.go(AppRoutes.splash);
    }
  }
}
