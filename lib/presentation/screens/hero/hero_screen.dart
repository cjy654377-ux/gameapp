import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/data/datasources/local_storage.dart';
import 'package:gameapp/data/models/equippable_skill_model.dart';
import 'package:gameapp/data/models/mount_model.dart';
import 'package:gameapp/data/models/player_model.dart';
import 'package:gameapp/l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context)!;
    final player = ref.watch(playerProvider).player;

    if (player == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
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
                  Text(l.heroHeader,
                      style: const TextStyle(
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
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: [
                  Tab(text: l.heroTabEquipment),
                  Tab(text: l.heroTabInventory),
                  Tab(text: l.heroTabFusion),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _EquipmentTab(),
                  _InventoryTab(),
                  _FusionTab(),
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
    final l = AppLocalizations.of(context)!;
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
          label: l.heroSkillLabel,
          icon: Icons.auto_awesome,
          slotColor: Colors.purple,
          equippedWidget: equippedSkill != null
              ? _SkillCard(skill: equippedSkill)
              : null,
          emptyText: l.heroNoSkill,
          onTap: () => _showSkillPicker(context, ref, player),
          onUnequip: equippedSkill != null
              ? () => _unequip(ref, skill: true)
              : null,
        ),
        const SizedBox(height: 12),
        _EquipmentSlot(
          label: l.heroMountLabel,
          icon: Icons.pets,
          slotColor: Colors.orange,
          equippedWidget: equippedMount != null
              ? _MountCard(mount: equippedMount)
              : null,
          emptyText: l.heroNoMount,
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
    final l = AppLocalizations.of(context)!;
    final skills = LocalStorage.instance.getAllSkills();
    if (skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.heroNoSkillOwned)),
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
    final l = AppLocalizations.of(context)!;
    final mounts = LocalStorage.instance.getAllMounts();
    if (mounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.heroNoMountOwned)),
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
    final l = AppLocalizations.of(context)!;
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 12),
            Text(l.heroNoEquipment,
                style: const TextStyle(fontSize: 14, color: AppColors.textTertiary)),
            const SizedBox(height: 4),
            Text(l.heroGetFromSummon,
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
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
            title: l.heroSkillLabel,
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
            title: l.heroMountLabel,
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
    final l = AppLocalizations.of(context)!;
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
          _SummaryItem(icon: Icons.auto_awesome, color: Colors.purple, label: l.heroSkillLabel, count: skillCount),
          Container(width: 1, height: 30, color: AppColors.border),
          _SummaryItem(icon: Icons.pets, color: Colors.orange, label: l.heroMountLabel, count: mountCount),
          Container(width: 1, height: 30, color: AppColors.border),
          _SummaryItem(icon: Icons.inventory_2, color: AppColors.info, label: l.heroTotal, count: skillCount + mountCount),
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
    final l = AppLocalizations.of(context)!;
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
                          child: Text(l.heroEquipped, style: const TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      '${_skillTypeLabel(context, skill.skillType)} · ${skill.effectiveValue.toStringAsFixed(1)} · ${'★' * skill.rarity}',
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
    final l = AppLocalizations.of(context)!;
    final cost = _cost();
    if (!await ref.read(currencyProvider.notifier).spendGold(cost)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.heroGoldInsufficient)));
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
    final l = AppLocalizations.of(context)!;
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
                          child: Text(l.heroEquipped, style: const TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold)),
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
    final l = AppLocalizations.of(context)!;
    final cost = _cost();
    if (!await ref.read(currencyProvider.notifier).spendGold(cost)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.heroGoldInsufficient)));
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

class _HeroStatsSection extends ConsumerWidget {
  const _HeroStatsSection({required this.player, this.equippedMount});
  final PlayerModel player;
  final MountModel? equippedMount;

  // Initial base values & training increments
  static const _initAtk = 15.0, _incrAtk = 1.0;
  static const _initDef = 8.0, _incrDef = 0.5;
  static const _initHp = 150.0, _incrHp = 10.0;
  static const _initSpd = 12.0, _incrSpd = 0.5;

  static int _trainCount(double current, double initial, double incr) =>
      ((current - initial) / incr).round();

