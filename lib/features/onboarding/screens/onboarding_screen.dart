import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/audio/audio_catalog.dart';
import '../../../core/audio/audio_controller.dart';
import '../../../core/constants/assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_routes.dart';
import '../../player/application/player_controller.dart';
import '../../../shared/widgets/mission_screen_background.dart';

const _lava = Color(0xFFFF7A1A);
const _lavaDeep = Color(0xFFC74214);
const _ember = Color(0xFFFFB45F);
const _charcoal = Color(0xFF100F0E);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  int _selectedAvatar = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(audioControllerProvider).setDesiredBgm(BgmTrack.menu);
    });
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(AppRoutes.players);
  }

  void _playButtonSfx() {
    unawaited(ref.read(audioControllerProvider).playSfx(SfxCue.button));
  }

  Future<void> _deploy() async {
    _playButtonSfx();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: const Text(
            'Enter your name to proceed.',
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
      body: MissionScreenBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final sidePadding = constraints.maxWidth < 380 ? 12.0 : 18.0;

              return Padding(
                padding: EdgeInsets.fromLTRB(sidePadding, 10, sidePadding, 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      children: [
                        _OnboardingTopBar(onBack: _isSaving ? null : _cancel),
                        const SizedBox(height: 6),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(0, 2, 0, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 2),
                                const _AlignedOnboardingAsset(
                                  assetPath: Assets.onboardingScientistIdentity,
                                  slotHeight: 154,
                                  imageHeight: 276,
                                ),
                                const SizedBox(height: 18),
                                const _LavaScanLine(),
                                const SizedBox(height: 24),

                                _OnboardingInputField(
                                  controller: _nameController,
                                ),

                                const SizedBox(height: 14),
                                const _AlignedOnboardingAsset(
                                  assetPath: Assets.onboardingSelectAvatarLabel,
                                  slotHeight: 54,
                                  imageHeight: 176,
                                ),
                                const SizedBox(height: 8),

                                _AvatarGrid(
                                  selectedAvatar: _selectedAvatar,
                                  onSelect: (index) {
                                    _playButtonSfx();
                                    setState(() => _selectedAvatar = index);
                                  },
                                ),

                                const SizedBox(height: 14),
                                _SelectedAvatarBanner(
                                  label: Assets.avatars[_selectedAvatar].label,
                                ),

                                const SizedBox(height: 18),
                                _OnboardingDeployButton(
                                  onTap: _deploy,
                                  isLoading: _isSaving,
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  final VoidCallback? onBack;

  const _OnboardingTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MissionBackButton(onPressed: onBack),
        const Spacer(),
        Expanded(
          flex: 8,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'SCIENTIST PROFILE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [_ember, _lava],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                  Shadow(color: _lavaDeep, offset: Offset(2, 2), blurRadius: 0),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _LavaScanLine extends StatelessWidget {
  const _LavaScanLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.7,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            _lavaDeep.withValues(alpha: 0.52),
            _ember.withValues(alpha: 0.92),
            _lavaDeep.withValues(alpha: 0.52),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _lava.withValues(alpha: 0.24),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

class _AlignedOnboardingAsset extends StatelessWidget {
  final String assetPath;
  final double slotHeight;
  final double imageHeight;

  const _AlignedOnboardingAsset({
    required this.assetPath,
    required this.slotHeight,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: slotHeight,
      child: OverflowBox(
        minHeight: 0,
        maxHeight: imageHeight,
        alignment: Alignment.center,
        child: Image.asset(assetPath, height: imageHeight, fit: BoxFit.contain),
      ),
    );
  }
}

class _OnboardingInputField extends StatelessWidget {
  final TextEditingController controller;

  const _OnboardingInputField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldHeight = (constraints.maxWidth * 0.25).clamp(86.0, 108.0);

        return SizedBox(
          height: fieldHeight,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: OverflowBox(
                  maxHeight: fieldHeight * 3.2,
                  alignment: Alignment.center,
                  child: Image.asset(
                    Assets.onboardingInputField,
                    width: constraints.maxWidth,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                left: constraints.maxWidth * 0.11,
                right: constraints.maxWidth * 0.08,
                top: fieldHeight * 0.47,
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: _ember,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                  maxLength: 24,
                  cursorColor: _lava,
                  decoration: const InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OnboardingDeployButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _OnboardingDeployButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Deploy to lab base',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isLoading ? null : onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: isLoading ? 0.99 : 1,
          child: Opacity(
            opacity: isLoading ? 0.72 : 1,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const _AlignedOnboardingAsset(
                  assetPath: Assets.onboardingDeployLabButton,
                  slotHeight: 58,
                  imageHeight: 186,
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _ember,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarGrid extends StatelessWidget {
  final int selectedAvatar;
  final ValueChanged<int> onSelect;

  const _AvatarGrid({required this.selectedAvatar, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: Assets.avatars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.96,
      ),
      itemBuilder: (context, i) => _AvatarTile(
        imagePath: Assets.avatars[i].imagePath,
        animatedPath: Assets.avatars[i].animatedPath,
        label: Assets.avatars[i].label,
        isSelected: selectedAvatar == i,
        onTap: () => onSelect(i),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final String imagePath;
  final String animatedPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.imagePath,
    required this.animatedPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isSelected ? 1 : 0.96,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected
                ? _lavaDeep.withValues(alpha: 0.2)
                : const Color.fromARGB(255, 23, 21, 18).withValues(alpha: 0.82),
            border: Border.all(
              color: isSelected ? _lava : _lavaDeep.withValues(alpha: 0.46),
              width: 4,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x33FF7A00),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isSelected
                      ? _LoopingAvatarVideo(
                          videoPath: animatedPath,
                          fallbackImagePath: imagePath,
                        )
                      : Image.asset(imagePath, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? _ember : _lava,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoopingAvatarVideo extends StatefulWidget {
  final String videoPath;
  final String fallbackImagePath;

  const _LoopingAvatarVideo({
    required this.videoPath,
    required this.fallbackImagePath,
  });

  @override
  State<_LoopingAvatarVideo> createState() => _LoopingAvatarVideoState();
}

class _LoopingAvatarVideoState extends State<_LoopingAvatarVideo> {
  late final VideoPlayerController _controller;
  var _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset(
            widget.videoPath,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..setLooping(true)
          ..setVolume(0);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
    } catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _isReady = true);
    try {
      await _controller.play();
    } catch (_) {
      // Keep the static fallback if playback is unavailable.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Image.asset(widget.fallbackImagePath, fit: BoxFit.cover);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
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
        color: _charcoal.withValues(alpha: 0.84),
        border: Border.all(
          color: _lavaDeep.withValues(alpha: 0.68),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: _lava.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _lava, size: 14),
          const SizedBox(width: 8),
          Text(
            'AVATAR: $label'.toUpperCase(),
            style: const TextStyle(
              color: _ember,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
