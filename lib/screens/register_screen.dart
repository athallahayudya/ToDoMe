import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();

  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  
  // Variabel terpisah untuk setiap field password
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false; // <-- VARIABEL BARU

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Cek apakah password & konfirmasi password sama
      if (_passwordController.text != _passwordConfirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password dan Konfirmasi Password tidak cocok!'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Hentikan jika tidak cocok
      }

      setState(() {
        _isLoading = true;
      });

      try {
        bool registerSuccess = await _apiService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
          _passwordConfirmController.text,
        );

        if (registerSuccess) {
          // Jika sukses: Tampilkan pesan & kembali ke Login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi Berhasil! Silakan Login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Kembali ke halaman sebelumnya (Login)
        } else {
          // Gagal (kemungkinan email sudah terdaftar)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi Gagal! Email mungkin sudah digunakan.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
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
        title: const Text('Register'),
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- FIELD NAMA ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Nama tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 16),

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
                  if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                  if (!value.contains('@')) return 'Email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- FIELD PASSWORD (UTAMA) ---
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // Menggunakan var pertama
                decoration: InputDecoration(
                  labelText: 'Password (min. 8 karakter)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (value) => (value == null || value.length < 8)
                    ? 'Password minimal 8 karakter'
                    : null,
              ),
              const SizedBox(height: 16),

              // --- FIELD KONFIRMASI PASSWORD (DIPERBARUI) ---
              TextFormField(
                controller: _passwordConfirmController,
                obscureText: !_isConfirmPasswordVisible, // <-- MENGGUNAKAN VAR KEDUA
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible // <-- MENGGUNAKAN VAR KEDUA
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible), // <-- MENGGUNAKAN VAR KEDUA
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Konfirmasi password tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 24),

              // --- TOMBOL REGISTER ---
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _register,
                      child: const Text('Register'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}