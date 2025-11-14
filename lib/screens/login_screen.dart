import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Impor "Otak" kita
import 'home_screen.dart'; // Halaman tujuan
import 'register_screen.dart'; // Halaman register

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Kunci untuk mengidentifikasi Form (untuk validasi)
  final _formKey = GlobalKey<FormState>();

  // Controller untuk "mendengarkan" apa yang diketik user
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Buat satu instance dari ApiService kita
  final ApiService _apiService = ApiService();

  // Variabel untuk menampilkan loading
  bool _isLoading = false;
  // Variabel untuk state ikon mata password
  bool _isPasswordVisible = false;

  // --- FUNGSI UNTUK LOGIN ---
  Future<void> _login() async {
    // 1. Validasi form
    if (_formKey.currentState!.validate()) {
      // 2. Tampilkan loading
      setState(() {
        _isLoading = true;
      });

      // 3. Panggil API
      try {
        bool loginSuccess = await _apiService.login(
          _emailController.text,
          _passwordController.text,
        );

        // 4. Cek hasil
        if (loginSuccess) {
          // Jika sukses: Pindah ke HomeScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen()), // Hapus 'const'
          );
        } else {
          // Jika gagal: Tampilkan pesan error (Snackbar)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Gagal! Email atau Password salah.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Jika ada error (misal: Sesi habis, server mati)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // 5. Hentikan loading
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Hubungkan Form dengan kunci
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- FIELD EMAIL ---
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!value.contains('@')) {
                    return 'Email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- FIELD PASSWORD (dengan ikon mata) ---
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // Ikat ke state
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      // Update state (toggle)
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- TOMBOL LOGIN ---
              _isLoading
                  ? const CircularProgressIndicator() // Tampilkan ini saat loading
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50), // Buat tombol lebar
                      ),
                      onPressed: _login, // Panggil fungsi _login
                      child: const Text('Login'),
                    ),
              
              const SizedBox(height: 16),

              // --- TOMBOL KE REGISTER ---
              TextButton(
                onPressed: () {
                  // Pindah ke RegisterScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('Belum punya akun? Register di sini'),
              )
            ],
          ),
        ),
      ),
    );
  }
}