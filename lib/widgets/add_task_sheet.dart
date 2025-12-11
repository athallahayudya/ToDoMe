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

  // --- TAMBAHAN: Helper untuk gaya Input Field ungu & rounded ---
  InputDecoration _buildInputDecoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: Icon(icon, color: Colors.purple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.purple, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

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
    return Padding(
      // Padding ini memastikan pop-up naik saat keyboard muncul
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
        left: 24, 
        right: 24, 
        top: 24
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. HEADER BARU (Ikon Ungu + Judul) ---
          // Menggantikan garis handle bar lama
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.task_alt_rounded, color: Colors.purple, size: 28),
              ),
              const SizedBox(width: 16),
              const Text(
                'Tugas Baru',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Area Scrollable agar konten muat banyak
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. INPUT JUDUL (Gaya Baru) ---
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    // Pakai helper dekorasi baru
                    decoration: _buildInputDecoration('Judul Tugas', Icons.title, hint: 'Apa yang ingin dikerjakan?'),
                  ),
                  
                  const SizedBox(height: 16),

                  // --- 3. INPUT DESKRIPSI (Gaya Baru) ---
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: _buildInputDecoration('Deskripsi', Icons.notes, hint: 'Detail tugas (opsional)'),
                  ),

                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),

                  // --- 4. SUBTASKS (Logika Tetap, Tampilan Lebih Rapi) ---
                  if (_subtasks.isNotEmpty) ...[
                    const Text('Sub-tugas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subtasks.length,
                      itemBuilder: (ctx, index) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle_outline, size: 20, color: Colors.grey),
                          title: Text(_subtasks[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            onPressed: () => _removeSubtask(index),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Input Subtask
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            hintText: "Tambah item checklist...",
                            border: InputBorder.none,
                            icon: Icon(Icons.add_task, color: Colors.purple),
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.purple), onPressed: _addSubtask)
                    ],
                  ),
                  
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),

                  // --- 5. KATEGORI (Logika Chip Tetap) ---
                  const Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: const Text("Baru"),
                          backgroundColor: Colors.purple,
                          labelStyle: const TextStyle(color: Colors.white),
                          onPressed: _showAddCategoryDialog,
                        ),
                        const SizedBox(width: 8),
                        ..._localCategories.map((cat) {
                          final isSelected = _selectedCategoryIds.contains(cat.id);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              selectedColor: Colors.purple[100],
                              checkmarkColor: Colors.purple,
                              labelStyle: TextStyle(color: isSelected ? Colors.purple : Colors.black),
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

                  const SizedBox(height: 16),

                  // --- 6. TANGGAL & OPSI LAIN ---
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

                  const SizedBox(height: 12),

                  // Recurrence Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                       border: Border.all(color: Colors.grey[300]!),
                       borderRadius: BorderRadius.circular(8)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRecurrence,
                        icon: const Icon(Icons.repeat, color: Colors.purple, size: 20),
                        items: _recurrenceOptions.map((opt) {
                          return DropdownMenuItem(value: opt['value'], child: Text(opt['label']!));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRecurrence = val);
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- 7. TOMBOL SIMPAN (Gaya Baru) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: () async {
                   // Logika simpan lama kamu, copy paste dari tombol lama jika perlu,
                   // atau gunakan yang ini (sudah disesuaikan dengan variabelmu)
                   if (_titleController.text.isNotEmpty) {
                      final int? newTaskId = await widget.onSave(
                        _titleController.text, 
                        _descController.text, 
                        _selectedDate, 
                        _selectedCategoryIds, 
                        _subtasks,
                        _selectedRecurrence
                      );
                      
                      if (newTaskId != null && _selectedDate != null) {
                        await NotificationService().scheduleTaskNotifications(
                          newTaskId, 
                          _titleController.text, 
                          _selectedDate!
                        );
                      }
                      if (mounted) Navigator.pop(context);
                   }
                },
                child: const Text('Simpan Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
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