import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/enums/monster_element.dart';
import '../../../core/enums/monster_rarity.dart';
import '../../../data/models/monster_model.dart';
import '../../../data/models/relic_model.dart';
import '../../../data/static/skill_database.dart';
import '../../providers/relic_provider.dart';

/// Full-screen monster detail profile.
class MonsterDetailScreen extends ConsumerWidget {
  const MonsterDetailScreen({super.key, required this.monster});

  final MonsterModel monster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rarity = MonsterRarity.fromRarity(monster.rarity);
    final element =
        MonsterElement.fromName(monster.element) ?? MonsterElement.fire;
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
            backgroundColor: element.color.withValues(alpha: 0.3),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      element.color.withValues(alpha: 0.4),
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
                          color: element.color.withValues(alpha: 0.25),
                          border: Border.all(color: rarity.color, width: 3),
                        ),
                        child: Center(
                          child: Text(element.emoji,
                              style: const TextStyle(fontSize: 40)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        monster.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
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
                        label: '진화 ${monster.evolutionStage}단계',
                        color: rarity.color,
                      ),
                      _InfoChip(
                        icon: monster.isInTeam ? Icons.check_circle : Icons.remove_circle_outline,
                        label: monster.isInTeam ? '팀 배치중' : '미배치',
                        color: monster.isInTeam ? Colors.green : AppColors.textTertiary,
                      ),
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label: '획득 ${_formatDate(monster.acquiredAt)}',
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stat radar chart
                  _SectionTitle(title: '스탯'),
                  const SizedBox(height: 8),
                  _StatRadarChart(monster: monster, relicBonus: relicBonus),
                  const SizedBox(height: 8),

                  // Stat details
                  _StatDetailRow(
                    label: 'HP',
                    base: monster.finalHp,
                    bonus: relicBonus.hp,
                    color: Colors.green,
                  ),
                  _StatDetailRow(
                    label: 'ATK',
                    base: monster.finalAtk,
                    bonus: relicBonus.atk,
                    color: Colors.red,
                  ),
                  _StatDetailRow(
                    label: 'DEF',
                    base: monster.finalDef,
                    bonus: relicBonus.def,
                    color: Colors.blue,
                  ),
                  _StatDetailRow(
                    label: 'SPD',
                    base: monster.finalSpd,
                    bonus: relicBonus.spd,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 20),

                  // EXP progress
                  _SectionTitle(title: '경험치'),
                  const SizedBox(height: 8),
                  _ExpBar(monster: monster),
                  const SizedBox(height: 20),

                  // Affinity
                  _SectionTitle(title: '친밀도'),
                  const SizedBox(height: 8),
                  _AffinityBar(monster: monster),
                  const SizedBox(height: 20),

                  // Skill
                  _SectionTitle(title: '스킬'),
                  const SizedBox(height: 8),
                  if (skill != null)
                    _SkillCard(skill: skill)
                  else
                    Text(
                      '스킬 없음',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  const SizedBox(height: 20),

                  // Equipped relics
                  _SectionTitle(title: '장착 유물 (${equippedRelics.length})'),
                  const SizedBox(height: 8),
                  if (equippedRelics.isEmpty)
                    Text(
                      '장착된 유물이 없습니다',
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

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// =============================================================================
// Stat detail row
// =============================================================================

class _StatDetailRow extends StatelessWidget {
  const _StatDetailRow({
    required this.label,
    required this.base,
    required this.bonus,
    required this.color,
  });
  final String label;
  final double base;
  final double bonus;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = base + bonus;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (total / 2000).clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceVariant,
                color: color.withValues(alpha: 0.7),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              bonus > 0
                  ? '${total.round()} (+${bonus.round()})'
                  : '${total.round()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: bonus > 0 ? Colors.amber : AppColors.textPrimary,
              ),
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

  static const _levelNames = ['없음', 'Lv.1 관심', 'Lv.2 신뢰', 'Lv.3 우정', 'Lv.4 유대', 'Lv.5 최대'];
  static const _thresholds = [10, 30, 60, 100, 150];

  @override
  Widget build(BuildContext context) {
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
              _levelNames[level],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: level > 0 ? Colors.pinkAccent : AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            Text(
              '전투 ${monster.battleCount}회',
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
              ? '보너스: 전 스탯 +${(level * 2)}%'
              : '다음 레벨까지 ${monster.battleCountToNextAffinity}회 (보너스: +${(level * 2)}%)',
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
                  'CD: ${skill.cooldown}턴',
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
                  label: '${skill.damageMultiplier}x ${skill.damageTarget == SkillTargetType.allEnemies ? "전체" : "단일"}',
                  color: Colors.red,
                ),
              if (skill.shieldPercent > 0)
                _SkillTag(
                  label: '방패 ${(skill.shieldPercent * 100).round()}%${skill.isTeamShield ? " 전체" : ""}',
                  color: Colors.blue,
                ),
              if (skill.healPercent > 0)
                _SkillTag(
                  label: '힐 ${(skill.healPercent * 100).round()}%${skill.isTeamHeal ? " 전체" : ""}',
                  color: Colors.green,
                ),
              if (skill.drainPercent > 0)
                _SkillTag(label: '흡수 ${(skill.drainPercent * 100).round()}%', color: Colors.teal),
              if (skill.burnTurns > 0)
                _SkillTag(label: '화상 ${skill.burnTurns}턴', color: Colors.orange),
              if (skill.stunChance > 0)
                _SkillTag(label: '기절 ${(skill.stunChance * 100).round()}%', color: Colors.amber),
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
                  '${_statLabel(relic.statType)} +${relic.statValue.toInt()} | ${relic.rarity}성',
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

  String _statLabel(String stat) {
    switch (stat) {
      case 'atk': return '공격력';
      case 'def': return '방어력';
      case 'hp': return '체력';
      case 'spd': return '속도';
      default: return stat;
    }
  }
}
