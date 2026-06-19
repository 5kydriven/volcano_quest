import 'package:flutter/material.dart';

import '../../core/constants/assets.dart';
import '../../core/theme/app_theme.dart';

class MissionScreenBackground extends StatelessWidget {
  final Widget child;

  const MissionScreenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          Assets.missionScreenBackground,
          fit: BoxFit.fill,
          alignment: Alignment.center,
        ),
        ColoredBox(color: AppColors.background.withValues(alpha: 0.14)),
        child,
      ],
    );
  }
}

class MissionBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const MissionBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Image.asset(Assets.backButton, height: 36, fit: BoxFit.contain),
    );
  }
}

class MissionResearchTopBar extends StatelessWidget {
  final String title;
  final int xp;
  final int? avatarIndex;
  final VoidCallback onBack;

  const MissionResearchTopBar({
    super.key,
    required this.title,
    required this.xp,
    required this.onBack,
    this.avatarIndex,
  });

  static const _avatarIcons = [
    Icons.person_outline,
    Icons.biotech_outlined,
    Icons.rocket_launch_outlined,
    Icons.hub_outlined,
    Icons.science_outlined,
    Icons.public_outlined,
    Icons.travel_explore_outlined,
    Icons.psychology_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MissionBackButton(onPressed: onBack),
        const Spacer(),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            foreground: Paint()
              ..shader = LinearGradient(
                colors: const [Color(0xFFFFA726), Color(0xFFE65100)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(Rect.fromLTWH(0, 0, 300, 70)),
            shadows: const [
              Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
              Shadow(
                color: Color(0xFF5D2A00),
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
        ),
        const Spacer(),
        _MissionStatusBadge(xp: xp, avatarIndex: avatarIndex),
      ],
    );
  }
}

class _MissionStatusBadge extends StatelessWidget {
  final int xp;
  final int? avatarIndex;

  const _MissionStatusBadge({required this.xp, required this.avatarIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1B14), Color(0xFF120C09)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFB85A12), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33FF7A00), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$xp XP',
            style: const TextStyle(
              color: Color(0xFFFF7A00),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              shadows: [Shadow(color: Colors.black, offset: Offset(1, 1))],
            ),
          ),
          if (avatarIndex != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A1B14), Color(0xFF120C09)],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFB85A12), width: 1.5),
              ),
              child: Icon(
                MissionResearchTopBar._avatarIcons[avatarIndex!.clamp(
                  0,
                  MissionResearchTopBar._avatarIcons.length - 1,
                )],
                color: const Color(0xFFFF7A00),
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
