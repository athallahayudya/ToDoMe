import 'package:flutter/material.dart';

// 1. FORMAT TANGGAL
import 'package:intl/date_symbol_data_local.dart';

// 2. NOTIFICATION SERVICE
import 'services/notification_service.dart';

// 3. FIREBASE CORE & MESSAGING
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 4. LOCAL NOTIFICATION UNTUK BACKGROUND
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'screens/splash_screen.dart';

/// ==========================================================
/// ✅ SATU-SATUNYA BACKGROUND HANDLER (WAJIB TOP LEVEL)
/// ==========================================================
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  final title = message.notification?.title ??
      message.data['title'] ??
      "Notifikasi";

  final body =
      message.notification?.body ?? message.data['body'] ?? "";

  const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    'todome_fcm_alerts',
    'Notifikasi Server',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    notificationDetails,
  );

  debugPrint("✅ Background FCM notification shown");
}

void main() async {
  // 5. PASTIKAN FLUTTER READY
  WidgetsFlutterBinding.ensureInitialized();

  // 6. INIT FIREBASE
  await Firebase.initializeApp();

  // ✅ 7. REGISTER BACKGROUND FCM HANDLER (PALING PENTING)
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  // 8. FORMAT TANGGAL INDONESIA
  await initializeDateFormatting('id_ID', null);

  // 9. REQUEST IZIN FCM
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 10. AMBIL TOKEN FCM (LOG SAJA)
  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint("✅ FCM TOKEN: $fcmToken");

  runApp(const MyApp());
}

/// ==========================================================
/// ✅ ROOT APP
/// ==========================================================
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();

    // ✅ INIT NOTIFIKASI LOCAL + FCM SETELAH CONTEXT TERSEDIA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do Me',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
