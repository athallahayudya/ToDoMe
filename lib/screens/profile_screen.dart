import 'package:flutter/material.dart';

// Import UI dari teman Anda (TETAP ADA)
import 'profile_header.dart';
import 'task_summary_cards.dart';
import 'weekly_line_chart.dart';
import 'upcoming_tasks.dart';
import 'unfinished_pie_chart.dart';

// Import Service (TETAP ADA)
import '../services/google_auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  // --- FUNGSI LOGOUT (DIPERBAIKI) ---
  // Logika teman Anda diganti dengan logika "Anti-Crash" kita.
  void _logout(BuildContext context) async {
    final ApiService apiService = ApiService();
    final GoogleAuthService googleAuthService = GoogleAuthService();

    // 1. Coba Logout Google (Dibungkus try-catch terpisah)
    // Agar jika user login manual, error di sini tidak menghentikan proses logout utama.
    try {
      await googleAuthService.signOut();
    } catch (e) {
      // Diamkan saja jika gagal (wajar jika login manual)
      print("Info: Logout Google dilewati/gagal: $e");
    }

    // 2. Logout Backend & Hapus Token (Ini yang UTAMA)
    try {
      await apiService.logout();

      if (context.mounted) {
        // Pindah ke Login Screen dan hapus semua rute sebelumnya
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal logout: $e')),
        );
      }
    }
  }

  // --- TAMPILAN UI (TETAP SAMA SEPERTI TEMAN ANDA) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            onPressed: () => _logout(context), // Memanggil fungsi logout yang sudah diperbaiki
            icon: const Icon(Icons.logout),
          )
        ],
      ),

      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget-widget buatan teman Anda
              ProfileHeader(),
              SizedBox(height: 20),

              Text(
                "Ringkasan Tugas",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TaskSummaryCards(),
              SizedBox(height: 16),

              WeeklyLineChart(),
              SizedBox(height: 16),

              UpcomingTasks(),
              SizedBox(height: 16),

              UnfinishedPieChart(),
            ],
          ),
        ),
      ),
    );
  }
}