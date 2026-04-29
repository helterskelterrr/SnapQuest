import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_strings.dart';

// Top-level handler for background FCM messages (required by firebase_messaging)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // flutter_local_notifications will show the notification automatically
  // for data-only messages. For notification messages, the OS handles it.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const String _channelId = 'snapquest_channel';
  static const String _channelName = 'SnapQuest Notifications';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Create Android notification channel (required for Android 8+)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Show FCM foreground notifications as local notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _plugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });
  }

  Future<void> requestPermission() async {
    // Request FCM permission (covers both local + push on iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  /// Get and return the FCM device token for this user
  Future<String?> getFcmToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Save this device's FCM token to Firestore under the user's doc
  Future<void> saveFcmToken(String uid) async {
    final token = await getFcmToken();
    if (token == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcm_token': token},
      SetOptions(merge: true),
    );

    // Refresh token if it changes
    _fcm.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcm_token': newToken},
        SetOptions(merge: true),
      );
    });
  }

  /// Send a push notification to a specific user via FCM HTTP v1 API.
  /// Reads their fcm_token from Firestore and sends the message.
  ///
  /// NOTE: This uses the FCM legacy HTTP API (server key).
  /// Get your server key from Firebase Console → Project Settings → Cloud Messaging.
  static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY'; // <-- ganti dengan server key kamu

  Future<void> sendPushToUser({
    required String recipientUid,
    required String title,
    required String body,
    String? submissionId,
  }) async {
    try {
      // Read recipient's FCM token
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipientUid)
          .get();
      if (!doc.exists) return;
      final token = doc.data()?['fcm_token'] as String?;
      if (token == null || token.isEmpty) return;

      // Send via FCM HTTP v1 (legacy endpoint)
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_fcmServerKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': {
            'submission_id': submissionId ?? '',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode != 200) {
        // Token mungkin expired — hapus dari Firestore
        if (response.statusCode == 400 || response.statusCode == 404) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(recipientUid)
              .update({'fcm_token': FieldValue.delete()});
        }
      }
    } catch (_) {
      // Best effort — jangan crash kalau notif gagal
    }
  }

  Future<void> scheduleDailyNotifications() async {
    await _cancelAllNotifications();

    final now = tz.TZDateTime.now(tz.local);

    await _scheduleDaily(
      id: 1,
      title: AppStrings.notif1Title,
      body: AppStrings.notif1Body,
      hour: 7,
      minute: 0,
      now: now,
    );

    await _scheduleDaily(
      id: 2,
      title: AppStrings.notif2Title,
      body: AppStrings.notif2Body,
      hour: 12,
      minute: 0,
      now: now,
    );

    await _scheduleDaily(
      id: 3,
      title: AppStrings.notif3Title,
      body: AppStrings.notif3Body,
      hour: 20,
      minute: 0,
      now: now,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required tz.TZDateTime now,
  }) async {
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
