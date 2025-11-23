import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category; // Hide Category bawaan Flutter
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/subtask.dart';

class ApiService {
  // --- KONFIGURASI URL ---
  static String get _baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000/api";
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000/api";
    } else {
      return "http://127.0.0.1:8000/api";
    }
  }

  final _storage = const FlutterSecureStorage();

  // --- HELPER HEADER & TOKEN (BAGIAN KRUSIAL) ---
  Future<Map<String, String>> _getHeaders({bool needsAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needsAuth) {
      final token = await _storage.read(key: 'token');
      print("DEBUG: Token dari Storage: $token"); // <--- LIHAT INI DI CONSOLE

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        print("DEBUG: Token KOSONG/NULL saat request butuh auth!");
      }
    }
    return headers;
  }

  // --- AUTH ---
  
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<bool> login(String email, String password) async {
    print("DEBUG: Mencoba Login ke $_baseUrl/login");
    
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: await _getHeaders(needsAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    print("DEBUG: Status Login: ${response.statusCode}");
    print("DEBUG: Body Login: ${response.body}"); // <-- PENTING: Kita intip isinya

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // --- PERBAIKAN UTAMA DI SINI ---
      // Kita coba cari token dengan nama 'token' ATAU 'access_token'
      String? token = data['token'] ?? data['access_token'];

      if (token != null) {
        await _storage.write(key: 'token', value: token);
        print("DEBUG: Token berhasil disimpan: $token");
        return true;
      } else {
        print("DEBUG: FATAL! Login 200 OK tapi Token tidak ditemukan di respon JSON.");
        return false;
      }
    } else {
      return false;
    }
  }

  // --- FUNGSI LOGOUT (TAMBAHKAN INI) ---
  Future<void> logout() async {
    try {
      // (Opsional) Beritahu backend untuk hapus token
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: await _getHeaders(),
      );
    } catch (e) {
      // Jika backend error/mati, biarkan saja, tetap hapus token lokal
      print("Error logout server: $e");
    }
    
    // WAJIB: Hapus token dari HP/Browser
    await _storage.delete(key: 'token');
  }

  Future<bool> register(String name, String email, String password) async {
    print("DEBUG: Mencoba Register...");
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: await _getHeaders(needsAuth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );
    
    print("DEBUG: Register Status: ${response.statusCode}");
    
    // Terima 201 (Created) atau 200 (OK)
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print("DEBUG: Register Gagal: ${response.body}");
      return false;
    }
  }

  // --- TASKS (LOAD DATA) ---

  Future<List<Task>> getTasks() async {
    print("DEBUG: Mengambil Tasks...");
    final response = await http.get(
      Uri.parse('$_baseUrl/tasks'),
      headers: await _getHeaders(),
    );

    print("DEBUG: Get Tasks Status: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      print("DEBUG: Jumlah Task ditemukan: ${jsonResponse.length}");
      return jsonResponse.map((data) => Task.fromJson(data)).toList();
    } else {
      print("DEBUG: Gagal Get Tasks: ${response.body}");
      throw Exception('Gagal memuat tugas: ${response.statusCode}');
    }
  }

  Future<Task> createTask({
    required String judul,
    String? deskripsi,
    DateTime? deadline,
    List<int>? categoryIds,
    List<String>? subtasks,
  }) async {
    print("DEBUG: Membuat Task Baru...");
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'judul': judul,
        'deskripsi': deskripsi,
        'deadline': deadline?.toIso8601String(),
        'categories': categoryIds,
        'subtasks': subtasks,
      }),
    );

    print("DEBUG: Create Task Status: ${response.statusCode}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      print("DEBUG: Gagal Create Task: ${response.body}");
      throw Exception('Gagal membuat tugas: ${response.body}');
    }
  }

  // ... (Update & Delete Task - Biarkan dulu) ...
   Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal update tugas');
    }
  }

  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus tugas');
    }
  }

  // --- SUBTASKS ---
  
  Future<Subtask> createSubtask(int taskId, String title) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks/$taskId/subtasks'),
      headers: await _getHeaders(),
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 201) {
      return Subtask.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal membuat subtask');
    }
  }

  Future<Subtask> updateSubtask(int id, bool isCompleted) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/subtasks/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({'is_completed': isCompleted}),
    );

    if (response.statusCode == 200) {
      return Subtask.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal update subtask');
    }
  }

  Future<void> deleteSubtask(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/subtasks/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus subtask');
    }
  }

  // --- CATEGORIES ---

  Future<List<Category>> getCategories() async {
    print("DEBUG: Mengambil Kategori...");
    final response = await http.get(
      Uri.parse('$_baseUrl/categories'),
      headers: await _getHeaders(),
    );

    print("DEBUG: Status Kategori: ${response.statusCode}");

    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Category.fromJson(data)).toList();
    } else {
       print("DEBUG: Gagal Get Kategori: ${response.body}");
      throw Exception('Gagal memuat kategori');
    }
  }

  Future<Category> createCategory(String name) async {
    print("DEBUG: Membuat Kategori: $name");
    final response = await http.post(
      Uri.parse('$_baseUrl/categories'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name}),
    );

    print("DEBUG: Status Create Kategori: ${response.statusCode}");

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
       print("DEBUG: Gagal Create Kategori: ${response.body}");
      throw Exception('Gagal membuat kategori');
    }
  }

    //PROFILE
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _storage.read(key: 'token');

    final res = await http.get(
      Uri.parse("$_baseUrl/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    print("=== PROFILE STATUS: ${res.statusCode}");
    print("=== PROFILE BODY: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal mengambil profil");
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? bio,
    File? photo, // null = tidak ganti foto
  }) async {
    final uri = Uri.parse("$_baseUrl/profile");

    final token = await _storage.read(key: 'token');

    final request = http.MultipartRequest('POST', uri);

    // Header auth
    request.headers['Authorization'] = "Bearer $token";
    request.headers['Accept'] = "application/json";

    // Data text
    request.fields['name'] = name;
    if (bio != null) request.fields['bio'] = bio;

    // Upload foto jika ada
    if (photo != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "photo", photo.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print("DEBUG UPDATE STATUS: ${response.statusCode}");
    print("DEBUG UPDATE BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal update profil");
    }
  }
}