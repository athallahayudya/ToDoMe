import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;

  String name = "";
  String bio = "";
  String photoUrl = "";
  
  File? newPhoto;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final api = ApiService();

    final profile = await api.getProfile();

    setState(() {
      name = profile["name"] ?? "";
      bio = profile["bio"] ?? "";
      photoUrl = profile["photo_url"] ?? "";
      _loading = false;
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        newPhoto = File(picked.path);
      });
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final api = ApiService();
    try {
      await api.updateProfile(
        name: name,
        bio: bio,
        photo: newPhoto,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diperbarui")),
      );

      Navigator.pop(context, true); // kembali ke ProfileScreen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: newPhoto != null
                          ? FileImage(newPhoto!)
                          : (photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null) as ImageProvider?,
                      child: (photoUrl.isEmpty && newPhoto == null)
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: pickImage,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Input Nama
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(
                  labelText: "Nama",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Nama tidak boleh kosong" : null,
                onChanged: (v) => name = v,
              ),

              const SizedBox(height: 16),

              // Input Bio
              TextFormField(
                initialValue: bio,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => bio = v,
              ),

              const SizedBox(height: 30),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : saveProfile,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
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
