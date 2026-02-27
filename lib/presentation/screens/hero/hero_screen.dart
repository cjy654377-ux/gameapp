import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/equippable_skill_model.dart';
import 'package:gameapp/data/models/mount_model.dart';
import 'package:gameapp/data/models/player_model.dart';
import 'package:gameapp/presentation/providers/currency_provider.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';

// =============================================================================
// HeroScreen — root
// =============================================================================

class HeroScreen extends ConsumerWidget {
  const HeroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider).player;

    if (player == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const CurrencyBar(),
            // Header
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Icon(Icons.person, color: AppColors.primaryLight, size: 24),
                  const SizedBox(width: 8),
                  const Text('영웅',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lv.${player.playerLevel}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            Container(
              color: AppColors.surface,
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: TextStyle(fontSize: 13),
                tabs: [
                  Tab(text: '장비'),
                  Tab(text: '인벤토리'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _EquipmentTab(),
                  _InventoryTab(),
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
// Equipment Tab
// =============================================================================

class _EquipmentTab extends ConsumerWidget {
  const _EquipmentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider).player;
    if (player == null) return const SizedBox.shrink();

    final equippedSkill = player.equippedSkillId != null
        ? LocalStorage.instance.getSkill(player.equippedSkillId!)
        : null;
    final equippedMount = player.equippedMountId != null
        ? LocalStorage.instance.getMount(player.equippedMountId!)
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroAvatarCard(player: player),
        const SizedBox(height: 16),
        _HeroStatsSection(player: player, equippedMount: equippedMount),
        const SizedBox(height: 16),
        _EquipmentSlot(
          label: '스킬',
          icon: Icons.auto_awesome,
          slotColor: Colors.purple,
          equippedWidget: equippedSkill != null
              ? _SkillCard(skill: equippedSkill)
              : null,
          emptyText: '장착된 스킬 없음',
          onTap: () => _showSkillPicker(context, ref, player),
          onUnequip: equippedSkill != null
              ? () => _unequip(ref, skill: true)
              : null,
        ),
        const SizedBox(height: 12),
        _EquipmentSlot(
          label: '탈것',
          icon: Icons.pets,
          slotColor: Colors.orange,
          equippedWidget: equippedMount != null
              ? _MountCard(mount: equippedMount)
              : null,
          emptyText: '장착된 탈것 없음',
          onTap: () => _showMountPicker(context, ref, player),
          onUnequip: equippedMount != null
              ? () => _unequip(ref, mount: true)
              : null,
        ),
      ],
    );
  }

  Future<void> _unequip(WidgetRef ref, {bool skill = false, bool mount = false}) async {
    await ref.read(playerProvider.notifier).updatePlayer(
          (p) => p.copyWith(
            clearEquippedSkill: skill,
            clearEquippedMount: mount,
          ),
        );
  }

  void _showSkillPicker(BuildContext context, WidgetRef ref, PlayerModel player) {
    final skills = LocalStorage.instance.getAllSkills();
    if (skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보유한 스킬이 없습니다. 소환에서 획득하세요!')),
      );
      return;
    }
    skills.sort((a, b) {
      final rc = b.rarity.compareTo(a.rarity);
      return rc != 0 ? rc : b.level.compareTo(a.level);
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SkillPickerSheet(
        skills: skills,
        currentSkillId: player.equippedSkillId,
        onSelect: (id) async {
          await ref.read(playerProvider.notifier).updatePlayer(
                (p) => p.copyWith(equippedSkillId: id),
              );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showMountPicker(BuildContext context, WidgetRef ref, PlayerModel player) {
    final mounts = LocalStorage.instance.getAllMounts();
    if (mounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보유한 탈것이 없습니다. 소환에서 획득하세요!')),
      );
      return;
    }
    mounts.sort((a, b) {
      final rc = b.rarity.compareTo(a.rarity);
      return rc != 0 ? rc : b.level.compareTo(a.level);
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MountPickerSheet(
        mounts: mounts,
        currentMountId: player.equippedMountId,
        onSelect: (id) async {
          await ref.read(playerProvider.notifier).updatePlayer(
                (p) => p.copyWith(equippedMountId: id),
              );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

// =============================================================================
// Inventory Tab
// =============================================================================

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch player to rebuild when equipment changes
    ref.watch(playerProvider);

    final skills = LocalStorage.instance.getAllSkills();
    final mounts = LocalStorage.instance.getAllMounts();

    skills.sort((a, b) {
      final rc = b.rarity.compareTo(a.rarity);
      return rc != 0 ? rc : b.level.compareTo(a.level);
    });
    mounts.sort((a, b) {
      final rc = b.rarity.compareTo(a.rarity);
      return rc != 0 ? rc : b.level.compareTo(a.level);
    });

    if (skills.isEmpty && mounts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, color: AppColors.textTertiary, size: 48),
            SizedBox(height: 12),
            Text('보유한 장비가 없습니다',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary)),
            SizedBox(height: 4),
            Text('소환에서 스킬과 탈것을 획득하세요!',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        _InventorySummary(skillCount: skills.length, mountCount: mounts.length),
        const SizedBox(height: 16),

        // Skills section
        if (skills.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.auto_awesome,
            color: Colors.purple,
            title: '스킬',
            count: skills.length,
          ),
          const SizedBox(height: 8),
          ...skills.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InventorySkillCard(skill: s),
              )),
          const SizedBox(height: 16),
        ],

        // Mounts section
        if (mounts.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.pets,
            color: Colors.orange,
            title: '탈것',
            count: mounts.length,
          ),
          const SizedBox(height: 8),
          ...mounts.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _InventoryMountCard(mount: m),
              )),
        ],
      ],
    );
  }
}

