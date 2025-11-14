import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Impor ApiService
import 'login_screen.dart'; // Impor LoginScreen (untuk tujuan redirect)

class HomeScreen extends StatelessWidget {
  // Menghapus 'const' dari konstruktor karena _apiService
  HomeScreen({Key? key}) : super(key: key);

  // Buat instance ApiService
  final ApiService _apiService = ApiService();

  // Buat fungsi helper untuk logout
  void _logout(BuildContext context) async {
    try {
      // Panggil API logout (hapus token di server & HP)
      await _apiService.logout();
      
      // Kembali ke LoginScreen, hancurkan halaman ini (user tdk bisa "back")
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      // Tampilkan error jika logout gagal (jarang terjadi)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To Do Me'),
        // Tambahkan tombol 'actions' (tombol di kanan)
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _logout(context); // Panggil fungsi logout saat ditekan
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Selamat Datang! Login Berhasil.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}