  static int _trainCost(int count) => 100 * (count + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
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

    final atkCnt = _trainCount(player.heroBaseAtk, _initAtk, _incrAtk);
    final defCnt = _trainCount(player.heroBaseDef, _initDef, _incrDef);
    final hpCnt = _trainCount(player.heroBaseHp, _initHp, _incrHp);
    final spdCnt = _trainCount(player.heroBaseSpd, _initSpd, _incrSpd);
    final gold = ref.watch(currencyProvider).gold;

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
          Row(
            children: [
              Text(l.heroBattleStats, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Spacer(),
              const Icon(Icons.fitness_center, color: AppColors.warning, size: 14),
              const SizedBox(width: 4),
              Text(l.heroTraining, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 12),
          _TrainableStatRow(
            label: 'ATK', icon: Icons.flash_on, color: AppColors.error,
            baseValue: player.heroAtk, bonus: atkB,
            trainCount: atkCnt, cost: _trainCost(atkCnt), gold: gold,
            onTrain: () => _train(ref, 'atk', atkCnt),
            onBulkTrain: () => _trainBulk(ref, 'atk', atkCnt, gold),
          ),
          const SizedBox(height: 8),
          _TrainableStatRow(
            label: 'DEF', icon: Icons.shield, color: AppColors.info,
            baseValue: player.heroDef, bonus: defB,
            trainCount: defCnt, cost: _trainCost(defCnt), gold: gold,
            onTrain: () => _train(ref, 'def', defCnt),
            onBulkTrain: () => _trainBulk(ref, 'def', defCnt, gold),
          ),
          const SizedBox(height: 8),
          _TrainableStatRow(
            label: 'HP', icon: Icons.favorite, color: AppColors.success,
            baseValue: player.heroHp, bonus: hpB,
            trainCount: hpCnt, cost: _trainCost(hpCnt), gold: gold,
            onTrain: () => _train(ref, 'hp', hpCnt),
            onBulkTrain: () => _trainBulk(ref, 'hp', hpCnt, gold),
          ),
          const SizedBox(height: 8),
          _TrainableStatRow(
            label: 'SPD', icon: Icons.speed, color: AppColors.warning,
            baseValue: player.heroSpd, bonus: spdB,
            trainCount: spdCnt, cost: _trainCost(spdCnt), gold: gold,
            onTrain: () => _train(ref, 'spd', spdCnt),
            onBulkTrain: () => _trainBulk(ref, 'spd', spdCnt, gold),
          ),
        ],
      ),
    );
  }

  Future<void> _train(WidgetRef ref, String stat, int currentCount) async {
    final cost = _trainCost(currentCount);
    final ok = await ref.read(currencyProvider.notifier).spendGold(cost);
    if (!ok) return;
    await ref.read(playerProvider.notifier).updatePlayer((p) {
      switch (stat) {
        case 'atk': return p.copyWith(heroBaseAtk: p.heroBaseAtk + _incrAtk);
        case 'def': return p.copyWith(heroBaseDef: p.heroBaseDef + _incrDef);
        case 'hp':  return p.copyWith(heroBaseHp: p.heroBaseHp + _incrHp);
        case 'spd': return p.copyWith(heroBaseSpd: p.heroBaseSpd + _incrSpd);
        default: return p;
      }
    });
  }

  /// Train up to 10 times at once (or until gold runs out).
  Future<void> _trainBulk(WidgetRef ref, String stat, int startCount, int availableGold) async {
    int count = startCount;
    int remaining = availableGold;
    int trained = 0;
    final incr = _incrForStat(stat);
    for (int i = 0; i < 10; i++) {
      final cost = _trainCost(count);
      if (remaining < cost) break;
      remaining -= cost;
      count++;
      trained++;
    }
    if (trained == 0) return;
    // Calculate total cost
    int totalCost = 0;
    for (int i = 0; i < trained; i++) {
      totalCost += _trainCost(startCount + i);
    }
    final ok = await ref.read(currencyProvider.notifier).spendGold(totalCost);
    if (!ok) return;
    final totalIncr = incr * trained;
    await ref.read(playerProvider.notifier).updatePlayer((p) {
      switch (stat) {
        case 'atk': return p.copyWith(heroBaseAtk: p.heroBaseAtk + totalIncr);
        case 'def': return p.copyWith(heroBaseDef: p.heroBaseDef + totalIncr);
        case 'hp':  return p.copyWith(heroBaseHp: p.heroBaseHp + totalIncr);
        case 'spd': return p.copyWith(heroBaseSpd: p.heroBaseSpd + totalIncr);
        default: return p;
      }
    });
  }

