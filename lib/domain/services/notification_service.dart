import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:gameapp/core/constants/game_config.dart';

/// Manages local push notifications for the game.
///
/// Schedules:
/// - Offline reward cap reminder (12h after last online)
/// - Come-back reminder (24h after last online)
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  /// Whether notifications are enabled by the user.
  bool get isEnabled {
    final box = Hive.box('settings');
    return box.get('notificationsEnabled', defaultValue: true) as bool;
  }

  /// Toggles notification enabled state and persists to Hive.
  void setEnabled(bool enabled) {
    final box = Hive.box('settings');
    box.put('notificationsEnabled', enabled);
    if (!enabled) {
      cancelAll();
    }
  }

  // Notification IDs
  static const int _offlineCapId = 1;
  static const int _comeBackId = 2;

  /// Must be called once at app start.
  Future<void> init() async {
    if (_initialised) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialised = true;
  }

  /// Schedule notifications when the app goes to background.
  ///
  /// [lastOnlineAt] is used to calculate when offline rewards will be capped.
  Future<void> scheduleOfflineReminders(DateTime lastOnlineAt) async {
    if (!_initialised || !isEnabled) return;

    await cancelAll();

    // 1) Offline reward cap notification — fires when max offline hours reached
    final capTime =
        lastOnlineAt.add(Duration(hours: GameConfig.maxOfflineHours));
    if (capTime.isAfter(DateTime.now())) {
      await _scheduleAt(
        id: _offlineCapId,
        scheduledAt: capTime,
        title: '오프라인 보상 최대치 도달!',
        body: '보상이 더 쌓이지 않아요. 접속해서 수령하세요!',
      );
    }

    // 2) Come-back reminder — fires 24h after last online
    final comeBackTime = lastOnlineAt.add(const Duration(hours: 24));
    if (comeBackTime.isAfter(DateTime.now())) {
      await _scheduleAt(
        id: _comeBackId,
        scheduledAt: comeBackTime,
        title: '몬스터들이 기다리고 있어요!',
        body: '오프라인 보상이 가득 찼어요. 지금 접속하세요!',
      );
    }
  }

  /// Cancel all pending notifications (called when app resumes).
  Future<void> cancelAll() async {
    if (!_initialised) return;
    await _plugin.cancelAll();
  }

  Future<void> _scheduleAt({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'gameapp_reminders',
      '게임 알림',
      channelDescription: '오프라인 보상 및 리마인더 알림',
      importance: Importance.high,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
