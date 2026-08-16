import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/mission_screen_background.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: MissionScreenBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _CreditsTopBar(onBack: () => _back(context)),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 36),
                sliver: SliverToBoxAdapter(child: _CreditsContent()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.menu);
  }
}

class _CreditsTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _CreditsTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: MissionBackButton(onPressed: onBack),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'ABOUT VOLCANO QUEST',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'CREDITS & REFERENCES',
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      shadows: [
                        Shadow(color: Color(0x99FF6A18), blurRadius: 12),
                        Shadow(color: Colors.black, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _CreditsContent extends StatelessWidget {
  const _CreditsContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xED160D09),
        border: Border.all(color: const Color(0xFF704025), width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SourceHeader(),
          _CreditDivider(),
          _CreditSection(
            title: 'CONTENT SOURCE',
            body:
                'This educational application\'s learning content, questions, and lesson modules were adapted from:',
          ),
          _CreditDetails(
            entries: [
              (
                'Module Title',
                'Science Grade 9 - Alternative Delivery Mode (ADM)',
              ),
              (
                'Quarter & Subject',
                'Quarter 3 - Earth and Space | Module 1: Different Types of Volcanoes',
              ),
              ('Publication', 'First Edition, 2020'),
              (
                'Publisher',
                'Department of Education - National Capital Region (DepEd NCR)',
              ),
            ],
          ),
          _CreditDivider(),
          _CreditSection(
            title: 'DEVELOPMENT TEAM OF THE MODULE',
            body:
                'Writer: Ellissa Christie Kaye L. Murillo\n\nEditors: Loreta E. Santos, Anthony D. Angeles\n\nReviewers: Anacoreta R. Trogo, Marilou G. Duque, Toribio G. Cruz Jr.\n\nIllustrators: Ellissa Christie Kaye L. Murillo, Neil Edward Diaz\n\nLayout Artists: Anthony D. Angeles, Neil Edward Diaz',
          ),
          SizedBox(height: 18),
          _CreditSection(
            title: 'MANAGEMENT TEAM',
            body:
                'Malcolm S. Garma\nGenia V. Santos\nDennis M. Mendoza\nMicah S. Pacheco\nJosefina M. Pablo\nManolo C. Davantes Jr.\nDalisay E. Esguerra\nHilda C. Valencia',
          ),
          _CreditDivider(),
          _CreditSection(
            title: 'PUBLISHER CONTACT INFO',
            body:
                'Office Address: Misamis St., Bago Bantay, Quezon City\n\nTelefax: (632) 8929-0153\n\nE-mail Address: depedncr@deped.gov.ph',
            selectable: true,
          ),
          _CreditDivider(),
          _CreditSection(
            title: 'DISCLAIMER',
            body:
                'This application is created exclusively for educational and non-commercial purposes. All rights, title, and intellectual property regarding the original learning module content belong to the Department of Education and its respective copyright holders.',
          ),
        ],
      ),
    );
  }
}

class _SourceHeader extends StatelessWidget {
  const _SourceHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.menu_book_outlined, color: AppColors.teal, size: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ABOUT VOLCANO QUEST',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'VOLCANO QUEST ${AppConstants.appVersion}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreditDetails extends StatelessWidget {
  final List<(String, String)> entries;

  const _CreditDetails({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    entries[index].$1.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entries[index].$2,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CreditSection extends StatelessWidget {
  final String title;
  final String body;
  final bool selectable;

  const _CreditSection({
    required this.title,
    required this.body,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      height: 1.55,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (selectable)
          SelectableText(body, style: bodyStyle)
        else
          Text(body, style: bodyStyle),
      ],
    );
  }
}

class _CreditDivider extends StatelessWidget {
  const _CreditDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 22),
      color: const Color(0xFF4F2A1B),
    );
  }
}
