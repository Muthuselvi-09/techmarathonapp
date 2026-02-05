import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for scheduling local notifications for sessions and sponsor alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  /// Schedule a notification for session starting soon
  Future<void> scheduleSessionReminder({
    required String sessionId,
    required String sessionTitle,
    required String eventName,
    required DateTime sessionStartTime,
    int minutesBefore = 10,
  }) async {
    await initialize();

    final scheduledTime = sessionStartTime.subtract(Duration(minutes: minutesBefore));
    
    // Don't schedule if the time has already passed
    if (scheduledTime.isBefore(DateTime.now())) return;

    final notificationId = sessionId.hashCode;

    const androidDetails = AndroidNotificationDetails(
      'session_reminders',
      'Session Reminders',
      channelDescription: 'Reminders for upcoming sessions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      notificationId,
      'Session Starting Soon',
      '$sessionTitle starts in $minutesBefore minutes',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'session|$sessionId',
    );
  }

  /// Show immediate notification for speaker session going live
  Future<void> showSpeakerLiveNotification({
    required String speakerName,
    required String sessionTitle,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'speaker_live',
      'Speaker Live',
      channelDescription: 'Notifications when a speaker goes live',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🎤 $speakerName is Live!',
      sessionTitle,
      notificationDetails,
      payload: 'speaker_live|$speakerName',
    );
  }

  /// Show sponsor offer alert notification
  Future<void> showSponsorOfferAlert({
    required String sponsorId,
    required String sponsorName,
    required String offerText,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'sponsor_offers',
      'Sponsor Offers',
      channelDescription: 'Alerts for sponsor offers',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      sponsorId.hashCode,
      '🎁 $sponsorName Special Offer!',
      offerText,
      notificationDetails,
      payload: 'sponsor_offer|$sponsorId',
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Schedule reminders for all sessions in a list
  Future<void> scheduleAllSessionReminders({
    required List<Map<String, dynamic>> sessions,
    required String eventName,
  }) async {
    for (final session in sessions) {
      await scheduleSessionReminder(
        sessionId: session['id'] as String,
        sessionTitle: session['title'] as String,
        eventName: eventName,
        sessionStartTime: session['startTime'] as DateTime,
      );
    }
  }
}

/// Global instance for easy access
final notificationService = NotificationService();
