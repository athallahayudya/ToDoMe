import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/subtask.dart';

class ApiService {
  // --- KONFIGURASI URL (SUDAH ONLINE) ---
  static String get _baseUrl {
    // Gunakan HTTPS untuk keamanan dan kompatibilitas Android terbaru
    // Pastikan akhiran '/api' tetap ada
    return "https://www.todome.my.id/api";
  }

  final _storage = const FlutterSecureStorage();

  // --- HELPER ---
  Future<Map<String, String>> _getHeaders({bool needsAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needsAuth) {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- FCM TOKEN ---
  Future<void> saveFcmToken(String token) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/save-fcm-token'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'fcm_token': token,
        }),
      );

      if (res.statusCode != 200) {
        print("❌ Gagal simpan FCM Token: ${res.body}");
      } else {
        print("✅ FCM Token berhasil disimpan ke server");
      }
    } catch (e) {
      print("❌ Error simpan FCM Token: $e");
    }
  }

  // --- AUTH ---

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return false;

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: await _getHeaders(),
      );

      if (res.statusCode == 200) return true;

      // kalau token invalid/hilang → hapus token
      await _storage.delete(key: 'token');
      return false;

    } catch (e) {
      await _storage.delete(key: 'token');
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: await _getHeaders(needsAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

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
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Email belum diverifikasi. Silakan cek inbox email Anda.'
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Email atau Password salah.'
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Terjadi kesalahan pada server.'
      };
    } catch (e) {
      print("Error login: $e");
      return {
        'success': false,
        'message': 'Gagal terhubung ke server.'
      };
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final url = Uri.parse('$_baseUrl/register');
      final headers = await _getHeaders(needsAuth: false);

      final body = jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
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

  // --- GOOGLE LOGIN CHECK (tetap utuh) ---
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

  // --- CHANGE PASSWORD ---
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/change-password'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Gagal ganti password: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error koneksi ganti password: $e");
      return false;
    }
  }

  // --- TASKS ---

  Future<List<Task>> getTasks() async {
    final response = await http.get(Uri.parse('$_baseUrl/tasks'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Task.fromJson(data)).toList();
    } else {
      // sertakan body server agar mudah debug
      final body = response.body;
      throw Exception('Gagal memuat tugas: ${response.statusCode} - $body');
    }
  }

  Future<Task> createTask({required String judul, String? deskripsi, DateTime? deadline, List<int>? categoryIds, List<String>? subtasks, String? recurrence}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'judul': judul,
        'deskripsi': deskripsi,
        'deadline': deadline?.toIso8601String(),
        'category_ids': categoryIds,
        'subtasks': subtasks,
        'recurrence': recurrence,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Gagal membuat tugas: ${response.statusCode} - ${response.body}');
    }
  }

  /// UPDATE TASK
  /// Banyak hosting memblokir PUT/DELETE - kita coba PUT dulu, jika gagal pakai POST + _method = PUT
  Future<Task> updateTask(int id, Map<String, dynamic> data) async {
    // First try a real PUT (some servers accept this)
    try {
      final putRes = await http.put(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );

      if (putRes.statusCode == 200) {
        return Task.fromJson(jsonDecode(putRes.body));
      }

      // If PUT returned non-200, fall through to override attempt
      // (we'll try POST override below)
    } catch (e) {
      // ignore and try override method
      print("PUT updateTask failed, will try POST override: $e");
    }

    // POST override (Laravel _method)
    final overrideBody = Map<String, dynamic>.from(data);
    overrideBody['_method'] = 'PUT';

    final postRes = await http.post(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(overrideBody),
    );

    if (postRes.statusCode == 200) {
      return Task.fromJson(jsonDecode(postRes.body));
    }

    throw Exception('Gagal update tugas: ${postRes.statusCode} - ${postRes.body}');
  }

  /// DELETE TASK
  /// Try DELETE, fallback to POST + _method=DELETE
  Future<void> deleteTask(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: await _getHeaders(),
      );

      if (res.statusCode == 200 || res.statusCode == 204 || res.statusCode == 202) {
        return;
      }

      // fallback
    } catch (e) {
      print("DELETE request failed, trying POST override: $e");
    }

    // fallback: POST _method=DELETE
    final overrideRes = await http.post(
      Uri.parse('$_baseUrl/tasks/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({'_method': 'DELETE'}),
    );

    if (overrideRes.statusCode == 200 || overrideRes.statusCode == 204 || overrideRes.statusCode == 202) {
      return;
    }

    throw Exception("Gagal menghapus tugas: ${overrideRes.statusCode} - ${overrideRes.body}");
  }

  // --- SUBTASKS ---
  Future<Subtask> createSubtask(int taskId, String title) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks/$taskId/subtasks'),
      headers: await _getHeaders(),
      body: jsonEncode({'title': title}),
    );

    if (response.statusCode == 201) return Subtask.fromJson(jsonDecode(response.body));
    throw Exception('Gagal membuat subtask: ${response.statusCode} - ${response.body}');
  }

  Future<Subtask> updateSubtask(int id, bool isCompleted) async {
    // try put
    try {
      final putRes = await http.put(
        Uri.parse('$_baseUrl/subtasks/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'is_completed': isCompleted}),
      );

      if (putRes.statusCode == 200) return Subtask.fromJson(jsonDecode(putRes.body));
    } catch (e) {
      print("PUT updateSubtask failed, will try override: $e");
    }

    // fallback: POST + _method=PUT
    final overrideRes = await http.post(
      Uri.parse('$_baseUrl/subtasks/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({'_method': 'PUT', 'is_completed': isCompleted}),
    );

    if (overrideRes.statusCode == 200) return Subtask.fromJson(jsonDecode(overrideRes.body));

    throw Exception('Gagal update subtask: ${overrideRes.statusCode} - ${overrideRes.body}');
  }

  Future<void> deleteSubtask(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/subtasks/$id'),
        headers: await _getHeaders(),
      );

      if (res.statusCode == 200 || res.statusCode == 204 || res.statusCode == 202) return;
    } catch (e) {
      print("DELETE subtask failed, will try override: $e");
    }

    final overrideRes = await http.post(
      Uri.parse('$_baseUrl/subtasks/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({'_method': 'DELETE'}),
    );

    if (overrideRes.statusCode == 200 || overrideRes.statusCode == 204 || overrideRes.statusCode == 202) return;

    throw Exception('Gagal menghapus subtask: ${overrideRes.statusCode} - ${overrideRes.body}');
  }

  // --- CATEGORIES ---
  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/categories'), headers: await _getHeaders());
    if (response.statusCode == 200) {
      List jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => Category.fromJson(data)).toList();
    } else {
      throw Exception('Gagal memuat kategori: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Category> createCategory(String name) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/categories'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201 || response.statusCode == 200) return Category.fromJson(jsonDecode(response.body));
    throw Exception('Gagal membuat kategori: ${response.statusCode} - ${response.body}');
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/categories/$id'),
        headers: await _getHeaders(),
      );

      if (res.statusCode == 200 || res.statusCode == 204 || res.statusCode == 202) return true;
    } catch (e) {
      print("DELETE category failed, will try override: $e");
    }

    final overrideRes = await http.post(
      Uri.parse('$_baseUrl/categories/$id'),
      headers: await _getHeaders(),
      body: jsonEncode({'_method': 'DELETE'}),
    );

    if (overrideRes.statusCode == 200 || overrideRes.statusCode == 204 || overrideRes.statusCode == 202) return true;

    throw Exception('Gagal menghapus kategori: ${overrideRes.statusCode} - ${overrideRes.body}');
  }

  // --- PROFILE ---
  Future<Map<String, dynamic>> getProfile() async {
    final token = await _storage.read(key: 'token');

    final res = await http.get(
      Uri.parse("$_baseUrl/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Gagal mengambil profil: ${res.statusCode} - ${res.body}");
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? bio,
    File? photo,
  }) async {
    final uri = Uri.parse("$_baseUrl/profile");
    final token = await _storage.read(key: 'token');

    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = "Bearer $token";
    request.headers['Accept'] = "application/json";

    request.fields['name'] = name;
    if (bio != null) request.fields['bio'] = bio;
    request.fields['_method'] = 'PUT';

    if (photo != null) {
      request.files.add(
        await http.MultipartFile.fromPath("photo", photo.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal update profil: ${response.body}");
    }
  }
}
