import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/lab_widgets.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SettingsTopBar(),
              const SizedBox(height: 34),
              const LabBadge(text: 'AUDIO CONTROL'),
              const SizedBox(height: 18),
              const Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'LAB SYSTEM PREFERENCES',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const ScanLine(),
              const SizedBox(height: 22),
              _SettingsPanel(
                children: [
                  _SettingSwitchRow(
                    icon: settings.masterMuted
                        ? Icons.volume_off_outlined
                        : Icons.volume_up_outlined,
                    title: 'Mute all audio',
                    subtitle: settings.masterMuted
                        ? 'BGM and SFX output disabled'
                        : 'BGM and SFX follow channel settings',
                    value: settings.masterMuted,
                    onChanged: notifier.setMasterMuted,
                  ),
                  const _PanelDivider(),
                  _AudioChannelRow(
                    icon: Icons.music_note_outlined,
                    title: 'BGM',
                    subtitle: settings.bgmEnabled
                        ? 'Background music enabled'
                        : 'Background music muted',
                    enabled: !settings.masterMuted,
                    switchValue: !settings.bgmMuted,
                    volume: settings.bgmVolume,
                    onSwitchChanged: (value) => notifier.setBgmMuted(!value),
                    onVolumeChanged: notifier.setBgmVolume,
                  ),
                  const _PanelDivider(),
                  _AudioChannelRow(
                    icon: Icons.graphic_eq_outlined,
                    title: 'SFX',
                    subtitle: settings.sfxEnabled
                        ? 'Interaction sounds enabled'
                        : 'Interaction sounds muted',
                    enabled: !settings.masterMuted,
                    switchValue: !settings.sfxMuted,
                    volume: settings.sfxVolume,
                    onSwitchChanged: (value) => notifier.setSfxMuted(!value),
                    onVolumeChanged: notifier.setSfxVolume,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsPanel(
                children: [
                  _QuitRow(onTap: () => _confirmQuit(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

    if (shouldQuit == true) {
      if (context.mounted) {
        context.go(AppRoutes.splash);
      }
    }
  }
}

class _SettingsTopBar extends StatelessWidget {
  const _SettingsTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(AppRoutes.menu);
          },
        ),
        const Spacer(),
        const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.teal,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final List<Widget> children;

  const _SettingsPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.teal, width: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.teal, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: AppColors.teal,
            activeTrackColor: AppColors.teal.withValues(alpha: 0.28),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AudioChannelRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool switchValue;
  final double volume;
  final ValueChanged<bool> onSwitchChanged;
  final ValueChanged<double> onVolumeChanged;

  const _AudioChannelRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.switchValue,
    required this.volume,
    required this.onSwitchChanged,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final channelActive = enabled && switchValue;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.teal, width: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.teal, size: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      enabled ? subtitle : 'Disabled by mute all audio',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: switchValue,
                activeThumbColor: AppColors.teal,
                activeTrackColor: AppColors.teal.withValues(alpha: 0.28),
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.border,
                onChanged: enabled ? onSwitchChanged : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.volume_down_outlined,
                color: AppColors.textMuted,
                size: 17,
              ),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  activeColor: AppColors.teal,
                  inactiveColor: AppColors.border,
                  onChanged: channelActive ? onVolumeChanged : null,
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  '${(volume * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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
}

class _QuitRow extends StatelessWidget {
  final VoidCallback onTap;

  const _QuitRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.teal.withValues(alpha: 0.05),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.power_settings_new, color: AppColors.teal, size: 20),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'QUIT APP',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, thickness: 0.5, height: 0);
  }
}
