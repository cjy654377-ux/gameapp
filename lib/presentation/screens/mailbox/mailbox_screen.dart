import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gameapp/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../providers/mailbox_provider.dart';

class MailboxScreen extends ConsumerStatefulWidget {
  const MailboxScreen({super.key});

  @override
  ConsumerState<MailboxScreen> createState() => _MailboxScreenState();
}

class _MailboxScreenState extends ConsumerState<MailboxScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(mailboxProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(mailboxProvider);

    // Show snackbar
    ref.listen<MailboxState>(mailboxProvider, (prev, next) {
      if (next.message != null && next.message != prev?.message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message!.resolve(l)), duration: const Duration(seconds: 2)),
        );
        ref.read(mailboxProvider.notifier).clearMessage();
      }
    });

    final activeMails = state.mails.where((m) => !m.isExpired).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.mailboxTitle),
        backgroundColor: AppColors.surface,
        actions: [
          if (state.claimableCount > 0)
            TextButton(
              onPressed: () => ref.read(mailboxProvider.notifier).claimAll(),
              child: Text(
                l.mailboxClaimAll,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: activeMails.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    l.mailboxEmpty,
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              cacheExtent: 400,
              itemCount: activeMails.length,
              itemBuilder: (_, i) => _MailCard(mail: activeMails[i]),
            ),
    );
  }
}

// =============================================================================
// Mail Card
// =============================================================================

class _MailCard extends ConsumerWidget {
  const _MailCard({required this.mail});
  final MailItem mail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mail.isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !mail.isRead
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                mail.hasReward && !mail.isClaimed
                    ? Icons.card_giftcard
                    : mail.isRead
                        ? Icons.drafts
                        : Icons.mail,
                color: mail.hasReward && !mail.isClaimed
                    ? Colors.amber
                    : mail.isRead
                        ? AppColors.textTertiary
                        : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mail.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: mail.isRead ? FontWeight.w500 : FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _formatDate(mail.sentAt),
                style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Body
          Text(
            mail.body,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Rewards
          if (mail.hasReward) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if ((mail.rewardGold ?? 0) > 0)
                  _RewardChip(
                    icon: Icons.monetization_on,
                    color: Colors.amber,
                    text: '${mail.rewardGold}',
                  ),
                if ((mail.rewardDiamond ?? 0) > 0)
                  _RewardChip(
                    icon: Icons.diamond,
                    color: Colors.cyan,
                    text: '${mail.rewardDiamond}',
                  ),
                if ((mail.rewardExpPotion ?? 0) > 0)
                  _RewardChip(
                    icon: Icons.science,
                    color: Colors.green,
                    text: '${mail.rewardExpPotion}',
                  ),
                if ((mail.rewardGachaTicket ?? 0) > 0)
                  _RewardChip(
                    icon: Icons.confirmation_number,
                    color: Colors.orange,
                    text: '${mail.rewardGachaTicket}',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (mail.hasReward && !mail.isClaimed)
                TextButton(
                  onPressed: () =>
                      ref.read(mailboxProvider.notifier).claimReward(mail.id),
                  child: Text(
                    l.mailboxClaim,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (mail.isClaimed)
                Text(
                  l.mailboxClaimed,
                  style: TextStyle(fontSize: 11, color: Colors.green),
                ),
              const Spacer(),
              if (mail.isClaimed || !mail.hasReward)
                GestureDetector(
                  onTap: () =>
                      ref.read(mailboxProvider.notifier).deleteMail(mail.id),
                  child: Icon(Icons.delete_outline,
                      size: 18, color: AppColors.textTertiary),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => FormatUtils.formatDateTime(dt);
}

// =============================================================================
// Reward Chip
// =============================================================================

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
