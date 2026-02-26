import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gameapp/core/constants/app_colors.dart';
import 'package:gameapp/core/utils/format_utils.dart';
import 'package:gameapp/data/models/quest_model.dart';
import 'package:gameapp/data/static/quest_database.dart';
import 'package:gameapp/presentation/providers/quest_provider.dart';
import 'package:gameapp/presentation/widgets/common/currency_bar.dart';

// =============================================================================
// QuestScreen
// =============================================================================

class QuestScreen extends ConsumerStatefulWidget {
  const QuestScreen({super.key});

  @override
  ConsumerState<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends ConsumerState<QuestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Ensure quests are loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final questState = ref.read(questProvider);
      if (!questState.isLoaded) {
        ref.read(questProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CurrencyBar(),
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textTertiary,
              tabs: const [
                Tab(text: '일일 퀘스트'),
                Tab(text: '업적'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _QuestList(questType: QuestType.daily),
                _QuestList(questType: QuestType.achievement),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _QuestList
// =============================================================================

class _QuestList extends ConsumerWidget {
  const _QuestList({required this.questType});

  final QuestType questType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questState = ref.watch(questProvider);

    if (!questState.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final quests = questType == QuestType.daily
        ? questState.dailyQuests
        : questState.achievements;

    if (quests.isEmpty) {
      return const Center(
        child: Text(
          '퀘스트가 없습니다',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        return _QuestCard(quest: quests[index]);
      },
    );
  }
}

// =============================================================================
// _QuestCard
// =============================================================================

class _QuestCard extends ConsumerWidget {
  const _QuestCard({required this.quest});

  final QuestModel quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final def = QuestDatabase.findById(quest.questId);
    if (def == null) return const SizedBox.shrink();

    final progress = quest.currentProgress.clamp(0, def.targetCount);
    final ratio = def.targetCount > 0 ? progress / def.targetCount : 0.0;
    final isReady = progress >= def.targetCount && !quest.isCompleted;
    final isDone = quest.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.surfaceVariant.withValues(alpha: 0.4)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady
              ? AppColors.warning
              : isDone
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.border,
          width: isReady ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  def.name,
                  style: TextStyle(
                    color: isDone
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isDone)
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 20)
              else if (isReady)
                GestureDetector(
                  onTap: () =>
                      ref.read(questProvider.notifier).claimReward(quest.questId),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '수령',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // Description
          Text(
            def.description,
            style: TextStyle(
              color: isDone ? AppColors.disabledText : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(
                isDone
                    ? AppColors.success.withValues(alpha: 0.5)
                    : isReady
                        ? AppColors.warning
                        : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 6),

          // Progress text + rewards
          Row(
            children: [
              Text(
                '$progress / ${def.targetCount}',
                style: TextStyle(
                  color:
                      isDone ? AppColors.disabledText : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Rewards
              if (def.rewardGold > 0) ...[
                Text(
                  '${FormatUtils.formatNumber(def.rewardGold)} G',
                  style: TextStyle(
                    color: isDone ? AppColors.disabledText : AppColors.gold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (def.rewardDiamond > 0) ...[
                Text(
                  '${def.rewardDiamond}',
                  style: TextStyle(
                    color: isDone ? AppColors.disabledText : AppColors.diamond,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (def.rewardGachaTicket > 0)
                Text(
                  '${def.rewardGachaTicket}',
                  style: TextStyle(
                    color: isDone
                        ? AppColors.disabledText
                        : AppColors.accentSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
