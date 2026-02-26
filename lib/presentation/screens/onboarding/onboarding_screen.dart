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

  // Three starter monsters (one from each basic element)
  static const _starterTemplateIds = ['slime', 'goblin', 'spark_bug'];

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_selectedTemplateId == null) return;

    final nickname = _nicknameController.text.trim();

    // Create player
    await ref.read(playerProvider.notifier).createNewPlayer(nickname);

    // Load currency (defaults)
    await ref.read(currencyProvider.notifier).load();

    // Create starter monster
    final template = MonsterDatabase.all.firstWhere(
      (t) => t.id == _selectedTemplateId,
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

    // Set as team
    await ref.read(monsterListProvider.notifier).setTeam([starterMonster.id]);
    await ref.read(playerProvider.notifier).updateTeamIds([starterMonster.id]);

    if (mounted) context.go(AppRoutes.battle);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _step == 0 ? _buildNicknameStep(l) : _buildStarterStep(l),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Nickname
  // ---------------------------------------------------------------------------

  Widget _buildNicknameStep(AppLocalizations l) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.catching_pokemon, size: 80, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          l.onboardingWelcome,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l.onboardingEnterName,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nicknameController,
          maxLength: 12,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: l.onboardingNameHint,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _nicknameController.text.trim().length >= 2
                ? () => setState(() => _step = 1)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.disabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Starter monster
  // ---------------------------------------------------------------------------

  Widget _buildStarterStep(AppLocalizations l) {
    final starters = MonsterDatabase.all
        .where((t) => _starterTemplateIds.contains(t.id))
        .toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l.onboardingChooseMonster(_nicknameController.text.trim()),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: starters.map((t) {
            final selected = _selectedTemplateId == t.id;
            final element =
                MonsterElement.fromName(t.element) ?? MonsterElement.fire;
            return GestureDetector(
              onTap: () => setState(() => _selectedTemplateId = t.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: element.color.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Text(element.emoji,
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      element.koreanName,
                      style: TextStyle(
                        fontSize: 11,
                        color: element.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed:
                _selectedTemplateId != null ? _completeOnboarding : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.disabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: Text(
            l.back,
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}
