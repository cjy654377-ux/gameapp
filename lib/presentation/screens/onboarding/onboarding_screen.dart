import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import 'package:gameapp/l10n/app_localizations.dart';
import '../../../core/enums/monster_element.dart';
import '../../../data/models/monster_model.dart';
import '../../../data/static/monster_database.dart';
import '../../../routing/app_router.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/monster_avatar.dart';
import '../../providers/monster_provider.dart';
import '../../providers/player_provider.dart';

/// First-run onboarding: nickname input + starter monster selection.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nicknameController = TextEditingController();
  int _step = 0; // 0=nickname, 1=pick starter
  String? _selectedTemplateId;

  // Six starter monsters (one per basic element)
  static const _starterTemplateIds = [
    'slime',        // water
    'flame_spirit', // fire
    'spark_bug',    // electric
    'pebble',       // stone
    'wisp',         // light
    'goblin',       // grass
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_selectedTemplateId == null) return;

    final nickname = _nicknameController.text.trim();

    try {
      await ref.read(playerProvider.notifier).createNewPlayer(nickname);
      await ref.read(currencyProvider.notifier).load();

      final template = MonsterDatabase.all.firstWhere(
        (t) => t.id == _selectedTemplateId,
        orElse: () => MonsterDatabase.all.first,
      );
      final starterMonster = MonsterModel.fromTemplate(
        id: 'starter_${template.id}',
        templateId: template.id,
        name: template.name,
        rarity: template.rarity,
        element: template.element,
        baseAtk: template.baseAtk,
        baseDef: template.baseDef,
        baseHp: template.baseHp,
        baseSpd: template.baseSpd,
        size: template.size,
      );
      await ref.read(monsterListProvider.notifier).addMonster(starterMonster);
      await ref.read(monsterListProvider.notifier).setTeam([starterMonster.id]);
      await ref.read(playerProvider.notifier).updateTeamIds([starterMonster.id]);

      if (mounted) context.go(AppRoutes.battle);
    } catch (e) {
      debugPrint('[Onboarding] _completeOnboarding error: $e');
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.onboardingSetupError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0
                    ? _NicknameStep(
                        key: const ValueKey(0),
                        controller: _nicknameController,
                        onNext: () => setState(() => _step = 1),
                        l: l,
                      )
                    : _StarterStep(
                        key: const ValueKey(1),
                        nickname: _nicknameController.text.trim(),
                        selectedId: _selectedTemplateId,
                        starterIds: _starterTemplateIds,
                        onSelect: (id) =>
                            setState(() => _selectedTemplateId = id),
                        onComplete: _completeOnboarding,
                        onBack: () => setState(() => _step = 0),
                        l: l,
                      ),
              ),
            ),
            // Step indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepDot(active: _step == 0),
                  const SizedBox(width: 8),
                  _StepDot(active: _step == 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Step Dot
// =============================================================================

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// =============================================================================
// Step 1: Nickname
// =============================================================================

class _NicknameStep extends StatelessWidget {
  const _NicknameStep({
    super.key,
    required this.controller,
    required this.onNext,
    required this.l,
  });

  final TextEditingController controller;
  final VoidCallback onNext;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.3),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.catching_pokemon,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l.onboardingWelcome,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.onboardingEnterName,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            maxLength: 12,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: l.onboardingNameHint,
              hintStyle: TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onChanged: (_) {},
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: value.text.trim().length >= 2 ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.disabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: Text(
                l.next,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Step 2: Starter Monster
// =============================================================================

class _StarterStep extends StatelessWidget {
  const _StarterStep({
    super.key,
    required this.nickname,
    required this.selectedId,
    required this.starterIds,
    required this.onSelect,
    required this.onComplete,
    required this.onBack,
    required this.l,
  });

  final String nickname;
  final String? selectedId;
  final List<String> starterIds;
  final ValueChanged<String> onSelect;
  final VoidCallback onComplete;
  final VoidCallback onBack;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final starters = MonsterDatabase.all
        .where((t) => starterIds.contains(t.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            l.onboardingChooseMonster(nickname),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.onboardingEnterName,
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 24),
          // 2x3 grid of starters
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: starters.length,
              itemBuilder: (_, i) => _StarterCard(
                template: starters[i],
                selected: selectedId == starters[i].id,
                onTap: () => onSelect(starters[i].id),
              ),
            ),
          ),
          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: selectedId != null ? onComplete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.disabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: Text(
                l.onboardingStart,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onBack,
            child: Text(l.back, style: TextStyle(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final MonsterTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final element =
        MonsterElement.fromName(template.element) ?? MonsterElement.fire;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? element.color.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? element.color : AppColors.border,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: element.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Monster avatar
            MonsterAvatar(name: template.name, element: template.element, rarity: template.rarity, templateId: template.id, size: 48),
            const SizedBox(height: 6),
            // Name
            Text(
              template.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Element tag
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: element.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                element.koreanName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: element.color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Mini stats
            _MiniStats(template: template),
          ],
        ),
      ),
    );
  }
}

class _MiniStats extends StatelessWidget {
  const _MiniStats({required this.template});
  final MonsterTemplate template;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatDot(label: 'ATK', value: template.baseAtk, color: Colors.red),
        const SizedBox(width: 4),
        _StatDot(label: 'HP', value: template.baseHp, color: Colors.green),
        const SizedBox(width: 4),
        _StatDot(label: 'SPD', value: template.baseSpd, color: Colors.blue),
      ],
    );
  }
}

class _StatDot extends StatelessWidget {
  const _StatDot({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${value.toInt()}',
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
