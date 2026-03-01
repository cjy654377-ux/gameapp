import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/skin_resolver.dart';
import '../../../core/enums/monster_rarity.dart';
import '../../../core/constants/game_config.dart';
import '../../../data/models/monster_model.dart';
import '../../../data/models/relic_model.dart';
import '../../../data/static/skin_database.dart';
import '../../../data/static/skill_database.dart';
import '../../providers/monster_provider.dart';
import '../../providers/relic_provider.dart';
import '../../providers/skin_provider.dart';

/// Full-screen monster detail profile.
class MonsterDetailScreen extends ConsumerWidget {
  const MonsterDetailScreen({super.key, required this.monster});

  final MonsterModel monster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final rarity = MonsterRarity.fromRarity(monster.rarity);
    final element =
        MonsterElement.fromName(monster.element) ?? MonsterElement.fire;
    final displayEmoji = SkinResolver.emoji(monster);
    final displayColor = SkinResolver.color(monster);
    final skill = SkillDatabase.findByTemplateId(monster.templateId);
    final relicNotifier = ref.read(relicProvider.notifier);
    final relicBonus = relicNotifier.relicBonuses(monster.id);
    final equippedRelics = ref.watch(relicProvider)
        .where((r) => r.equippedMonsterId == monster.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: displayColor.withValues(alpha: 0.3),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      displayColor.withValues(alpha: 0.4),
                      AppColors.background,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: displayColor.withValues(alpha: 0.25),
                          border: Border.all(color: rarity.color, width: 3),
                        ),
                        child: Center(
                          child: Text(displayEmoji,
                              style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showNicknameDialog(context, ref, monster, l),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              monster.displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 14, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                      if (monster.nickname != null)
                        Text(
                          monster.name,
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            rarity.starsDisplay,
                            style: TextStyle(color: rarity.color, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${element.koreanName} | Lv.${monster.level}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.auto_awesome,
                        label: l.evolutionStage(monster.evolutionStage),
                        color: rarity.color,
                      ),
                      _InfoChip(
                        icon: monster.isInTeam ? Icons.check_circle : Icons.remove_circle_outline,
                        label: monster.isInTeam ? l.teamAssigned : l.teamNotAssigned,
                        color: monster.isInTeam ? Colors.green : AppColors.textTertiary,
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label: l.acquiredDate(_formatDate(monster.acquiredAt)),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stat radar chart
                  _SectionTitle(title: l.stats),
                  const SizedBox(height: 8),
                  _StatRadarChart(monster: monster, relicBonus: relicBonus),
                  const SizedBox(height: 8),

                  // Stat details (tap to expand breakdown)
                  _StatDetailRow(
                    label: 'HP',
                    base: monster.finalHp,
                    bonus: relicBonus.hp,
                    color: Colors.green,
                    monster: monster,
                  ),
                  _StatDetailRow(
                    label: 'ATK',
                    base: monster.finalAtk,
                    bonus: relicBonus.atk,
                    color: Colors.red,
                    monster: monster,
                  ),
                  _StatDetailRow(
                    label: 'DEF',
                    base: monster.finalDef,
                    bonus: relicBonus.def,
                    color: Colors.blue,
                    monster: monster,
                  ),
                  _StatDetailRow(
                    label: 'SPD',
                    base: monster.finalSpd,
                    bonus: relicBonus.spd,
                    color: Colors.amber,
                    monster: monster,
                  ),
                  const SizedBox(height: 20),

                  // EXP progress
                  _SectionTitle(title: l.experience),
                  const SizedBox(height: 8),
                  _ExpBar(monster: monster),
                  const SizedBox(height: 20),

                  // Affinity
                  _SectionTitle(title: l.affinity),
                  const SizedBox(height: 8),
                  _AffinityBar(monster: monster),
                  const SizedBox(height: 20),

                  // Skill
                  _SectionTitle(title: l.skill),
                  const SizedBox(height: 8),
                  if (skill != null)
                    _SkillCard(skill: skill)
                  else
                    Text(
                      l.noSkill,
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  const SizedBox(height: 20),

                  // Passive skill
                  Builder(builder: (_) {
                    final passive = SkillDatabase.findPassive(monster.templateId);
                    if (passive == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(title: l.passiveSkill),
                        const SizedBox(height: 8),
                        _PassiveCard(passive: passive, l: l),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),

                  // Ultimate skill
                  Builder(builder: (_) {
                    final ult = SkillDatabase.findUltimate(monster.templateId);
                    if (ult == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(title: l.ultimateSkill),
                        const SizedBox(height: 8),
                        _UltimateCard(ultimate: ult, l: l),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),

                  // Evolution tree
                  _SectionTitle(title: l.evolutionTree),
                  const SizedBox(height: 8),
                  _EvolutionTree(monster: monster, l: l),
                  const SizedBox(height: 20),

                  // Element matchup
                  _SectionTitle(title: l.elementMatchup),
                  const SizedBox(height: 4),
                  Text(
                    l.elementMatchupDesc,
                    style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 8),
                  _ElementMatchupTable(element: element),
                  const SizedBox(height: 20),

                  // Skin section
                  _SkinSection(monster: monster, l: l),
                  const SizedBox(height: 20),

                  // Equipped relics
                  _SectionTitle(title: '${l.equippedRelics} (${equippedRelics.length})'),
                  const SizedBox(height: 8),
                  if (equippedRelics.isEmpty)
                    Text(
                      l.noRelics,
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    )
                  else
                    ...equippedRelics.map((r) => _RelicTile(relic: r)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => FormatUtils.formatDate(dt);

  void _showNicknameDialog(
    BuildContext context,
    WidgetRef ref,
    MonsterModel monster,
    AppLocalizations l,
  ) {
    final controller = TextEditingController(text: monster.nickname ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.nicknameTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLength: 10,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: monster.name,
            hintStyle: TextStyle(color: AppColors.textTertiary),
          ),
        ),
        actions: [
          if (monster.nickname != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                final updated = monster.copyWith(nickname: null);
                ref.read(monsterListProvider.notifier).updateMonster(updated);
              },
              child: Text(l.nicknameReset,
                  style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel,
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final text = controller.text.trim();
              final updated = text.isEmpty
                  ? monster.copyWith(nickname: null)
                  : monster.copyWith(nickname: text);
              ref.read(monsterListProvider.notifier).updateMonster(updated);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Section title
// =============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// =============================================================================
// Info chip
// =============================================================================

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Stat radar chart (simplified pentagon)
// =============================================================================

class _StatRadarChart extends StatelessWidget {
  const _StatRadarChart({required this.monster, required this.relicBonus});
  final MonsterModel monster;
  final ({double atk, double def, double hp, double spd}) relicBonus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        size: const Size(double.infinity, 180),
        painter: _RadarPainter(
          values: [
            ((monster.finalHp + relicBonus.hp) / 2000).clamp(0.0, 1.0),
            ((monster.finalAtk + relicBonus.atk) / 500).clamp(0.0, 1.0),
            ((monster.finalDef + relicBonus.def) / 500).clamp(0.0, 1.0),
            ((monster.finalSpd + relicBonus.spd) / 50).clamp(0.0, 1.0),
          ],
          labels: ['HP', 'ATK', 'DEF', 'SPD'],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2 - 20;
    final count = values.length;

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i <= count; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * (i % count) / count);
        final pt = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    // Draw values
    final valuePath = Path();
    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i <= count; i++) {
      final idx = i % count;
      final v = values[idx].clamp(0.0, 1.0);
      final angle = -math.pi / 2 + (2 * math.pi * idx / count);
      final pt = Offset(
        center.dx + radius * v * math.cos(angle),
        center.dy + radius * v * math.sin(angle),
      );
      if (i == 0) {
        valuePath.moveTo(pt.dx, pt.dy);
      } else {
        valuePath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, strokePaint);

    // Draw labels
    for (int i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      final labelOffset = Offset(
        center.dx + (radius + 14) * math.cos(angle) - 10,
        center.dy + (radius + 14) * math.sin(angle) - 6,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

// =============================================================================
// Stat detail row
// =============================================================================

class _StatDetailRow extends StatefulWidget {
  const _StatDetailRow({
    required this.label,
    required this.base,
    required this.bonus,
    required this.color,
    this.monster,
  });
  final String label;
  final double base;
  final double bonus;
  final Color color;
  final MonsterModel? monster;

  @override
  State<_StatDetailRow> createState() => _StatDetailRowState();
}

class _StatDetailRowState extends State<_StatDetailRow> {
  bool _expanded = false;

  double _getBaseStat() {
    final m = widget.monster;
    if (m == null) return widget.base;
    return switch (widget.label) {
      'ATK' => m.baseAtk,
      'DEF' => m.baseDef,
      'HP' => m.baseHp,
      'SPD' => m.baseSpd,
      _ => widget.base,
    };
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.base + widget.bonus;
    return Column(
      children: [
        GestureDetector(
          onTap: widget.monster != null ? () => setState(() => _expanded = !_expanded) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (total / 2000).clamp(0.0, 1.0),
                      backgroundColor: AppColors.surfaceVariant,
                      color: widget.color.withValues(alpha: 0.7),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (widget.monster != null)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                SizedBox(
                  width: 70,
                  child: Text(
                    widget.bonus > 0
                        ? '${total.round()} (+${widget.bonus.round()})'
                        : '${total.round()}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.bonus > 0 ? Colors.amber : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded && widget.monster != null)
          _buildBreakdown(),
      ],
    );
  }

  Widget _buildBreakdown() {
    final m = widget.monster!;
    final baseStat = _getBaseStat();
    final lvlMult = 1.0 + (m.level - 1) * 0.05;
    final evoMult = switch (m.evolutionStage) { 1 => 1.25, 2 => 1.60, _ => 1.0 };
    final awkMult = 1.0 + m.awakeningStars * 0.10;
    final affMult = 1.0 + m.affinityLevel * 0.02;

    final afterLvl = baseStat * lvlMult;
    final afterEvo = afterLvl * evoMult;
    final afterAwk = afterEvo * awkMult;
    final afterAff = afterAwk * affMult;

    return Container(
      margin: const EdgeInsets.only(left: 36, bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _breakdownLine('Base', baseStat, null),
          _breakdownLine('Lv.${m.level}', afterLvl, lvlMult),
          if (m.evolutionStage > 0) _breakdownLine('Evo ${m.evolutionStage}', afterEvo, evoMult),
          if (m.awakeningStars > 0) _breakdownLine('Awaken ★${m.awakeningStars}', afterAwk, awkMult),
          if (m.affinityLevel > 0) _breakdownLine('Bond Lv.${m.affinityLevel}', afterAff, affMult),
          if (widget.bonus > 0) _breakdownLine('Relic', afterAff + widget.bonus, null, isBonus: true),
        ],
      ),
    );
  }

  Widget _breakdownLine(String label, double value, double? mult, {bool isBonus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: isBonus ? Colors.amber : AppColors.textSecondary),
            ),
          ),
          if (mult != null)
            Text(
              '×${mult.toStringAsFixed(2)}  ',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          const Spacer(),
          Text(
            '${value.round()}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isBonus ? Colors.amber : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EXP bar
// =============================================================================

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.monster});
  final MonsterModel monster;

  @override
  Widget build(BuildContext context) {
    final expNeeded = monster.expToNextLevel;
    final progress = expNeeded > 0
        ? (monster.experience / expNeeded).clamp(0.0, 1.0)
        : 1.0;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceVariant,
            color: Colors.cyan,
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${monster.experience} / $expNeeded EXP',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// =============================================================================
// Affinity bar
// =============================================================================

class _AffinityBar extends StatelessWidget {
  const _AffinityBar({required this.monster});
  final MonsterModel monster;

  static const _thresholds = [10, 30, 60, 100, 150];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final levelNames = l.affinityNames.split(',');
    final level = monster.affinityLevel;
    final isMax = level >= 5;
    final currentThreshold = isMax ? 150 : _thresholds[level];
    final prevThreshold = level > 0 ? _thresholds[level - 1] : 0;
    final progressInLevel = isMax
        ? 1.0
        : ((monster.battleCount - prevThreshold) / (currentThreshold - prevThreshold)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Hearts for level
            for (int i = 0; i < 5; i++)
              Icon(
                i < level ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: i < level ? Colors.pinkAccent : AppColors.textTertiary,
              ),
            const SizedBox(width: 8),
            Text(
              levelNames[level],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: level > 0 ? Colors.pinkAccent : AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              l.affinityBattleCount(monster.battleCount),
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressInLevel,
            backgroundColor: AppColors.surfaceVariant,
            color: Colors.pinkAccent,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isMax
              ? l.affinityBonus(level * 2)
              : l.affinityNext(monster.battleCountToNextAffinity, level * 2),
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// =============================================================================
// Skill card
// =============================================================================

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill});
  final SkillDefinition skill;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high, color: Colors.purple[300], size: 20),
              const SizedBox(width: 8),
              Text(
                skill.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.purpleAccent,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.skillCd(skill.cooldown),
                  style: TextStyle(fontSize: 11, color: Colors.purple[200]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            skill.description,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (skill.damageMultiplier > 0)
                _SkillTag(
                  label: '${skill.damageMultiplier}x ${skill.damageTarget == SkillTargetType.allEnemies ? l.tagAll : l.tagSingle}',
                  color: Colors.red,
                ),
              if (skill.shieldPercent > 0)
                _SkillTag(
                  label: '${l.tagShield((skill.shieldPercent * 100).round())}${skill.isTeamShield ? " ${l.tagAll}" : ""}',
                  color: Colors.blue,
                ),
              if (skill.healPercent > 0)
                _SkillTag(
                  label: '${l.tagHeal((skill.healPercent * 100).round())}${skill.isTeamHeal ? " ${l.tagAll}" : ""}',
                  color: Colors.green,
                ),
              if (skill.drainPercent > 0)
                _SkillTag(label: l.tagDrain((skill.drainPercent * 100).round()), color: Colors.teal),
              if (skill.burnTurns > 0)
                _SkillTag(label: l.tagBurn(skill.burnTurns), color: Colors.orange),
              if (skill.stunChance > 0)
                _SkillTag(label: l.tagStun((skill.stunChance * 100).round()), color: Colors.amber),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  const _SkillTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// =============================================================================
// Relic tile
// =============================================================================

class _RelicTile extends StatelessWidget {
  const _RelicTile({required this.relic});
  final RelicModel relic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            _typeIcon(relic.type),
            color: Colors.amber,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relic.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  l.relicInfo(_statLabel(relic.statType, l), relic.statValue.toInt(), relic.rarity),
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'weapon': return Icons.gavel;
      case 'armor': return Icons.shield;
      case 'accessory': return Icons.diamond;
      default: return Icons.inventory;
    }
  }

  String _statLabel(String stat, AppLocalizations l) {
    switch (stat) {
      case 'atk': return l.statAttack;
      case 'def': return l.statDefense;
      case 'hp': return l.statHp;
      case 'spd': return l.statSpeed;
      default: return stat;
    }
  }
}

// =============================================================================
// Passive skill card
// =============================================================================

class _PassiveCard extends StatelessWidget {
  const _PassiveCard({required this.passive, required this.l});
  final PassiveDefinition passive;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final triggerLabel = switch (passive.trigger) {
      PassiveTrigger.onTurnStart => l.triggerOnTurnStart,
      PassiveTrigger.onAttack => l.triggerOnAttack,
      PassiveTrigger.onDamaged => l.triggerOnDamaged,
      PassiveTrigger.battleStart => l.triggerBattleStart,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_mosaic, color: Colors.teal[300], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  passive.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  triggerLabel,
                  style: TextStyle(fontSize: 11, color: Colors.teal[200]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            passive.description,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (passive.atkBoost > 0)
                _SkillTag(label: 'ATK +${(passive.atkBoost * 100).round()}%', color: Colors.red),
              if (passive.defBoost > 0)
                _SkillTag(label: 'DEF +${(passive.defBoost * 100).round()}%', color: Colors.blue),
              if (passive.hpRegenPercent > 0)
                _SkillTag(label: l.tagHpRegen((passive.hpRegenPercent * 100).round()), color: Colors.green),
              if (passive.counterChance > 0)
                _SkillTag(label: l.tagCounter((passive.counterChance * 100).round()), color: Colors.orange),
              if (passive.critBoost > 0)
                _SkillTag(label: l.tagCrit((passive.critBoost * 100).round()), color: Colors.amber),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Ultimate skill card
// =============================================================================

class _UltimateCard extends StatelessWidget {
  const _UltimateCard({required this.ultimate, required this.l});
  final UltimateDefinition ultimate;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.amber[300], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ultimate.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.ultCharge(ultimate.maxCharge),
                  style: TextStyle(fontSize: 11, color: Colors.amber[200]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ultimate.description,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (ultimate.damageMultiplier > 0)
                _SkillTag(
                  label: '${ultimate.damageMultiplier}x ${ultimate.damageTarget == SkillTargetType.allEnemies ? l.tagAll : l.tagSingle}',
                  color: Colors.red,
                ),
              if (ultimate.healPercent > 0)
                _SkillTag(
                  label: '${l.tagHeal((ultimate.healPercent * 100).round())}${ultimate.isTeamHeal ? " ${l.tagAll}" : ""}',
                  color: Colors.green,
                ),
              if (ultimate.stunChance > 0)
                _SkillTag(label: l.tagStun((ultimate.stunChance * 100).round()), color: Colors.amber),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Evolution tree
// =============================================================================

class _EvolutionTree extends StatelessWidget {
  const _EvolutionTree({required this.monster, required this.l});
  final MonsterModel monster;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final stages = [
      (label: l.evoStageBase, multiplier: '1.00x', stage: 0),
      (label: l.evoStageFirst, multiplier: '1.25x', stage: 1),
      (label: l.evoStageFinal, multiplier: '1.60x', stage: 2),
    ];
    final maxStage = GameConfig.maxEvolutionStage;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (int i = 0; i <= maxStage; i++) ...[
            Expanded(
              child: _EvoStageNode(
                label: stages[i].label,
                multiplier: stages[i].multiplier,
                isCurrent: monster.evolutionStage == i,
                isReached: monster.evolutionStage >= i,
                currentLabel: l.evoCurrentMark,
              ),
            ),
            if (i < maxStage)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: monster.evolutionStage > i
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EvoStageNode extends StatelessWidget {
  const _EvoStageNode({
    required this.label,
    required this.multiplier,
    required this.isCurrent,
    required this.isReached,
    required this.currentLabel,
  });
  final String label;
  final String multiplier;
  final bool isCurrent;
  final bool isReached;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrent
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 22,
            color: isReached ? AppColors.primary : AppColors.textTertiary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isReached ? AppColors.textPrimary : AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            multiplier,
            style: TextStyle(
              fontSize: 10,
              color: isReached ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                currentLabel,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Element matchup table
// =============================================================================

class _ElementMatchupTable extends StatelessWidget {
  const _ElementMatchupTable({required this.element});
  final MonsterElement element;

  @override
  Widget build(BuildContext context) {
    final allElements = MonsterElement.values;
    final strong = <MonsterElement>[];
    final weak = <MonsterElement>[];

    for (final target in allElements) {
      final adv = element.getAdvantage(target);
      if (adv > 1.0) strong.add(target);
      if (adv < 1.0) weak.add(target);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // This monster's element header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: element.color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(element.emoji, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                element.koreanName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Strong against
          if (strong.isNotEmpty) ...[
            _MatchupRow(
              label: '🔼',
              elements: strong,
              color: Colors.green,
              multiplier: '1.3x',
            ),
            const SizedBox(height: 8),
          ],
          // Weak against
          if (weak.isNotEmpty)
            _MatchupRow(
              label: '🔽',
              elements: weak,
              color: Colors.red,
              multiplier: '0.7x',
            ),
          if (strong.isEmpty && weak.isEmpty)
            Text(
              '-',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _MatchupRow extends StatelessWidget {
  const _MatchupRow({
    required this.label,
    required this.elements,
    required this.color,
    required this.multiplier,
  });
  final String label;
  final List<MonsterElement> elements;
  final Color color;
  final String multiplier;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            multiplier,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        ...elements.map((e) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: e.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: e.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      e.koreanName,
                      style: TextStyle(
                        fontSize: 11,
                        color: e.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// =============================================================================
// Skin Section
// =============================================================================

class _SkinSection extends ConsumerWidget {
  const _SkinSection({required this.monster, required this.l});
  final MonsterModel monster;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skinState = ref.watch(skinProvider);
    final equippedSkin = monster.equippedSkinId != null
        ? SkinDatabase.findById(monster.equippedSkinId!)
        : null;
    final applicableSkins = SkinDatabase.applicableTo(
      element: monster.element,
      templateId: monster.templateId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: l.skinTitle),
        const SizedBox(height: 8),

        // Currently equipped
        if (equippedSkin != null)
          _EquippedSkinCard(
            skin: equippedSkin,
            onUnequip: () async {
              await ref.read(skinProvider.notifier).unequipSkin(monster.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.skinUnequipSuccess)),
                );
              }
            },
            l: l,
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l.skinNone,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),

        const SizedBox(height: 8),

        // Available skins grid
        ...applicableSkins.map(
          (skin) => _SkinCard(
            skin: skin,
            isUnlocked: skinState.isUnlocked(skin.id),
            isEquipped: monster.equippedSkinId == skin.id,
            monster: monster,
            l: l,
          ),
        ),
      ],
    );
  }
}

class _EquippedSkinCard extends StatelessWidget {
  const _EquippedSkinCard({
    required this.skin,
    required this.onUnequip,
    required this.l,
  });
  final SkinDefinition skin;
  final VoidCallback onUnequip;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (skin.overrideColor ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (skin.overrideColor ?? AppColors.primary).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (skin.overrideEmoji != null)
            Text(skin.overrideEmoji!, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      skin.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l.skinEquipped,
                        style: const TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  skin.description,
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUnequip,
            child: Text(l.skinUnequip, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SkinCard extends ConsumerWidget {
  const _SkinCard({
    required this.skin,
    required this.isUnlocked,
    required this.isEquipped,
    required this.monster,
    required this.l,
  });
  final SkinDefinition skin;
  final bool isUnlocked;
  final bool isEquipped;
  final MonsterModel monster;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rarityColor = _rarityColor(skin.rarity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isEquipped
            ? rarityColor.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEquipped
              ? rarityColor.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Skin preview
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (skin.overrideColor ?? AppColors.border).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                skin.overrideEmoji ?? '?',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      skin.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '★' * skin.rarity,
                      style: TextStyle(fontSize: 10, color: rarityColor),
                    ),
                  ],
                ),
                Text(
                  _targetLabel(skin),
                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          // Action button
          if (isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l.skinEquipped,
                style: const TextStyle(fontSize: 11, color: Colors.green),
              ),
            )
          else if (isUnlocked)
            _ActionButton(
              label: l.skinEquip,
              color: AppColors.primary,
              onTap: () async {
                final ok = await ref.read(skinProvider.notifier).equipSkin(
                      monsterId: monster.id,
                      skinId: skin.id,
                    );
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.skinEquipSuccess)),
                  );
                }
              },
            )
          else
            _ActionButton(
              label: l.skinCost(skin.shardCost),
              color: Colors.teal,
              onTap: () async {
                final ok = await ref.read(skinProvider.notifier).unlockSkin(skin.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? l.skinUnlockSuccess : l.skinInsufficientShards,
                      ),
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  String _targetLabel(SkinDefinition s) {
    if (s.targetTemplateId != null) return l.skinExclusive;
    if (s.targetElement != null) {
      final elem = MonsterElement.fromName(s.targetElement!);
      return l.skinElementOnly(elem?.koreanName ?? s.targetElement!);
    }
    return l.skinUniversal;
  }

  Color _rarityColor(int rarity) {
    switch (rarity) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.green;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
