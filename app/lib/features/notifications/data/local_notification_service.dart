import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:musemend/features/notifications/domain/future_letter_reminder.dart';
import 'package:musemend/features/notifications/domain/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _journalOpenRequests = StreamController<String>.broadcast();
  bool _initialized = false;
  String? _pendingJournalId;

  @override
  Stream<String> get journalOpenRequests => _journalOpenRequests.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handlePayload(response.payload);
      },
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handlePayload(launchDetails?.notificationResponse?.payload);
    }
    _initialized = true;
  }

  @override
  String? takePendingJournalId() {
    final journalId = _pendingJournalId;
    _pendingJournalId = null;
    return journalId;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android =
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  @override
  Future<void> scheduleFutureLetter(FutureLetterReminder reminder) async {
    await initialize();
    final delivery = tz.TZDateTime.from(reminder.deliverAt.toLocal(), tz.local);
    if (!delivery.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      _notificationId(reminder.journalId),
      'Một lá thư đang đợi bạn',
      'Mở MuseMend khi bạn sẵn sàng.',
      delivery,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'future_letters',
          'Thư tương lai',
          channelDescription: 'Nhắc khi thư gửi tương lai đến ngày mở',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'journal:${reminder.journalId}',
    );
  }

  @override
  Future<void> cancelFutureLetter(String journalId) async {
    await initialize();
    await _plugin.cancel(_notificationId(journalId));
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  int _notificationId(String journalId) {
    final compact = journalId.replaceAll('-', '');
    return int.parse(compact.substring(0, 7), radix: 16);
  }

  void _handlePayload(String? payload) {
    if (payload == null || !payload.startsWith('journal:')) return;
    final journalId = payload.substring('journal:'.length);
    if (journalId.isEmpty) return;
    _pendingJournalId = journalId;
    _journalOpenRequests.add(journalId);
  }
}