// =============================================================================
// Inventory Summary
// =============================================================================

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.skillCount, required this.mountCount});
  final int skillCount;
  final int mountCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryItem(icon: Icons.auto_awesome, color: Colors.purple, label: '스킬', count: skillCount),
          Container(width: 1, height: 30, color: AppColors.border),
          _SummaryItem(icon: Icons.pets, color: Colors.orange, label: '탈것', count: mountCount),
          Container(width: 1, height: 30, color: AppColors.border),
          _SummaryItem(icon: Icons.inventory_2, color: AppColors.info, label: '합계', count: skillCount + mountCount),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.icon, required this.color, required this.label, required this.count});
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ],
    );
  }
}

// =============================================================================
// Section Header
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.color, required this.title, required this.count});
  final IconData icon;
  final Color color;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Text('($count)', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      ],
    );
  }
}

// =============================================================================
// Inventory Skill Card
// =============================================================================

class _InventorySkillCard extends ConsumerWidget {
  const _InventorySkillCard({required this.skill});
  final EquippableSkillModel skill;

  int _cost() => skill.level * 200 * skill.rarity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rc = _rarityColor(skill.rarity);
    final player = ref.watch(playerProvider).player;
    final isEquipped = player?.equippedSkillId == skill.id;
    final cost = _cost();
    final gold = ref.watch(currencyProvider).gold;
    final canUpgrade = skill.canLevelUp && gold >= cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEquipped ? rc.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isEquipped ? rc : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: rc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome, color: rc, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(skill.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rc)),
                      const SizedBox(width: 6),
                      Text('Lv.${skill.level}/${skill.maxLevel}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (isEquipped) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('장착중', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      '${_skillTypeLabel(skill.skillType)} · ${skill.effectiveValue.toStringAsFixed(1)} · ${'★' * skill.rarity}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                    if (skill.description.isNotEmpty)
                      Text(skill.description, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          if (skill.canLevelUp) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text('다음: ${(skill.value * (1.0 + skill.level * 0.1)).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                const SizedBox(width: 12),
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: canUpgrade ? () => _levelUp(context, ref) : null,
                    icon: const Icon(Icons.arrow_upward, size: 14),
                    label: Text('$cost G', style: const TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUpgrade ? AppColors.success : AppColors.disabled,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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

  Future<void> _levelUp(BuildContext context, WidgetRef ref) async {
    final cost = _cost();
    if (!await ref.read(currencyProvider.notifier).spendGold(cost)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('골드가 부족합니다')));
      return;
    }
    final upgraded = skill.copyWith(level: skill.level + 1);
    await LocalStorage.instance.saveSkill(upgraded);
    ref.read(playerProvider.notifier).forceUpdate(ref.read(playerProvider).player!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${skill.name} Lv.${upgraded.level} 강화 완료!')));
  }
}

// =============================================================================
// Inventory Mount Card
// =============================================================================

class _InventoryMountCard extends ConsumerWidget {
  const _InventoryMountCard({required this.mount});
  final MountModel mount;

  int _cost() => mount.level * 150 * mount.rarity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rc = _rarityColor(mount.rarity);
    final player = ref.watch(playerProvider).player;
    final isEquipped = player?.equippedMountId == mount.id;
    final cost = _cost();
    final gold = ref.watch(currencyProvider).gold;
    final canUpgrade = mount.level < mount.maxLevel && gold >= cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEquipped ? rc.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isEquipped ? rc : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: rc.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pets, color: rc, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(mount.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rc)),
                      const SizedBox(width: 6),
                      Text('Lv.${mount.level}/${mount.maxLevel}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (isEquipped) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('장착중', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      '${mount.statType.toUpperCase()} +${mount.effectiveStatValue.toStringAsFixed(1)} · ${'★' * mount.rarity}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                    if (mount.description.isNotEmpty)
                      Text(mount.description, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          if (mount.level < mount.maxLevel) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text('다음: +${(mount.statValue * (1.0 + mount.level * 0.05)).toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                const SizedBox(width: 12),
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: canUpgrade ? () => _levelUp(context, ref) : null,
                    icon: const Icon(Icons.arrow_upward, size: 14),
                    label: Text('$cost G', style: const TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canUpgrade ? AppColors.success : AppColors.disabled,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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

  Future<void> _levelUp(BuildContext context, WidgetRef ref) async {
    final cost = _cost();
    if (!await ref.read(currencyProvider.notifier).spendGold(cost)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('골드가 부족합니다')));
      return;
    }
    final upgraded = mount.copyWith(level: mount.level + 1);
    await LocalStorage.instance.saveMount(upgraded);
    ref.read(playerProvider.notifier).forceUpdate(ref.read(playerProvider).player!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${mount.name} Lv.${upgraded.level} 강화 완료!')));
  }
}

// =============================================================================
// Hero Avatar Card
// =============================================================================

class _HeroAvatarCard extends StatelessWidget {
  const _HeroAvatarCard({required this.player});
  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 2),
            ),
            child: const Icon(Icons.person, color: AppColors.primaryLight, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Lv.${player.playerLevel} 영웅', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                _ExpBar(current: player.playerExp, max: player.expToNextLevel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.current, required this.max});
  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('EXP', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            Text('$current / $max', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.experience),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Hero Stats Section
// =============================================================================

class _HeroStatsSection extends StatelessWidget {
  const _HeroStatsSection({required this.player, this.equippedMount});
  final PlayerModel player;
  final MountModel? equippedMount;

  @override
  Widget build(BuildContext context) {
    double atkB = 0, defB = 0, hpB = 0, spdB = 0;
    if (equippedMount != null) {
      final v = equippedMount!.effectiveStatValue;
      switch (equippedMount!.statType) {
        case 'atk': atkB = v;
        case 'def': defB = v;
        case 'hp':  hpB = v;
        case 'spd': spdB = v;
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('전투 능력치', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _StatRow(label: 'ATK', icon: Icons.flash_on, color: AppColors.error, baseValue: player.heroAtk, bonus: atkB),
          const SizedBox(height: 8),
          _StatRow(label: 'DEF', icon: Icons.shield, color: AppColors.info, baseValue: player.heroDef, bonus: defB),
          const SizedBox(height: 8),
          _StatRow(label: 'HP', icon: Icons.favorite, color: AppColors.success, baseValue: player.heroHp, bonus: hpB),
          const SizedBox(height: 8),
          _StatRow(label: 'SPD', icon: Icons.speed, color: AppColors.warning, baseValue: player.heroSpd, bonus: spdB),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.icon, required this.color, required this.baseValue, this.bonus = 0});
  final String label;
  final IconData icon;
  final Color color;
  final double baseValue;
  final double bonus;

  @override
  Widget build(BuildContext context) {
    final total = baseValue + bonus;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        const SizedBox(width: 8),
        Text(total.toStringAsFixed(1), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        if (bonus > 0) ...[
          const SizedBox(width: 6),
          Text('(+${bonus.toStringAsFixed(1)})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ],
    );
  }
}

// =============================================================================
// Equipment Slot
// =============================================================================

class _EquipmentSlot extends StatelessWidget {
  const _EquipmentSlot({
    required this.label,
    required this.icon,
    required this.slotColor,
    this.equippedWidget,
    required this.emptyText,
    required this.onTap,
    this.onUnequip,
  });
  final String label;
  final IconData icon;
  final Color slotColor;
  final Widget? equippedWidget;
  final String emptyText;
  final VoidCallback onTap;
  final VoidCallback? onUnequip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: slotColor, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Spacer(),
            if (onUnequip != null)
              TextButton(
                onPressed: onUnequip,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('해제', style: TextStyle(fontSize: 12)),
              ),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: equippedWidget ??
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: slotColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    Icon(Icons.add_circle_outline, color: slotColor.withValues(alpha: 0.5), size: 32),
                    const SizedBox(height: 4),
                    Text(emptyText, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text('탭하여 장착', style: TextStyle(fontSize: 11, color: slotColor.withValues(alpha: 0.7))),
                  ]),
                ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Skill Card (equipped view)
// =============================================================================

class _SkillCard extends ConsumerWidget {
  const _SkillCard({required this.skill});
  final EquippableSkillModel skill;

  int _cost() => skill.level * 200 * skill.rarity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rc = _rarityColor(skill.rarity);
    final cost = _cost();
    final gold = ref.watch(currencyProvider).gold;
    final canUpgrade = skill.canLevelUp && gold >= cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rc.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: rc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.auto_awesome, color: rc, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(skill.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rc)),
              const SizedBox(width: 6),
              Text('Lv.${skill.level}/${skill.maxLevel}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 2),
            Text('${_skillTypeLabel(skill.skillType)} · ${skill.effectiveValue.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ])),
          Text('★' * skill.rarity, style: TextStyle(fontSize: 12, color: rc)),
        ]),
        if (skill.canLevelUp) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            Text('다음: ${(skill.value * (1.0 + skill.level * 0.1)).toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            const SizedBox(width: 12),
            SizedBox(
              height: 28,
              child: ElevatedButton.icon(
                onPressed: canUpgrade ? () => _levelUp(context, ref) : null,
                icon: const Icon(Icons.arrow_upward, size: 14),
                label: Text('$cost G', style: const TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUpgrade ? AppColors.success : AppColors.disabled,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Future<void> _levelUp(BuildContext context, WidgetRef ref) async {
    final cost = _cost();
    if (!await ref.read(currencyProvider.notifier).spendGold(cost)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('골드가 부족합니다')));
      return;
    }
    final upgraded = skill.copyWith(level: skill.level + 1);
    await LocalStorage.instance.saveSkill(upgraded);
    ref.read(playerProvider.notifier).forceUpdate(ref.read(playerProvider).player!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${skill.name} Lv.${upgraded.level} 강화 완료!')));
  }
}

// =============================================================================
// Mount Card (equipped view)
// =============================================================================

class _MountCard extends ConsumerWidget {
  const _MountCard({required this.mount});
  final MountModel mount;

  int _cost() => mount.level * 150 * mount.rarity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rc = _rarityColor(mount.rarity);
    final cost = _cost();
    final gold = ref.watch(currencyProvider).gold;
    final canUpgrade = mount.level < mount.maxLevel && gold >= cost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rc.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: rc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.pets, color: rc, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(mount.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rc)),
              const SizedBox(width: 6),
              Text('Lv.${mount.level}/${mount.maxLevel}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 2),
            Text('${mount.statType.toUpperCase()} +${mount.effectiveStatValue.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ])),
          Text('★' * mount.rarity, style: TextStyle(fontSize: 12, color: rc)),
        ]),
        if (mount.level < mount.maxLevel) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Spacer(),
            Text('다음: +${(mount.statValue * (1.0 + mount.level * 0.05)).toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            const SizedBox(width: 12),
            SizedBox(
              height: 28,
              child: ElevatedButton.icon(
                onPressed: canUpgrade ? () => _levelUp(context, ref) : null,
                icon: const Icon(Icons.arrow_upward, size: 14),
                label: Text('$cost G', style: const TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUpgrade ? AppColors.success : AppColors.disabled,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Future<void> _levelUp(BuildContext context, WidgetRef ref) async {
    final cost = _cost();
    if (!await ref.read(currencyProvider.notifier).spendGold(cost)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('골드가 부족합니다')));
      return;
    }
    final upgraded = mount.copyWith(level: mount.level + 1);
    await LocalStorage.instance.saveMount(upgraded);
    ref.read(playerProvider.notifier).forceUpdate(ref.read(playerProvider).player!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${mount.name} Lv.${upgraded.level} 강화 완료!')));
  }
}

// =============================================================================
// Skill Picker Bottom Sheet
// =============================================================================

class _SkillPickerSheet extends StatelessWidget {
  const _SkillPickerSheet({required this.skills, this.currentSkillId, required this.onSelect});
  final List<EquippableSkillModel> skills;
  final String? currentSkillId;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.85, minChildSize: 0.3, expand: false,
      builder: (_, controller) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('스킬 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('보유: ${skills.length}개', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: skills.length,
            itemBuilder: (_, i) {
              final s = skills[i];
              final eq = s.id == currentSkillId;
              final rc = _rarityColor(s.rarity);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: eq ? rc.withValues(alpha: 0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: eq ? rc : AppColors.border, width: eq ? 2 : 1),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: rc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.auto_awesome, color: rc, size: 20),
                  ),
                  title: Row(children: [
                    Text(s.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rc)),
                    const SizedBox(width: 6),
                    Text('Lv.${s.level}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  subtitle: Text('${_skillTypeLabel(s.skillType)} · ${s.effectiveValue.toStringAsFixed(1)} · ${'★' * s.rarity}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  trailing: eq
                      ? const Icon(Icons.check_circle, color: AppColors.success, size: 24)
                      : const Icon(Icons.radio_button_off, color: AppColors.textTertiary, size: 24),
                  onTap: () => onSelect(s.id),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// Mount Picker Bottom Sheet
// =============================================================================

class _MountPickerSheet extends StatelessWidget {
  const _MountPickerSheet({required this.mounts, this.currentMountId, required this.onSelect});
  final List<MountModel> mounts;
  final String? currentMountId;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.85, minChildSize: 0.3, expand: false,
      builder: (_, controller) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('탈것 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('보유: ${mounts.length}개', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: mounts.length,
            itemBuilder: (_, i) {
              final m = mounts[i];
              final eq = m.id == currentMountId;
              final rc = _rarityColor(m.rarity);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: eq ? rc.withValues(alpha: 0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: eq ? rc : AppColors.border, width: eq ? 2 : 1),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: rc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.pets, color: rc, size: 20),
                  ),
                  title: Row(children: [
                    Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rc)),
                    const SizedBox(width: 6),
                    Text('Lv.${m.level}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  subtitle: Text('${m.statType.toUpperCase()} +${m.effectiveStatValue.toStringAsFixed(1)} · ${'★' * m.rarity}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  trailing: eq
                      ? const Icon(Icons.check_circle, color: AppColors.success, size: 24)
                      : const Icon(Icons.radio_button_off, color: AppColors.textTertiary, size: 24),
                  onTap: () => onSelect(m.id),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

Color _rarityColor(int rarity) {
  switch (rarity) {
    case 1: return AppColors.rarityNormal;
    case 2: return AppColors.rarityAdvanced;
    case 3: return AppColors.rarityRare;
    case 4: return AppColors.rarityEpic;
    case 5: return AppColors.rarityLegendary;
    default: return AppColors.rarityNormal;
  }
}

String _skillTypeLabel(String type) {
  switch (type) {
    case 'damage': return '피해';
    case 'def_buff': return '방어 버프';
    case 'hp_regen': return 'HP 회복';
    case 'atk_buff': return '공격 버프';
    case 'speed_buff': return '속도 버프';
    case 'crit_boost': return '치명타 강화';
    default: return type;
  }
}
