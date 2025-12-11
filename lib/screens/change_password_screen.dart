import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // --- STATE UNTUK VISIBILITAS PASSWORD ---
  bool _isOldPassVisible = false;
  bool _isNewPassVisible = false;
  bool _isConfirmPassVisible = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_newPassController.text != _confirmPassController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password baru tidak cocok")));
        return;
      }

      setState(() => _isLoading = true);
      final success = await _apiService.changePassword(
        _oldPassController.text,
        _newPassController.text,
      );
      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password berhasil diubah")));
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal mengubah password. Cek password lama.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ganti Password")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Password Lama
              TextFormField(
                controller: _oldPassController,
                obscureText: !_isOldPassVisible, // Gunakan variabel state
                decoration: InputDecoration(
                  labelText: "Password Lama",
                  // Tambahkan Ikon Mata
                  suffixIcon: IconButton(
                    icon: Icon(_isOldPassVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isOldPassVisible = !_isOldPassVisible;
                      });
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Harus diisi" : null,
              ),
              const SizedBox(height: 16),

              // 2. Password Baru
              TextFormField(
                controller: _newPassController,
                obscureText: !_isNewPassVisible, // Gunakan variabel state
                decoration: InputDecoration(
                  labelText: "Password Baru (Min 8)",
                  // Tambahkan Ikon Mata
                  suffixIcon: IconButton(
                    icon: Icon(_isNewPassVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isNewPassVisible = !_isNewPassVisible;
                      });
                    },
                  ),
                ),
                validator: (v) => v!.length < 8 ? "Minimal 8 karakter" : null,
              ),
              const SizedBox(height: 16),

              // 3. Konfirmasi Password Baru
              TextFormField(
                controller: _confirmPassController,
                obscureText: !_isConfirmPassVisible, // Gunakan variabel state
                decoration: InputDecoration(
                  labelText: "Ulangi Password Baru",
                  // Tambahkan Ikon Mata
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPassVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isConfirmPassVisible = !_isConfirmPassVisible;
                      });
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? "Harus diisi" : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const Text("Menyimpan...") : const Text("Simpan"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}