import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Foto Profil
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue[100],
            backgroundImage: null, // nanti ambil dari API
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // Nama & Bio
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Nama User",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Bio pengguna akan ditampilkan di sini",
                  style: TextStyle(color: Colors.grey[600]),
                ),

                TextButton(
                  onPressed: () {
                    // TODO: buka form edit profil
                  },
                  child: Text("Edit Profil"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