  static double _incrForStat(String stat) {
    switch (stat) {
      case 'atk': return _incrAtk;
      case 'def': return _incrDef;
      case 'hp':  return _incrHp;
      case 'spd': return _incrSpd;
      default: return 0;
    }
  }
}

class _TrainableStatRow extends StatelessWidget {
  const _TrainableStatRow({
    required this.label, required this.icon, required this.color,
    required this.baseValue, this.bonus = 0,
    required this.trainCount, required this.cost, required this.gold,
    required this.onTrain, this.onBulkTrain,
  });
  final String label;
  final IconData icon;
  final Color color;
  final double baseValue;
  final double bonus;
  final int trainCount;
  final int cost;
  final int gold;
  final VoidCallback onTrain;
  final VoidCallback? onBulkTrain;

  @override
  Widget build(BuildContext context) {
    final total = baseValue + bonus;
    final canAfford = gold >= cost;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
        const SizedBox(width: 4),
        Text(total.toStringAsFixed(1), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        if (bonus > 0) ...[
          const SizedBox(width: 4),
          Text('(+${bonus.toStringAsFixed(1)})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
        if (trainCount > 0) ...[
          const SizedBox(width: 4),
          Text('Lv$trainCount', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
        ],
        const Spacer(),
        GestureDetector(
          onTap: canAfford ? onTrain : null,
          onLongPress: canAfford && onBulkTrain != null ? onBulkTrain : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: canAfford ? color.withValues(alpha: 0.15) : AppColors.disabled.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: canAfford ? color.withValues(alpha: 0.4) : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: canAfford ? color : AppColors.disabledText, size: 14),
                const SizedBox(width: 2),
                Text('$cost', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: canAfford ? color : AppColors.disabledText)),
                const SizedBox(width: 2),
                Icon(Icons.monetization_on, color: canAfford ? AppColors.warning : AppColors.disabledText, size: 12),
              ],
            ),
          ),
        ),
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
    final l = AppLocalizations.of(context)!;
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
                child: Text(l.heroUnequip, style: const TextStyle(fontSize: 12)),
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
                    Text(l.heroTapToEquip, style: TextStyle(fontSize: 11, color: slotColor.withValues(alpha: 0.7))),
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
            Text('${_skillTypeLabel(context, skill.skillType)} · ${skill.effectiveValue.toStringAsFixed(1)}',
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
    final l = AppLocalizations.of(context)!;
    final cost = _cost();
    if (!await ref.read(currencyProvider.notifier).spendGold(cost)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.heroGoldInsufficient)));
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
    final l = AppLocalizations.of(context)!;
    final cost = _cost();
    if (!await ref.read(currencyProvider.notifier).spendGold(cost)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.heroGoldInsufficient)));
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
    final l = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.85, minChildSize: 0.3, expand: false,
      builder: (_, controller) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(l.heroSelectSkill, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(l.heroOwned(skills.length), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
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
                  subtitle: Text('${_skillTypeLabel(context, s.skillType)} · ${s.effectiveValue.toStringAsFixed(1)} · ${'★' * s.rarity}',
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
    final l = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.85, minChildSize: 0.3, expand: false,
      builder: (_, controller) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text(l.heroSelectMount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(l.heroOwned(mounts.length), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
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
// Fusion / Dismantle Tab
// =============================================================================

class _FusionTab extends ConsumerWidget {
  const _FusionTab();

  // Dismantle rewards: gold = rarity * level * 50, shard = rarity
  static int _dismantleGold(int rarity, int level) => rarity * level * 50;
  static int _dismantleShard(int rarity) => rarity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    ref.watch(playerProvider);
    ref.watch(currencyProvider);

    final skills = LocalStorage.instance.getAllSkills();
    final mounts = LocalStorage.instance.getAllMounts();
    final player = ref.read(playerProvider).player;

    // Group skills by templateId for fusion
    final skillGroups = <String, List<EquippableSkillModel>>{};
    for (final s in skills) {
      skillGroups.putIfAbsent(s.templateId, () => []).add(s);
    }
    // Group mounts by templateId
    final mountGroups = <String, List<MountModel>>{};
    for (final m in mounts) {
      mountGroups.putIfAbsent(m.templateId, () => []).add(m);
    }

    // Fusible: groups with 2+ items
    final fusibleSkills = skillGroups.entries.where((e) => e.value.length >= 2).toList();
    final fusibleMounts = mountGroups.entries.where((e) => e.value.length >= 2).toList();

    // Dismantleable: all items except currently equipped
    final dismantleSkills = skills.where((s) => s.id != player?.equippedSkillId).toList();
    final dismantleMounts = mounts.where((m) => m.id != player?.equippedMountId).toList();

    if (skills.isEmpty && mounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.build_circle_outlined, color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 12),
            Text(l.heroNoFusionItems, style: const TextStyle(fontSize: 14, color: AppColors.textTertiary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Fusion Section ─────────────────────────
        _SectionHeader(icon: Icons.merge_type, color: Colors.deepPurple, title: l.heroFusion, count: fusibleSkills.length + fusibleMounts.length),
        const SizedBox(height: 4),
        Text(l.heroFusionDesc, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 8),

        if (fusibleSkills.isEmpty && fusibleMounts.isEmpty)
          _emptyCard(l.heroNoFusible)
        else ...[
          for (final entry in fusibleSkills)
            _FusionGroupCard(
              icon: Icons.auto_awesome,
              name: entry.value.first.name,
              rarity: entry.value.first.rarity,
              count: entry.value.length,
              itemType: 'skill',
              onFuse: () => _fuseSkills(context, ref, entry.value),
            ),
          for (final entry in fusibleMounts)
            _FusionGroupCard(
              icon: Icons.pets,
              name: entry.value.first.name,
              rarity: entry.value.first.rarity,
              count: entry.value.length,
              itemType: 'mount',
              onFuse: () => _fuseMounts(context, ref, entry.value),
            ),
        ],

        const SizedBox(height: 20),

        // ── Dismantle Section ─────────────────────────
        _SectionHeader(icon: Icons.recycling, color: Colors.red, title: l.heroDismantle, count: dismantleSkills.length + dismantleMounts.length),
        const SizedBox(height: 4),
        Text(l.heroDismantleDesc, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 8),

        if (dismantleSkills.isEmpty && dismantleMounts.isEmpty)
          _emptyCard(l.heroNoDismantleable)
        else ...[
          for (final s in dismantleSkills)
            _DismantleCard(
              icon: Icons.auto_awesome,
              name: s.name,
              rarity: s.rarity,
              level: s.level,
              goldReward: _dismantleGold(s.rarity, s.level),
              shardReward: _dismantleShard(s.rarity),
              onDismantle: () => _dismantleSkill(context, ref, s),
            ),
          for (final m in dismantleMounts)
            _DismantleCard(
              icon: Icons.pets,
              name: m.name,
              rarity: m.rarity,
              level: m.level,
              goldReward: _dismantleGold(m.rarity, m.level),
              shardReward: _dismantleShard(m.rarity),
              onDismantle: () => _dismantleMount(context, ref, m),
            ),
        ],
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
    );
  }

  Future<void> _fuseSkills(BuildContext context, WidgetRef ref, List<EquippableSkillModel> group) async {
    // Sort by level desc, pick the best one to keep, consume the worst one
    group.sort((a, b) => b.level.compareTo(a.level));
    final keep = group.first;
    final consume = group.last;

    if (!keep.canLevelUp) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.heroMaxLevel)));
      return;
    }

    // Level up the kept skill, delete the consumed one
    final upgraded = keep.copyWith(level: keep.level + 1);
    await LocalStorage.instance.saveSkill(upgraded);
    await LocalStorage.instance.deleteSkill(consume.id);
    ref.read(playerProvider.notifier).forceUpdate(ref.read(playerProvider).player!);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${keep.name} 합성! Lv.${upgraded.level}')),
    );
  }

  Future<void> _fuseMounts(BuildContext context, WidgetRef ref, List<MountModel> group) async {
    group.sort((a, b) => b.level.compareTo(a.level));
    final keep = group.first;
    final consume = group.last;

    if (keep.level >= keep.maxLevel) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.heroMaxLevel)));
      return;
    }

    final upgraded = keep.copyWith(level: keep.level + 1);
    await LocalStorage.instance.saveMount(upgraded);
    await LocalStorage.instance.deleteMount(consume.id);
    ref.read(playerProvider.notifier).forceUpdate(ref.read(playerProvider).player!);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${keep.name} 합성! Lv.${upgraded.level}')),
    );
  }

  Future<void> _dismantleSkill(BuildContext context, WidgetRef ref, EquippableSkillModel skill) async {
    final gold = _dismantleGold(skill.rarity, skill.level);
    final shard = _dismantleShard(skill.rarity);

    await LocalStorage.instance.deleteSkill(skill.id);
    await ref.read(currencyProvider.notifier).addGold(gold);
    await ref.read(currencyProvider.notifier).addShard(shard);
    ref.read(playerProvider.notifier).forceUpdate(ref.read(playerProvider).player!);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${skill.name} 분해! +$gold G, +$shard 샤드')),
    );
  }

  Future<void> _dismantleMount(BuildContext context, WidgetRef ref, MountModel mount) async {
    final gold = _dismantleGold(mount.rarity, mount.level);
    final shard = _dismantleShard(mount.rarity);

    await LocalStorage.instance.deleteMount(mount.id);
    await ref.read(currencyProvider.notifier).addGold(gold);
    await ref.read(currencyProvider.notifier).addShard(shard);
    ref.read(playerProvider.notifier).forceUpdate(ref.read(playerProvider).player!);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${mount.name} 분해! +$gold G, +$shard 샤드')),
    );
  }
}

