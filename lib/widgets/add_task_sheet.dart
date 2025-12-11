import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../services/notification_service.dart';

class AddTaskSheet extends StatefulWidget {
  final List<Category> categories;
  // Callback onSave sekarang menerima subtasks juga
  final Future<int?> Function(
    String judul, 
    String deskripsi, 
    DateTime? deadline, 
    List<int> catIds, 
    List<String> subtasks, 
    String recurrence
  ) onSave;
  
  final Future<Category?> Function(String) onCreateCategory;

  const AddTaskSheet({
    Key? key, 
    required this.categories, 
    required this.onSave, 
    required this.onCreateCategory
  }) : super(key: key);

  @override
  _AddTaskSheetState createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskController = TextEditingController();
  
  DateTime? _selectedDate;
  List<int> _selectedCategoryIds = [];
  List<String> _subtasks = []; // Menyimpan list subtask sementara
  
  // List lokal untuk menampung kategori agar update UI instan
  List<Category> _localCategories = [];

  // Variabel untuk opsi Berulang
  String _selectedRecurrence = 'none';
  final List<Map<String, String>> _recurrenceOptions = [
    {'value': 'none', 'label': 'Tidak Berulang'},
    {'value': 'daily', 'label': 'Setiap Hari'},
    {'value': 'weekly', 'label': 'Setiap Minggu'},
    {'value': 'monthly', 'label': 'Setiap Bulan'},
    {'value': 'yearly', 'label': 'Setiap Tahun'},
  ];

  @override
  void initState() {
    super.initState();
    // Salin data kategori dari parent ke list lokal saat pertama dibuka
    _localCategories = List.from(widget.categories);
  }

  // --- LOGIKA TANGGAL & WAKTU ---
  void _setDate(int daysToAdd) {
    final now = DateTime.now();
    setState(() {
      if (daysToAdd == 0) {
        // HARI INI: Set ke jam 23:59:59 (Akhir Hari)
        _selectedDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (daysToAdd == 1) {
        // BESOK: Set ke jam 23:59:59 juga (Biasanya deadline itu akhir hari)
        final tmr = now.add(const Duration(days: 1));
        _selectedDate = DateTime(tmr.year, tmr.month, tmr.day, 23, 59, 59);
      }
    });
  }

  // Pilih Tanggal & Jam Custom (Mirip add_task_screen)
  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    // 1. Pilih Tanggal
    final pickedDate = await showDatePicker(
      context: context, 
      initialDate: _selectedDate ?? now, 
      firstDate: now, 
      lastDate: DateTime(2100)
    );
    
    if (pickedDate != null) {
      // 2. Pilih Jam (Langsung muncul setelah pilih tanggal agar praktis)
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute
          );
        });
      }
    }
  }

  // --- LOGIKA SUBTASK ---
  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(_subtaskController.text);
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  // --- LOGIKA KATEGORI ---
  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kategori Baru"),
        content: TextField(controller: catController, decoration: const InputDecoration(hintText: "Nama Kategori")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (catController.text.isNotEmpty) {
                // Panggil API create di parent & tunggu hasilnya
                final newCategory = await widget.onCreateCategory(catController.text);
                
                // Jika sukses, tambahkan ke list lokal agar langsung muncul
                if (newCategory != null) {
                  setState(() {
                    _localCategories.add(newCategory);
                    _selectedCategoryIds.add(newCategory.id); // Auto select
                  });
                }
                Navigator.pop(ctx);
              }
            }, 
            child: const Text("Simpan")
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan DraggableScrollableSheet atau SingleChildScrollView agar bisa scroll
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Menghindari Keyboard
        left: 16, right: 16, top: 12
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           // Handle Bar (Garis kecil di atas)
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),

          // AREA SCROLLABLE (Agar muat banyak konten)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. JUDUL
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: "Apa yang ingin dikerjakan?", 
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    autofocus: true, 
                  ),
                  
                  // 2. DESKRIPSI
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      hintText: "Deskripsi (opsional)", 
                      border: InputBorder.none, 
                      icon: Icon(Icons.description_outlined, size: 20, color: Colors.grey)
                    ),
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const Divider(),

                  // 3. SUBTASKS (Baru ditambahkan)
                  if (_subtasks.isNotEmpty) ...[
                    const Text('Sub-tugas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subtasks.length,
                      itemBuilder: (ctx, index) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_box_outline_blank, size: 18),
                        title: Text(_subtasks[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => _removeSubtask(index),
                        ),
                      ),
                    ),
                  ],
                  // Input Subtask Baru
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            hintText: "Tambah item checklist...",
                            border: InputBorder.none,
                            icon: Icon(Icons.checklist, size: 20, color: Colors.grey),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onSubmitted: (_) => _addSubtask(), // Tekan enter untuk tambah
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.blue),
                        onPressed: _addSubtask,
                      )
                    ],
                  ),
                  const Divider(),

                  // 4. KATEGORI
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.blue), 
                          onPressed: _showAddCategoryDialog,
                        ),
                        ..._localCategories.map((cat) {
                          final isSelected = _selectedCategoryIds.contains(cat.id);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              selectedColor: Colors.blue[100],
                              onSelected: (val) {
                                setState(() {
                                  val ? _selectedCategoryIds.add(cat.id) : _selectedCategoryIds.remove(cat.id);
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. TANGGAL & WAKTU (Shortcut + Custom)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDateChip("Hari Ini", Icons.today, 0),
                        const SizedBox(width: 8),
                        _buildDateChip("Besok", Icons.wb_sunny_outlined, 1),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: Text(_selectedDate == null 
                            ? "Pilih Waktu" 
                            : DateFormat("dd MMM, HH:mm").format(_selectedDate!)
                          ),
                          avatar: const Icon(Icons.calendar_month, size: 16),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          onPressed: _pickCustomDate,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 6. PILIHAN BERULANG (RECURRENCE)
                  Row(
                    children: [
                      const Icon(Icons.repeat, color: Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: _selectedRecurrence,
                        underline: Container(), // Hilangkan garis bawah
                        items: _recurrenceOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt['value'], 
                            child: Text(opt['label']!)
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRecurrence = val);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 7. TOMBOL SIMPAN (Sticky di bawah)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)
              ),
              onPressed: () async {
                if (_titleController.text.isNotEmpty) {
                  
                  // 1. Simpan ke Backend dan TUNGGU return ID Task
                  final int? newTaskId = await widget.onSave(
                    _titleController.text, 
                    _descController.text, 
                    _selectedDate, 
                    _selectedCategoryIds, 
                    _subtasks,
                    _selectedRecurrence // <-- Data baru
                  );
                  
                  // 2. JADWALKAN NOTIFIKASI (Jika sukses simpan & ada deadline)
                  if (newTaskId != null && _selectedDate != null) {
                    await NotificationService().scheduleTaskNotifications(
                      newTaskId, 
                      _titleController.text, 
                      _selectedDate!
                    );
                  }
                  
                  // 3. Tutup Sheet jika masih terpasang (mounted)
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text("Simpan Tugas", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, IconData icon, int days) {
    bool isSelected = false;
    if (_selectedDate != null) {
      final now = DateTime.now();
      final target = days == 0 ? now : now.add(const Duration(days: 1));
      isSelected = _selectedDate!.day == target.day && _selectedDate!.month == target.month;
    }

    return ActionChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
      backgroundColor: isSelected ? Colors.blue : Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      side: BorderSide(color: isSelected ? Colors.blue : Colors.grey.shade300),
      onPressed: () => _setDate(days),
    );
  }
}