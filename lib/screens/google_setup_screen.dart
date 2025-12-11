import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class GoogleSetupScreen extends StatefulWidget {
  final String googleEmail;
  final String googleName;

  const GoogleSetupScreen({
    Key? key,
    required this.googleEmail,
    required this.googleName,
  }) : super(key: key);

  @override
  State<GoogleSetupScreen> createState() => _GoogleSetupScreenState();
}

class _GoogleSetupScreenState extends State<GoogleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller
  late TextEditingController _nameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Isi Nama otomatis dari data Google
    _nameController = TextEditingController(text: widget.googleName);
  }

  Future<void> _completeRegistration() async {
    if (_formKey.currentState!.validate()) {
      // 1. Validasi Manual: Password vs Konfirmasi
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password dan Konfirmasi tidak cocok!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        bool success = await _apiService.register(
          _nameController.text,
          widget.googleEmail, // Email otomatis dari Google
          _passwordController.text,
        );

        if (success) {
           await _apiService.login(widget.googleEmail, _passwordController.text);

           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Akun berhasil dibuat!'), backgroundColor: Colors.green),
             );
             Navigator.of(context).pushAndRemoveUntil(
               MaterialPageRoute(builder: (_) => const MainScreen()),
               (route) => false,
             );
           }
        } else {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal membuat akun.'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lengkapi Akun")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Selamat datang!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Mengatur akun untuk: ${widget.googleEmail}", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // --- FIELD NAMA ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                 validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // --- FIELD PASSWORD BARU ---
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Buat Password Baru',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (v) => (v != null && v.length < 8) ? 'Minimal 8 karakter' : null,
              ),
              const SizedBox(height: 16),

              // --- FIELD KONFIRMASI PASSWORD ---
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Konfirmasi password wajib diisi' : null,
              ),
              
              const SizedBox(height: 30),

              // --- TOMBOL SIMPAN ---
              _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text("Simpan & Masuk"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}