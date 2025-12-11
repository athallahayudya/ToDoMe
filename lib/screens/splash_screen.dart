import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'auth_check_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
  }

  Future<void> _checkFirstTimeUser() async {
    // 1. Simulasi loading (misal 2 detik biar logonya kelihatan)
    await Future.delayed(const Duration(seconds: 4));

    // 2. Cek di memori HP apakah user sudah pernah melihat tutorial
    final prefs = await SharedPreferences.getInstance();
    final bool seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

    if (!mounted) return;

    // 3. Navigasi
    if (seenOnboarding) {
      // User lama -> Langsung cek login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthCheckScreen()),
      );
    } else {
      // User baru -> Tampilkan Tutorial
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple, // Warna tema ToDoMe
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Aplikasi (Gunakan Icon atau Image asset jika ada)
            Container(
              padding: const EdgeInsets.all(4), // Border putih tipis
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              // ClipOval memotong gambar menjadi lingkaran sempurna
              child: ClipOval(
                child: Image.asset(
                  "assets/Logo App.png", // Pastikan nama file sesuai dengan di folder assets
                  width: 120, // Ukuran logo
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback jika gambar gagal dimuat
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Icon(Icons.check_circle, size: 80, color: Colors.purple),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "To Do Me",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Atur Tugas, Raih Impian",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator Putih
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}