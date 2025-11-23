import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';

// Import dari branch profil
import 'task_summary_cards.dart';
import 'weekly_line_chart.dart';
import 'upcoming_tasks.dart';
import 'unfinished_pie_chart.dart';
import 'edit_profile_screen.dart';

// Import dari branch main
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "";
  String userBio = "";
  String userPhoto = "";
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final api = ApiService();

    try {
      final response = await api.getProfile();
      final user = response["user"];

       if (!mounted) return;

      setState(() {
        userName = user["name"] ?? "Nama User";
        userBio = user["bio"] ?? "Belum ada bio";
        userPhoto = user["photo_url"] ?? "";
        loadingProfile = false;
      });
    } catch (e) {
      print("GAGAL GET PROFILE: $e");
    }
  }

  // Profile Header Widget dari branch profil
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          //Foto profil pengguna
          CircleAvatar(
            radius: 40,
            backgroundImage: userPhoto.isNotEmpty
                ? NetworkImage(userPhoto)
                : null,
            child: userPhoto.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),

          const SizedBox(width: 16),

          // Nama + Bio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loadingProfile ? "Memuat..." : userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loadingProfile ? "Memuat bio..." : userBio,
                  style: TextStyle(color: Colors.grey[600]),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: const Text("Edit Profil"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi logout dari branch main
  void _logout(BuildContext context) async {
    final ApiService apiService = ApiService();
    try {
      await apiService.logout();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),

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
