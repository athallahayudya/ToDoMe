import 'dart:io'; // Untuk deteksi platform
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // <-- 1. Tambah ini
import '../models/task.dart'; // (Model Task tetap sama)

class ApiService {
  // --- KONFIGURASI DASAR ---

  // Gunakan IP 10.0.2.2 untuk Emulator Android
  // Gunakan IP 127.0.0.1 (localhost) jika menjalankan di Windows/Web
  static final String _baseUrl = Platform.isAndroid ? "http://10.0.2.2:8000/api" : "http://127.0.0.1:8000/api";

  // Catatan: Membuat "lemari besi" untuk menyimpan token
  final _storage = const FlutterSecureStorage();

  // --- HELPER INTERNAL ---

  // Catatan: Helper untuk membaca token dari "lemari besi"
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Catatan: Helper "ajaib" yang membuat header
  // Ini otomatis menempelkan token jika ada
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Jika token ada, tambahkan header Authorization
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- 1. FUNGSI AUTENTIKASI ---

  // Fungsi untuk LOGIN
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Jika sukses, simpan token
        final data = jsonDecode(response.body);
        await _storage.write(key: 'auth_token', value: data['access_token']);
        return true;
      } else {
        // Jika gagal (misal: 401 password salah), return false
        return false;
      }
    } catch (e) {
      print("Error saat login: $e");
      return false;
    }
  }

  // Fungsi untuk REGISTER
  Future<bool> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );
      // 201 = Created
      return response.statusCode == 201;
    } catch (e) {
      print("Error saat register: $e");
      return false;
    }
  }

  // Fungsi untuk LOGOUT
  Future<void> logout() async {
    try {
      // Panggil API logout di backend (untuk menghapus token di server)
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: await _getHeaders(), // Wajib kirim token untuk tahu siapa yg logout
      );
    } catch (e) {
      print("Error saat API logout: $e");
      // Tidak masalah, tetap hapus token di HP
    } finally {
      // Hapus token dari "lemari besi" di HP
      await _storage.delete(key: 'auth_token');
    }
  }

  // Fungsi untuk Cek apakah user sedang login (cek token)
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // --- 2. FUNGSI TASK (SEKARANG AMAN) ---

  // Catatan: Fungsi ini sekarang OTOMATIS mengirim token
  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks'),
        headers: await _getHeaders(), // <-- Menggunakan header aman
      );

      if (response.statusCode == 200) {
        return taskFromJson(response.body);
      } else if (response.statusCode == 401) {
        // 401 = Unauthorized (Token tidak valid/kedaluwarsa)
        await logout(); // Otomatis logout user
        throw Exception('Sesi habis. Silakan login kembali.');
      } else {
        throw Exception('Gagal mengambil tasks. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat getTasks: $e');
    }
  }

  // Catatan: Fungsi ini juga sekarang OTOMATIS mengirim token
  Future<Task> createTask(String judul, {String? deskripsi, List<int>? categoryIds}) async {
    try {
      final body = jsonEncode({
        'judul': judul,
        'deskripsi': deskripsi,
        'category_ids': categoryIds, // Kirim kategori
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: await _getHeaders(), // <-- Menggunakan header aman
        body: body,
      );

      if (response.statusCode == 201) {
        return Task.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Sesi habis. Silakan login kembali.');
      } else {
        throw Exception('Gagal membuat task. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saat createTask: $e');
    }
  }

  // (Anda bisa tambahkan fungsi updateTask, deleteTask, getCategories, dll
  // di sini dengan pola yang sama persis: gunakan '_getHeaders()')
}