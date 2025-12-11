import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import 'change_password_screen.dart'; // 1. IMPORT SCREEN GANTI PASSWORD

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentBio;
  final String currentPhotoUrl;

  const EditProfileScreen({
    Key? key,
    this.currentName = "",
    this.currentBio = "",
    this.currentPhotoUrl = "",
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  bool _saving = false;
  File? _newPhoto;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _bioController = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); 
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        imageQuality: 80, 
      );

      if (picked != null) {
        setState(() {
          _newPhoto = File(picked.path);
        });
      }
    } catch (e) {
      print("Gagal ambil gambar: $e");
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Ambil dari Galeri'),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.purple),
                title: const Text('Ambil dari Kamera'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final api = ApiService();
    try {
      await api.updateProfile(
        name: _nameController.text,
        bio: _bioController.text,
        photo: _newPhoto,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui")),
      );

      Navigator.pop(context, true);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_newPhoto != null) {
      imageProvider = FileImage(_newPhoto!);
    } else if (widget.currentPhotoUrl.isNotEmpty) {
      imageProvider = NetworkImage(widget.currentPhotoUrl);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- FOTO PROFIL ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: imageProvider,
                      child: (imageProvider == null)
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showPickerOptions,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.purple, // Sesuaikan warna tema
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- INPUT NAMA ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Lengkap",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),

              const SizedBox(height: 16),

              // --- INPUT BIO ---
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Bio Singkat",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),

              const SizedBox(height: 20),

              // 2. TOMBOL TEKS GANTI PASSWORD (BARU)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    // Navigasi ke screen ChangePassword
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple, // Warna teks
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Agar area klik pas
                  ),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text(
                    "Ganti Password",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saving ? null : saveProfile,
                  child: _saving
                      ? const SizedBox(
                          height: 24, width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text("Simpan Perubahan"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}