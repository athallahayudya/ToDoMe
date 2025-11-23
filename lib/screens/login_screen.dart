import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import '../services/google_auth_service.dart';
import 'google_setup_screen.dart'; // Import Halaman Setup

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

// --- FUNGSI LOGIN MANUAL ---
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Panggil API (Sekarang mengembalikan Map)
        final result = await _apiService.login(
          _emailController.text,
          _passwordController.text,
        );

        // Cek Status Sukses/Gagal
        if (result['success'] == true) {
          // --- SUKSES ---
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selamat datang, ${result['name']}!'),
                backgroundColor: Colors.blue,
              ),
            );

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        } else {
          // --- GAGAL (Tampilkan Pesan Spesifik dari API) ---
          // Ini akan menampilkan "Email belum diverifikasi" jika errornya 403
          // Atau "Password salah" jika errornya 401
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Login Gagal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- FUNGSI LOGIN GOOGLE ---
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final user = await _googleAuthService.signIn();

      if (user != null) {
        // Cek ke Backend
        final result = await _apiService.googleLoginCheck(
            user.email, 
            user.displayName ?? 'User Google'
        );

        if (!mounted) return;

        if (result['status'] == 'success') {
          // USER LAMA -> Masuk Home
          // Ambil nama asli dari Database (fallback ke nama Google jika null)
          final realName = result['name'] ?? user.displayName;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Selamat datang, $realName!'),
                backgroundColor: Colors.blue, // Bisa ganti warna sesuka hati
              ),
          );
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );

        } else if (result['status'] == 'new_user') {
          // USER BARU -> Buka Halaman Setup Password
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GoogleSetupScreen(
                googleEmail: user.email,
                googleName: user.displayName ?? '',
              ),
            ),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal terhubung ke server.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (error) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red));
        }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (value) => (value == null || value.isEmpty) ? 'Email tidak boleh kosong' : (!value.contains('@') ? 'Email tidak valid' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Password tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 20),
              if (!_isLoading)
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("ATAU", style: TextStyle(color: Colors.grey))), Expanded(child: Divider())]),
              const SizedBox(height: 20),
              if (!_isLoading)
                OutlinedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                  label: const Text("Masuk dengan Google", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), side: const BorderSide(color: Colors.red)),
                  onPressed: _handleGoogleSignIn,
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text('Belum punya akun? Register di sini'),
              )
            ],
          ),
        ),
      ),
    );
  }
}