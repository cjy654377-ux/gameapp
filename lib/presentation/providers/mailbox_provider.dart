import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'currency_provider.dart';

// =============================================================================
// Mail Model
// =============================================================================

class MailItem {
  final String id;
  final String title;
  final String body;
  final DateTime sentAt;
  final DateTime expiresAt;
  final bool isRead;
  final bool isClaimed;

  /// Attached rewards (null = no reward).
  final int? rewardGold;
  final int? rewardDiamond;
  final int? rewardExpPotion;
  final int? rewardGachaTicket;

  bool get hasReward =>
      (rewardGold ?? 0) > 0 ||
      (rewardDiamond ?? 0) > 0 ||
      (rewardExpPotion ?? 0) > 0 ||
      (rewardGachaTicket ?? 0) > 0;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  const MailItem({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.expiresAt,
    this.isRead = false,
    this.isClaimed = false,
    this.rewardGold,
    this.rewardDiamond,
    this.rewardExpPotion,
    this.rewardGachaTicket,
  });

  MailItem copyWith({bool? isRead, bool? isClaimed}) => MailItem(
        id: id,
        title: title,
        body: body,
        sentAt: sentAt,
        expiresAt: expiresAt,
        isRead: isRead ?? this.isRead,
        isClaimed: isClaimed ?? this.isClaimed,
        rewardGold: rewardGold,
        rewardDiamond: rewardDiamond,
        rewardExpPotion: rewardExpPotion,
        rewardGachaTicket: rewardGachaTicket,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'sentAt': sentAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isRead': isRead,
        'isClaimed': isClaimed,
        'rewardGold': rewardGold,
        'rewardDiamond': rewardDiamond,
        'rewardExpPotion': rewardExpPotion,
        'rewardGachaTicket': rewardGachaTicket,
      };

  factory MailItem.fromJson(Map<String, dynamic> j) => MailItem(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        sentAt: DateTime.parse(j['sentAt'] as String),
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        isRead: j['isRead'] as bool? ?? false,
        isClaimed: j['isClaimed'] as bool? ?? false,
        rewardGold: j['rewardGold'] as int?,
        rewardDiamond: j['rewardDiamond'] as int?,
        rewardExpPotion: j['rewardExpPotion'] as int?,
        rewardGachaTicket: j['rewardGachaTicket'] as int?,
      );
}

// =============================================================================
// State
// =============================================================================

class MailboxState {
  final List<MailItem> mails;
  final String? message;

  const MailboxState({this.mails = const [], this.message});

  int get unreadCount => mails.where((m) => !m.isRead && !m.isExpired).length;
  int get claimableCount =>
      mails.where((m) => m.hasReward && !m.isClaimed && !m.isExpired).length;

  MailboxState copyWith({
    List<MailItem>? mails,
    String? message,
    bool clearMessage = false,
  }) =>
      MailboxState(
        mails: mails ?? this.mails,
        message: clearMessage ? null : (message ?? this.message),
      );
}

// =============================================================================
// Provider
// =============================================================================

final mailboxProvider =
    StateNotifierProvider<MailboxNotifier, MailboxState>((ref) {
  return MailboxNotifier(ref);
});

class MailboxNotifier extends StateNotifier<MailboxState> {
  MailboxNotifier(this._ref) : super(const MailboxState());
  final Ref _ref;

  static const _key = 'mailbox';

