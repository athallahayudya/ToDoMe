import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category; 
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

  // --- HELPER ---
  Future<Map<String, String>> _getHeaders({bool needsAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json', // <--- INI NYAWA-NYA (WAJIB ADA)
      'Accept': 'application/json',       // <--- INI JUGA
    };
    
    if (needsAuth) {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- AUTH ---
  
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: await _getHeaders(needsAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      // SKENARIO 1: BERHASIL (200)
      if (response.statusCode == 200) {
        String? token = data['token'] ?? data['access_token'];
        if (token != null) {
          await _storage.write(key: 'token', value: token);
          String userName = data['user']['name'];
          
          return {
            'success': true,
            'name': userName,
          };
        }
      } 
      
      // SKENARIO 2: EMAIL BELUM VERIFIKASI (403)
      // Laravel mengirim 403 jika belum verifikasi (sesuai kode AuthController kita)
      else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Email belum diverifikasi. Silakan cek inbox email Anda.'
        };
      }

      // SKENARIO 3: PASSWORD SALAH (401)
      else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Email atau Password salah.'
        };
      }

      // SKENARIO LAIN (Error Server dll)
      return {
        'success': false,
        'message': data['message'] ?? 'Terjadi kesalahan pada server.'
      };

    } catch (e) {
      print("Error login: $e");
      return {
        'success': false,
        'message': 'Gagal terhubung ke internet.'
      };
    }
  }

  Future<bool> register(String name, String email, String password) async {
    print("DEBUG: Mencoba Register...");
    print("DEBUG: Data -> Name: $name, Email: $email"); // Cek di console apakah datanya ada?

    try {
      final url = Uri.parse('$_baseUrl/register');
      
      // Ambil header
      final headers = await _getHeaders(needsAuth: false);
      
      // Bungkus data
      final body = jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      final response = await http.post(
        url,
        headers: headers, // Pastikan header dikirim
        body: body,       // Pastikan body dikirim
      );

      print("DEBUG: Response Code: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        // Jika error, print isinya biar kita tahu kenapa
        print("DEBUG: ERROR REGISTER BACKEND: ${response.body}");
        return false;
      }
    } catch (e) {
      print("DEBUG: Error koneksi register: $e");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: await _getHeaders(),
      );
    } catch (e) {
      print("Error logout server: $e");
    }
    await _storage.delete(key: 'token');
  }

  // --- GOOGLE LOGIN CHECK (UPDATE PENTING) ---
  Future<Map<String, dynamic>> googleLoginCheck(String email, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: await _getHeaders(needsAuth: false),
        body: jsonEncode({'email': email, 'name': name}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'exists') {
          String? token = data['token'];
          await _storage.write(key: 'token', value: token);
          
          // Ambil nama asli dari Database untuk ditampilkan di UI
          String dbName = data['user']['name']; 
          
          return {'status': 'success', 'name': dbName}; 
        } else {
          return {'status': 'new_user'};
        }
      }
      return {'status': 'error', 'message': response.body};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // --- TASKS ---
  
  Future<List<Task>> getTasks() async {
    final response = await http.get(Uri.parse('$_baseUrl/tasks'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Task.fromJson(data)).toList();
    } else {
      throw Exception('Gagal memuat tugas');
    }
  }

  Future<Task> createTask({required String judul, String? deskripsi, DateTime? deadline, List<int>? categoryIds, List<String>? subtasks}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'judul': judul,
        'deskripsi': deskripsi,
        'deadline': deadline?.toIso8601String(),
        'category_ids': categoryIds, // Ubah key sesuai backend (categories/category_ids)
        'subtasks': subtasks,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal membuat tugas');
    }
  }

  Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    final response = await http.put(Uri.parse('$_baseUrl/tasks/$id'), headers: await _getHeaders(), body: jsonEncode(data));
    if (response.statusCode == 200) return Task.fromJson(jsonDecode(response.body));
    throw Exception('Gagal update tugas');
  }

  Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/tasks/$id'), headers: await _getHeaders());
    if (response.statusCode != 204) throw Exception('Gagal menghapus tugas');
  }

  // --- SUBTASKS ---
  Future<Subtask> createSubtask(int taskId, String title) async {
    final response = await http.post(Uri.parse('$_baseUrl/tasks/$taskId/subtasks'), headers: await _getHeaders(), body: jsonEncode({'title': title}));
    if (response.statusCode == 201) return Subtask.fromJson(jsonDecode(response.body));
    throw Exception('Gagal membuat subtask');
  }

  Future<Subtask> updateSubtask(int id, bool isCompleted) async {
    final response = await http.put(Uri.parse('$_baseUrl/subtasks/$id'), headers: await _getHeaders(), body: jsonEncode({'is_completed': isCompleted}));
    if (response.statusCode == 200) return Subtask.fromJson(jsonDecode(response.body));
    throw Exception('Gagal update subtask');
  }

  Future<void> deleteSubtask(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/subtasks/$id'), headers: await _getHeaders());
    if (response.statusCode != 204) throw Exception('Gagal menghapus subtask');
  }

  // --- CATEGORIES ---
  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/categories'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Category.fromJson(data)).toList();
    } else {
      throw Exception('Gagal memuat kategori');
    }
  }

  Future<Category> createCategory(String name) async {
    final response = await http.post(Uri.parse('$_baseUrl/categories'), headers: await _getHeaders(), body: jsonEncode({'name': name}));
    if (response.statusCode == 201) return Category.fromJson(jsonDecode(response.body));
    throw Exception('Gagal membuat kategori');
  }
}