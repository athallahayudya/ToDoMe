import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_check_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  // Fungsi saat tombol "Selesai" diklik
  void _onIntroEnd(BuildContext context) async {
    // 1. Simpan tanda bahwa user sudah melihat tutorial
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    // 2. Pindah ke halaman Auth/Login
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthCheckScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Style teks agar rapi
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.grey);
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.purple),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      
      // --- DAFTAR HALAMAN TUTORIAL ---
      pages: [
        PageViewModel(
          title: "Kelola Tugasmu",
          body: "Catat semua tugas harian, mingguan, hingga tahunan dengan mudah dan terorganisir.",
          image: _buildImage(Icons.list_alt_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Notifikasi Pintar",
          body: "Dapatkan pengingat H-7 jam, H-1 jam, hingga 10 menit sebelum deadline. Jangan sampai terlewat!",
          image: _buildImage(Icons.notifications_active_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Kalender Interaktif",
          body: "Lihat jadwalmu dalam tampilan kalender yang rapi. Rencanakan hari-harimu dengan lebih baik.",
          image: _buildImage(Icons.calendar_month_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Siap Memulai?",
          body: "Ayo mulai produktif bersama To Do Me sekarang juga!",
          image: _buildImage(Icons.rocket_launch_rounded),
          decoration: pageDecoration,
        ),
      ],

      // --- TOMBOL NAVIGASI ---
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // Tombol skip fungsinya sama dengan done
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      
      // Tampilan Tombol
      skip: const Text('Lewati', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.purple)),
      next: const Icon(Icons.arrow_forward, color: Colors.purple),
      done: const Text('Mulai', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.purple)),
      
      // Indikator Titik-titik
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeColor: Colors.purple,
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }

  // Helper untuk membuat Icon besar (bisa diganti Image.asset jika punya gambar)
  Widget _buildImage(IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          shape: BoxShape.circle
        ),
        child: Icon(icon, size: 100.0, color: Colors.purple),
      ),
    );
  }
}