  void load() {
    final box = Hive.box('settings');
    final raw = box.get(_key) as String?;
    List<MailItem> mails = [];
    if (raw != null && raw.isNotEmpty) {
      mails = (jsonDecode(raw) as List)
          .map((e) => MailItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Remove expired+claimed mails older than 7 days
    final now = DateTime.now();
    mails = mails
        .where((m) => now.difference(m.expiresAt).inDays < 7 || !m.isClaimed)
        .toList();

    // Generate system mails if needed
    _generateSystemMails(mails);

    state = MailboxState(mails: mails);
    _save();
  }

  Future<void> _save() async {
    final box = Hive.box('settings');
    final json = jsonEncode(state.mails.map((m) => m.toJson()).toList());
    await box.put(_key, json);
  }

  /// Generates daily system mails (welcome, daily login bonus, etc.)
  void _generateSystemMails(List<MailItem> existing) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final existingIds = existing.map((m) => m.id).toSet();

    // Welcome mail (only once)
    if (!existingIds.contains('welcome')) {
      existing.insert(
        0,
        MailItem(
          id: 'welcome',
          title: '환영합니다!',
          body: '몬스터 수집 게임에 오신 것을 환영합니다! 시작 선물을 받아주세요.',
          sentAt: now,
          expiresAt: now.add(const Duration(days: 30)),
          rewardGold: 1000,
          rewardDiamond: 50,
          rewardGachaTicket: 3,
        ),
      );
    }

    // Daily login reward mail
    final dailyId = 'daily_${today.toIso8601String().substring(0, 10)}';
    if (!existingIds.contains(dailyId)) {
      existing.insert(
        0,
        MailItem(
          id: dailyId,
          title: '일일 접속 보상',
          body: '매일 접속해 주셔서 감사합니다! 오늘의 보상입니다.',
          sentAt: now,
          expiresAt: now.add(const Duration(days: 7)),
          rewardGold: 500,
          rewardExpPotion: 2,
        ),
      );
    }

    // Weekly bonus (Monday)
    if (now.weekday == DateTime.monday) {
      final weeklyId = 'weekly_${today.toIso8601String().substring(0, 10)}';
      if (!existingIds.contains(weeklyId)) {
        existing.insert(
          0,
          MailItem(
            id: weeklyId,
            title: '주간 보너스',
            body: '이번 주도 화이팅! 주간 보너스 보상입니다.',
            sentAt: now,
            expiresAt: now.add(const Duration(days: 7)),
            rewardGold: 2000,
            rewardDiamond: 30,
            rewardGachaTicket: 1,
          ),
        );
      }
    }
  }

  Future<void> markRead(String mailId) async {
    final idx = state.mails.indexWhere((m) => m.id == mailId);
    if (idx < 0) return;

    final updated = [...state.mails];
    updated[idx] = updated[idx].copyWith(isRead: true);
    state = state.copyWith(mails: updated);
    await _save();
  }

  Future<void> claimReward(String mailId) async {
    final idx = state.mails.indexWhere((m) => m.id == mailId);
    if (idx < 0) return;

    final mail = state.mails[idx];
    if (mail.isClaimed || !mail.hasReward || mail.isExpired) return;

    // Grant rewards
    final currency = _ref.read(currencyProvider.notifier);
    if ((mail.rewardGold ?? 0) > 0) {
      await currency.addGold(mail.rewardGold!);
    }
    if ((mail.rewardDiamond ?? 0) > 0) {
      await currency.addDiamond(mail.rewardDiamond!);
    }
    if ((mail.rewardExpPotion ?? 0) > 0) {
      await currency.addExpPotion(mail.rewardExpPotion!);
    }
    if ((mail.rewardGachaTicket ?? 0) > 0) {
      await currency.addGachaTicket(mail.rewardGachaTicket!);
    }

    final updated = [...state.mails];
    updated[idx] = updated[idx].copyWith(isClaimed: true, isRead: true);

    final rewards = <String>[];
    if ((mail.rewardGold ?? 0) > 0) rewards.add('골드 +${mail.rewardGold}');
    if ((mail.rewardDiamond ?? 0) > 0) rewards.add('다이아 +${mail.rewardDiamond}');
    if ((mail.rewardExpPotion ?? 0) > 0) rewards.add('경험치포션 +${mail.rewardExpPotion}');
    if ((mail.rewardGachaTicket ?? 0) > 0) rewards.add('소환권 +${mail.rewardGachaTicket}');

    state = state.copyWith(
      mails: updated,
      message: rewards.join(', '),
    );
    await _save();
  }

  Future<void> claimAll() async {
    final claimable = state.mails
        .where((m) => m.hasReward && !m.isClaimed && !m.isExpired)
        .toList();
    if (claimable.isEmpty) return;

    for (final mail in claimable) {
      await claimReward(mail.id);
    }
  }

  Future<void> deleteMail(String mailId) async {
    final updated = state.mails.where((m) => m.id != mailId).toList();
    state = state.copyWith(mails: updated);
    await _save();
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}
