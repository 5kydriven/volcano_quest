import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_routes.dart';
import '../../player/application/player_controller.dart';
import '../../../shared/widgets/lab_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  int _selectedAvatar = 0;
  bool _isSaving = false;

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

  static const _avatarLabels = [
    'Scientist',
    'Researcher',
    'Explorer',
    'Analyst',
    'Chemist',
    'Geologist',
    'Observer',
    'Strategist',
  ];

  Future<void> _deploy() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: const Text(
            'Enter your callsign to proceed.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await ref
        .read(playerProvider.notifier)
        .setProfile(name: name, avatarIndex: _selectedAvatar);
    if (mounted) {
      context.go(AppRoutes.menu);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STEP 1 OF 1 · SCIENTIST PROFILE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create your\nscientist identity',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              const ScanLine(),
              const SizedBox(height: 20),

              _fieldLabel('CALLSIGN (NAME)'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                maxLength: 24,
                decoration: const InputDecoration(
                  hintText: 'Enter your name...',
                  counterStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _fieldLabel('SELECT AVATAR'),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _avatarIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) => _AvatarTile(
                  icon: _avatarIcons[i],
                  label: _avatarLabels[i],
                  isSelected: _selectedAvatar == i,
                  onTap: () => setState(() => _selectedAvatar = i),
                ),
              ),

              const SizedBox(height: 16),
              _SelectedAvatarBanner(label: _avatarLabels[_selectedAvatar]),

              const SizedBox(height: 28),
              LabButton(
                label: 'DEPLOY TO LAB BASE',
                onTap: _deploy,
                isLoading: _isSaving,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceAlt : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.borderAlt,
            width: isSelected ? 1.0 : 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.teal : AppColors.textMuted,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 7,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedAvatarBanner extends StatelessWidget {
  final String label;
  const _SelectedAvatarBanner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderAlt, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.teal,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            'AVATAR: $label'.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
