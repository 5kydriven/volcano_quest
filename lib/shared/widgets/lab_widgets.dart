import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_catalog.dart';
import '../../core/audio/audio_controller.dart';
import '../../core/theme/app_theme.dart';

class ScanLine extends StatelessWidget {
  const ScanLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, AppColors.teal, Colors.transparent],
        ),
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final String label;
  const StatusDot({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.teal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class LabBadge extends StatelessWidget {
  final String text;
  const LabBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.teal, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 10,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class LabButton extends ConsumerWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const LabButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                unawaited(
                  ref.read(audioControllerProvider).playSfx(SfxCue.button),
                );
                onTap();
              },
        child: isLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.teal,
                ),
              )
            : Text(label),
      ),
    );
  }
}
