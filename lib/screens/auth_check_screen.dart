import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({Key? key}) : super(key: key);

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Cek ke "lemari besi" apakah ada token
    bool isLoggedIn = await _apiService.isLoggedIn();

    // ✅ JIKA LOGIN → KIRIM FCM TOKEN KE SERVER
    if (isLoggedIn) {
      await _sendFcmTokenToServer();
    }

    // Pindah halaman berdasarkan hasil
    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _sendFcmTokenToServer() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint("📤 Mengirim FCM Token ke server: $token");

      if (token != null) {
        await _apiService.saveFcmToken(token);
        debugPrint("✅ FCM Token berhasil disimpan ke database");
      }
    } catch (e) {
      debugPrint("❌ Gagal mengirim FCM token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan layar loading selagi kita mengecek
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
