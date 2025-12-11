import 'package:flutter/material.dart';
import '../models/category.dart';

// Enum Filter
enum TaskFilterType { all, starred, category }

// Callback Filter
typedef FilterCallback = void Function(TaskFilterType type, {int? categoryId});

class AppDrawer extends StatelessWidget {
  final List<Category> categories;
  final int allTasksCount;
  final int starredTasksCount;
  
  final FilterCallback onFilterSelected;
  final VoidCallback onAddCategory;
  final VoidCallback onOpenStarredPage;
  
  // --- CALLBACK BARU UNTUK HAPUS ---
  final Function(Category) onDeleteCategory; 

  final bool isKategoriExpanded;
  final Function(bool) onKategoriToggled;

  const AppDrawer({
    Key? key,
    required this.categories,
    required this.allTasksCount,
    required this.starredTasksCount,
    required this.onFilterSelected,
    required this.onAddCategory,
    required this.onOpenStarredPage,
    required this.isKategoriExpanded,
    required this.onKategoriToggled,
    // --- WAJIB DIISI ---
    required this.onDeleteCategory, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF9C27B0),
                        Color(0xFF6A1B9A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  right: -10,
                  top: 10,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 110,
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "To Do Me",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Atur semua tugasmu",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),


          // MENU BINTANG
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Tugas Berbintang'),
            trailing: Text(starredTasksCount.toString()),
            onTap: () {
              Navigator.pop(context);
              onOpenStarredPage();
            },
          ),

          const Divider(),

          // MENU KATEGORI
          ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: const Icon(Icons.category),
            title: const Text('Kategori'),
            initiallyExpanded: isKategoriExpanded,
            onExpansionChanged: onKategoriToggled,
            children: [
              // PILIHAN "SEMUA"
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                leading: const Icon(Icons.all_inbox_outlined),
                title: const Text('Semua'),
                trailing: Text(allTasksCount.toString()),
                onTap: () {
                  onFilterSelected(TaskFilterType.all);
                  Navigator.pop(context);
                },
              ),
              
              // --- LIST KATEGORI (MODIFIKASI DISINI) ---
              ...categories.map((category) {
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 32.0, right: 8.0), // Padding kanan dikecilkan
                  leading: const Icon(Icons.label_outline),
                  title: Text(category.name),
                  
                  // GANTI TRAILING JADI ROW (ANGKA + TOMBOL HAPUS)
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Agar tidak mengambil semua ruang
                    children: [
                      Text(category.tasksCount.toString()), // Jumlah tugas
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        tooltip: "Hapus Kategori",
                        onPressed: () {
                          // Panggil dialog konfirmasi
                          _showDeleteConfirmDialog(context, category);
                        },
                      ),
                    ],
                  ),
                  
                  onTap: () {
                    onFilterSelected(TaskFilterType.category, categoryId: category.id);
                    Navigator.pop(context);
                  },
                );
              }).toList(),

              // TOMBOL TAMBAH KATEGORI
              ListTile(
                contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('Tambah Kategori', style: TextStyle(color: Colors.green)),
                onTap: () {
                  Navigator.pop(context);
                  onAddCategory();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Dialog Konfirmasi Hapus (Penting agar tidak kepencet)
  void _showDeleteConfirmDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Kategori?"),
        content: Text("Apakah Anda yakin ingin menghapus kategori '${category.name}'? Tugas di dalamnya mungkin ikut terhapus atau kehilangan kategori."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              onDeleteCategory(category); // Jalankan aksi hapus
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}