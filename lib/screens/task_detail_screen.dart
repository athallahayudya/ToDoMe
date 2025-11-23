import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todome/models/category.dart';
import 'package:todome/models/subtask.dart';
import 'package:todome/models/task.dart';
import 'package:todome/services/api_service.dart';
import 'package:todome/services/calendar_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  
  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService _apiService = ApiService();
  final CalendarService _calendarService = CalendarService();
  
  // --- STATE LOKAL ---
  late Task _task; 
  bool _isDataDirty = false; 
  bool _isSyncingCalendar = false;
  
  List<Category> _allCategories = []; 
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _task = widget.task; 
    _loadCategories();
  }

  // Fungsi _loadCategories sekarang akan di-panggil ulang
  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _allCategories = categories;
        });
      }
    } catch (e) {
      _showError("Gagal memuat kategori: $e");
    }
  }

  // --- FUNGSI HELPER API (dengan update state) ---
  Future<void> _updateTaskData(Map<String, dynamic> data) async {
    try {
      final updatedTask = await _apiService.updateTask(_task.id, data);
      setState(() {
        _task = updatedTask; 
        _isDataDirty = true;
      });
    } catch (e) {
      _showError("Gagal menyimpan: $e");
    }
  }

  // --- Fungsi Pop-up Edit ---

  // 1. POP-UP EDIT JUDUL
  void _showEditJudulDialog() {
    final controller = TextEditingController(text: _task.judul);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Judul'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Judul Tugas'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updateTaskData({'judul': controller.text});
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // 2. POP-UP EDIT DESKRIPSI
  void _showEditDeskripsiDialog() {
    final controller = TextEditingController(text: _task.deskripsi);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Deskripsi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Deskripsi'),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              _updateTaskData({'deskripsi': controller.text});
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // 3. POP-UP EDIT KATEGORI (Direvisi)
  void _showEditKategoriDialog() {
    List<int> tempSelectedIds = _task.categories?.map((c) => c.id).toList() ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Kategori'),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Daftar Chip Kategori
                      Wrap(
                        spacing: 8.0,
                        children: _allCategories.map((category) {
                          final isSelected = tempSelectedIds.contains(category.id);
                          return FilterChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setDialogState(() { 
                                if (selected) {
                                  tempSelectedIds.add(category.id);
                                } else {
                                  tempSelectedIds.remove(category.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(),
                      // --- REVISI #2: Tombol Tambah Kategori ---
                      ListTile(
                        leading: const Icon(Icons.add, color: Colors.green),
                        title: const Text('Tambah Kategori Baru'),
                        onTap: () {
                          // Panggil pop-up baru di atas pop-up ini
                          _showNestedAddCategoryDialog(setDialogState);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    _updateTaskData({'category_ids': tempSelectedIds});
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FUNGSI BARU: Pop-up di dalam Pop-up ---
  void _showNestedAddCategoryDialog(StateSetter setDialogState) {
    final controller = TextEditingController();
    showDialog(
      // 'context' di sini adalah context dari 'AlertDialog' pertama
      context: context, 
      builder: (nestedContext) => AlertDialog(
        title: const Text('Kategori Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(nestedContext), // Tutup dialog nested
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              try {
                await _apiService.createCategory(controller.text);
                Navigator.pop(nestedContext); // Tutup dialog nested
                await _loadCategories(); // Muat ulang daftar kategori di halaman utama
                setDialogState(() {}); // Perbarui UI dialog pertama
              } catch (e) {
                _showError("Gagal: $e");
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }


  // 4. POP-UP EDIT DEADLINE
  void _showEditDeadlineDialog() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context, initialDate: _task.deadline ?? now,
      firstDate: now, lastDate: DateTime(2101),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(_task.deadline ?? now),
    );
    if (pickedTime == null) return;

    final newDeadline = DateTime(
      pickedDate.year, pickedDate.month, pickedDate.day,
      pickedTime.hour, pickedTime.minute,
    );
    _updateTaskData({'deadline': newDeadline.toIso8601String()});
  }

  // --- FUNGSI AKSI LANGSUNG (Tanpa Pop-up) ---
  void _toggleSelesai() {
    _updateTaskData({'status_selesai': !_task.statusSelesai});
  }

  void _deleteTask() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tugas?'),
        content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _apiService.deleteTask(_task.id);
        Navigator.of(context).pop(true); // Kirim 'true' untuk refresh
      } catch (e) { _showError("Gagal menghapus: $e"); }
    }
  }

  // --- FUNGSI SUBTUGAS (Aksi Langsung) ---
  void _addSubtask() async {
    if (_subtaskController.text.isEmpty) return;
    final title = _subtaskController.text;
    _subtaskController.clear();
    try {
      final newSubtask = await _apiService.createSubtask(_task.id, title);
      setState(() { 
        _task.subtasks?.add(newSubtask); 
        _isDataDirty = true;
      });
    } catch (e) { _showError("Gagal menambah subtask: $e"); }
  }

  void _removeSubtask(Subtask subtask) async {
    try {
      await _apiService.deleteSubtask(subtask.id);
      setState(() { 
        _task.subtasks?.removeWhere((s) => s.id == subtask.id); 
        _isDataDirty = true;
      });
    } catch (e) { _showError("Gagal menghapus subtask: $e"); }
  }

  void _toggleSubtask(Subtask subtask) async {
    try {
      final updatedSubtask = await _apiService.updateSubtask(subtask.id, !subtask.isCompleted);
      setState(() {
        final index = _task.subtasks?.indexWhere((s) => s.id == subtask.id) ?? -1;
        if (index != -1) { 
          _task.subtasks![index] = updatedSubtask; 
          _isDataDirty = true;
        }
      });
    } catch (e) { _showError("Gagal update subtask: $e"); }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- WIDGET BUILD (UI BARU) ---
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _isDataDirty); // Kirim status perubahan
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Tugas'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _isDataDirty),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red), 
              onPressed: _deleteTask,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- 1. SELESAIKAN TUGAS ---
              InkWell(
                onTap: _toggleSelesai,
                child: Row(
                  children: [
                    Checkbox(
                      value: _task.statusSelesai,
                      onChanged: (val) => _toggleSelesai(),
                    ),
                    const Text('Selesaikan Tugas', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              const Divider(height: 24),

              // --- 2. JUDUL ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.title_outlined, color: Colors.grey),
                title: const Text(
                  'Judul Tugas',
                  style: TextStyle(fontWeight: FontWeight.bold), 
                ),
                subtitle: Text(
                  _task.judul,
                  style: TextStyle(
                    fontSize: 20, 
                    color: Colors.black87,
                    decoration: _task.statusSelesai ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: const Icon(Icons.edit, size: 20, color: Colors.grey), // <-- IKON EDIT
                onTap: _showEditJudulDialog,
              ),
              const SizedBox(height: 8), 

              // --- 3. DESKRIPSI ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined, color: Colors.grey),
                title: const Text(
                  'Deskripsi',
                  style: TextStyle(fontWeight: FontWeight.bold), 
                ),
                subtitle: Text(
                  _task.deskripsi == null || _task.deskripsi!.isEmpty
                      ? 'Tambah deskripsi'
                      : _task.deskripsi!,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: _task.deskripsi == null || _task.deskripsi!.isEmpty
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
                trailing: const Icon(Icons.edit, size: 20, color: Colors.grey), // <-- IKON EDIT
                onTap: _showEditDeskripsiDialog,
              ),
              const Divider(height: 24),

              // --- 4. KATEGORI ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_outlined, color: Colors.grey),
                title: const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: (_task.categories == null || _task.categories!.isEmpty)
                    ? const Text('Atur kategori', style: TextStyle(color: Colors.grey))
                    : Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8.0,
                          children: _task.categories!
                              .map((c) => Chip(label: Text(c.name)))
                              .toList(),
                        ),
                      ),
                trailing: const Icon(Icons.edit, size: 20, color: Colors.grey), // <-- IKON EDIT
                onTap: _showEditKategoriDialog,
              ),
              const Divider(height: 24),

              // --- 5. DEADLINE ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                title: const Text('Deadline', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _task.deadline == null
                        ? 'Atur deadline'
                        : DateFormat('dd MMM yyyy, HH:mm').format(_task.deadline!.toLocal()),
                    style: TextStyle(
                      fontSize: 16,
                      color: _task.deadline == null ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                trailing: const Icon(Icons.edit, size: 20, color: Colors.grey), // <-- IKON EDIT
                onTap: _showEditDeadlineDialog,
              ),
              const Divider(height: 24),
              
              // --- 6. SUB-TUGAS ---
              const Text('Checklist Sub-tugas', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._task.subtasks?.map((subtask) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: subtask.isCompleted,
                        onChanged: (val) => _toggleSubtask(subtask),
                      ),
                      title: Text(
                        subtask.title,
                        style: TextStyle(decoration: subtask.isCompleted ? TextDecoration.lineThrough : null),
                      ),
      
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeSubtask(subtask),
                      ),
                    );
                  }) ?? [],
              
              // Form tambah subtugas
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: const InputDecoration(labelText: 'Item checklist baru...'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: _addSubtask,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}