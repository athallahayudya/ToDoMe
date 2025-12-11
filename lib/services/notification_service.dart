import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ===========================================================
  // ✅ INIT UTAMA (LOCAL + FCM FOREGROUND)
  // ===========================================================
  Future<void> init(BuildContext context) async {
    debugPrint("🔔 [NOTIF] INIT SERVICES");

    // ============ TIMEZONE LOCAL ============
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    debugPrint("✅ TIMEZONE SET: Asia/Jakarta");

    // ============ INIT LOCAL NOTIFICATION ============
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("✅ CLICK NOTIF: ${details.payload}");
      },
    );

    await requestPermissions();
    await _initFCM(context);
  }

  // ===========================================================
  // ✅ PERMISSION ANDROID 13+
  // ===========================================================
  Future<void> requestPermissions() async {
    debugPrint("📛 REQUEST PERMISSIONS");

    if (Platform.isAndroid) {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await android?.requestNotificationsPermission();
      debugPrint("✅ ANDROID NOTIFICATION PERMISSION REQUESTED");
    }

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("✅ FCM PERMISSION REQUESTED");
  }

  // ===========================================================
  // ✅ INIT FIREBASE NOTIFICATION (FOREGROUND)
  // ===========================================================
  Future<void> _initFCM(BuildContext context) async {
    final token = await _firebaseMessaging.getToken();
    debugPrint("✅ FCM TOKEN: $token");

    // ✅ NOTIF MASUK SAAT APP DIBUKA (FOREGROUND)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 FCM FOREGROUND RECEIVED");

      final title = message.notification?.title ??
          message.data['title'] ??
          "Notifikasi";

      final body =
          message.notification?.body ?? message.data['body'] ?? "";

      debugPrint("🟢 Foreground Title: $title");
      debugPrint("🟢 Foreground Body : $body");

      _showForegroundNotification(title, body);
    });

    // ✅ NOTIF DIKLIK SAAT APP BACKGROUND / TERMINATED
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("✅ NOTIF DIKLIK DARI BACKGROUND / TERMINATED");
    });
  }

  // ===========================================================
  // ✅ TAMPILKAN NOTIFIKASI SAAT FOREGROUND
  // ===========================================================
  Future<void> _showForegroundNotification(String title, String body) async {
    debugPrint("🔔 SHOW FOREGROUND NOTIF → $title");

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'todome_fcm_alerts',
      'Notifikasi Server',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }

  // ===========================================================
  // ✅ SCHEDULE NOTIFIKASI REMINDER TUGAS (LOKAL + DEBUG)
  // ===========================================================
  Future<void> scheduleTaskNotifications(
      int taskId, String title, DateTime deadline) async {

    debugPrint("=======================================");
    debugPrint("📌 SCHEDULE TASK REMINDER");
    debugPrint("📌 TASK ID   : $taskId");
    debugPrint("📌 TITLE     : $title");
    debugPrint("📌 DEADLINE  : $deadline");
    debugPrint("📌 NOW       : ${DateTime.now()}");

    final baseId = taskId * 1000;
    final tzDeadline = tz.TZDateTime.from(deadline, tz.local);

    debugPrint("📌 DEADLINE TZ: $tzDeadline");

    await _schedule(baseId + 1, "H-1 Jam: $title",
        tzDeadline.subtract(const Duration(hours: 1)));

    await _schedule(baseId + 2, "H-30 Menit: $title",
        tzDeadline.subtract(const Duration(minutes: 30)));

    await _schedule(baseId + 3, "H-15 Menit: $title",
        tzDeadline.subtract(const Duration(minutes: 15)));

    await _schedule(baseId + 4, "H-5 Menit: $title",
        tzDeadline.subtract(const Duration(minutes: 5)));

    debugPrint("✅ ALL REMINDER REQUEST SENT");
    debugPrint("=======================================");
  }

  // ===========================================================
  // ✅ INTERNAL SCHEDULE HANDLER + DEBUG
  // ===========================================================
  Future<void> _schedule(int id, String title, tz.TZDateTime time) async {
    final now = tz.TZDateTime.now(tz.local);

    debugPrint("⏰ CEK SCHEDULE:");
    debugPrint("   ID    : $id");
    debugPrint("   TITLE : $title");
    debugPrint("   TIME  : $time");
    debugPrint("   NOW   : $now");

    if (time.isBefore(now)) {
      debugPrint("⚠️ SKIPPED — WAKTU SUDAH LEWAT");
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        "",
        time,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todome_task_alerts',
            'Pengingat Tugas',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint("✔ BERHASIL SCHEDULE ID $id JAM $time");
    } catch (e) {
      debugPrint("❌ GAGAL SCHEDULE: $e");
    }
  }

  // ===========================================================
  // ✅ CANCEL SEMUA NOTIFIKASI TASK
  // ===========================================================
  Future<void> cancelTaskNotifications(int taskId) async {
    debugPrint("🧹 CANCEL NOTIFIKASI TASK: $taskId");

    final baseId = taskId * 1000;
    for (int i = 0; i < 150; i++) {
      await flutterLocalNotificationsPlugin.cancel(baseId + i);
    }

    debugPrint("✅ SEMUA NOTIFIKASI TASK DICANCEL");
  }
}
  