class _FusionGroupCard extends StatelessWidget {
  const _FusionGroupCard({
    required this.icon,
    required this.name,
    required this.rarity,
    required this.count,
    required this.itemType,
    required this.onFuse,
  });
  final IconData icon;
  final String name;
  final int rarity;
  final int count;
  final String itemType;
  final VoidCallback onFuse;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rc = _rarityColor(rarity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: rc.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: rc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: rc, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: rc)),
                Text('${l.heroOwnedCount(count)} · ${'★' * rarity}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: onFuse,
              icon: const Icon(Icons.merge_type, size: 16),
              label: Text(l.heroFusion, style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DismantleCard extends StatelessWidget {
  const _DismantleCard({
    required this.icon,
    required this.name,
    required this.rarity,
    required this.level,
    required this.goldReward,
    required this.shardReward,
    required this.onDismantle,
  });
  final IconData icon;
  final String name;
  final int rarity;
  final int level;
  final int goldReward;
  final int shardReward;
  final VoidCallback onDismantle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rc = _rarityColor(rarity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: rc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: rc, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: rc)),
                  const SizedBox(width: 4),
                  Text('Lv.$level', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ]),
                Text('+$goldReward G · +$shardReward 샤드', style: const TextStyle(fontSize: 11, color: AppColors.gold)),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: onDismantle,
              icon: const Icon(Icons.recycling, size: 16),
              label: Text(l.heroDismantle, style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
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

String _skillTypeLabel(BuildContext context, String type) {
  final l = AppLocalizations.of(context)!;
  switch (type) {
    case 'damage': return l.heroSkillTypeDamage;
    case 'def_buff': return l.heroSkillTypeDefBuff;
    case 'hp_regen': return 'HP 회복';
    case 'atk_buff': return l.heroSkillTypeAtkBuff;
    case 'speed_buff': return l.heroSkillTypeSpeedBuff;
    case 'crit_boost': return l.heroSkillTypeCritBoost;
    default: return type;
  }
}
