import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/domain/services/prestige_service.dart';
import 'package:gameapp/presentation/providers/player_provider.dart';
import 'package:gameapp/presentation/providers/prestige_provider.dart';

class PrestigeScreen extends ConsumerWidget {
  const PrestigeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final player = playerState.player;
    final prestige = ref.watch(prestigeProvider);

    if (player == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('전생')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final canPrestige = PrestigeService.canPrestige(player);
    final diamondReward = PrestigeService.prestigeDiamondReward(player);
    final ticketReward = PrestigeService.prestigeTicketReward(player);
    final currentBonus = player.prestigeBonusPercent;
    final nextBonus = PrestigeService.nextBonusPercent(player);
    final isMaxPrestige =
        player.prestigeLevel >= PrestigeService.maxPrestigeLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('전생 (프레스티지)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Prestige level badge
            _PrestigeBadge(level: player.prestigeLevel),
            const SizedBox(height: 20),

            // Current bonuses
            _InfoCard(
              title: '현재 전생 보너스',
              children: [
                _BonusRow(
                  icon: Icons.monetization_on,
                  label: '골드 획득량',
                  value: '+${currentBonus.toInt()}%',
                  color: Colors.amber,
                ),
                _BonusRow(
                  icon: Icons.auto_awesome,
                  label: '경험치 획득량',
                  value: '+${currentBonus.toInt()}%',
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Requirements
            _InfoCard(
              title: '전생 조건',
              children: [
                _RequirementRow(
                  label: '플레이어 레벨 ${PrestigeService.minLevelToPrestige}+',
                  met: player.playerLevel >= PrestigeService.minLevelToPrestige,
                  current: 'Lv.${player.playerLevel}',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '또는',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                _RequirementRow(
                  label: '${PrestigeService.minAreaToPrestige}지역 이상 클리어',
                  met: _clearedArea(player.maxClearedStageId) >=
                      PrestigeService.minAreaToPrestige,
                  current: player.maxClearedStageId.isEmpty
                      ? '없음'
                      : player.maxClearedStageId,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // What you get / lose
            if (!isMaxPrestige) ...[
              _InfoCard(
                title: '전생 시 얻는 것',
                color: Colors.green.withValues(alpha: 0.1),
                children: [
                  _RewardRow(
                    icon: Icons.diamond,
                    label: '다이아몬드',
                    value: '+$diamondReward',
                    color: Colors.cyanAccent,
                  ),
                  _RewardRow(
                    icon: Icons.confirmation_number,
                    label: '소환권',
                    value: '+$ticketReward',
                    color: Colors.purple,
                  ),
                  _RewardRow(
                    icon: Icons.trending_up,
                    label: '영구 보너스',
                    value: '${currentBonus.toInt()}% → ${nextBonus.toInt()}%',
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: '전생 시 초기화되는 것',
                color: Colors.red.withValues(alpha: 0.1),
                children: const [
                  _LossRow(label: '플레이어 레벨 → Lv.1'),
                  _LossRow(label: '스테이지 진행 → 1-1'),
                  _LossRow(label: '던전 기록 초기화'),
                  _LossRow(label: '보유 몬스터 전체 삭제'),
                  _LossRow(label: '골드/파편/포션 초기화'),
                  _LossRow(label: '퀘스트 진행 초기화'),
                ],
              ),
            ] else
              _InfoCard(
                title: '최대 전생 달성!',
                color: Colors.amber.withValues(alpha: 0.15),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '최대 전생 레벨 ${PrestigeService.maxPrestigeLevel}에 도달했습니다!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Success message
            if (prestige.resultMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prestige.resultMessage!,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Prestige button
            if (!isMaxPrestige)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: prestige.isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: canPrestige
                            ? () => _showPrestigeConfirm(context, ref)
                            : null,
                        icon: const Icon(Icons.autorenew, size: 28),
                        label: Text(
                          canPrestige ? '전생하기' : '조건 미달',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPrestige
                              ? Colors.deepPurple
                              : Colors.grey[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showPrestigeConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('전생 확인'),
          ],
        ),
        content: const Text(
          '전생하면 레벨, 스테이지, 몬스터, 재화가 모두 초기화됩니다.\n\n'
          '대신 영구 보너스와 다이아몬드를 획득합니다.\n\n'
          '정말 전생하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(prestigeProvider.notifier).performPrestige();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('전생하기'),
          ),
        ],
      ),
    );
  }

  static int _clearedArea(String stageId) {
    if (stageId.isEmpty) return 0;
    final parts = stageId.split('-');
    if (parts.isEmpty) return 0;
    return int.tryParse(parts[0]) ?? 0;
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _PrestigeBadge extends StatelessWidget {
  const _PrestigeBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final starCount = level.clamp(0, 20);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: level > 0
              ? [Colors.deepPurple.shade900, Colors.deepPurple.shade700]
              : [Colors.grey.shade900, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: level > 0
              ? Colors.amber.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.autorenew,
            size: 48,
            color: level > 0 ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            '전생 Lv.$level',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: level > 0 ? Colors.amber : Colors.grey,
            ),
          ),
          if (starCount > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: List.generate(
                starCount,
                (_) => const Icon(Icons.star, color: Colors.amber, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.children,
    this.color,
  });

  final String title;
  final List<Widget> children;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _BonusRow extends StatelessWidget {
  const _BonusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    required this.met,
    required this.current,
  });

  final String label;
  final bool met;
  final String current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: met ? Colors.greenAccent : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: met ? Colors.white : Colors.grey,
              ),
            ),
          ),
          Text(
            current,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: met ? Colors.greenAccent : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LossRow extends StatelessWidget {
  const _LossRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.remove_circle_outline, color: Colors.redAccent,
              size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
