import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart'; // Import showcaseview
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart'; 
import 'starred_tasks_screen.dart'; 

import '../models/task.dart';
import '../models/category.dart';
import '../models/subtask.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart'; 
import '../widgets/add_task_sheet.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _categoryController = TextEditingController();

  // --- KUNCI SHOWCASE ---
  final GlobalKey _addFabKey = GlobalKey(); 
  final GlobalKey _categoryKey = GlobalKey(); 
  final GlobalKey _calendarTabKey = GlobalKey(); 
  final GlobalKey _profileTabKey = GlobalKey(); 

  int _selectedIndex = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  List<Task> _allTasks = [];
  List<Category> _allCategories = [];
  
  List<Task> _ongoingTasks = [];
  List<Task> _overdueTasks = [];
  List<Task> _completedTasks = [];

  TaskFilterType _currentFilterType = TaskFilterType.all;
  int? _selectedCategoryId;
  String _appBarTitle = 'Semua Tugas';

  bool _isKategoriExpanded = true;
  bool _isOngoingExpanded = true;
  bool _isOverdueExpanded = true;
  bool _isCompletedExpanded = false;
  
  // Variabel untuk mencegah cek berulang kali
  bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Fungsi cek tutorial
  void _checkTutorial(BuildContext context) async {
    if (_tutorialChecked) return; // Cegah pemanggilan berulang
    _tutorialChecked = true;

    final prefs = await SharedPreferences.getInstance();
    
    // GANTI KEY INI JIKA INGIN RESET TUTORIAL LAGI (misal ke v3, v4)
    bool seen = prefs.getBool('seen_full_tutorial_v2') ?? false; 

    debugPrint("🔍 [TUTORIAL] Status dilihat: $seen");

    // Jika belum pernah lihat, dan data sudah selesai loading, tampilkan showcase
    if (!seen && !_isLoading && mounted) {
      debugPrint("🚀 [TUTORIAL] Memulai Showcase...");
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
           if (mounted) {
             ShowCaseWidget.of(context).startShowCase([
               _addFabKey, 
               _categoryKey, 
               _calendarTabKey, 
               _profileTabKey
             ]);
             // Simpan status bahwa sudah dilihat
             prefs.setBool('seen_full_tutorial_v2', true);
           }
        });
      });
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        _apiService.getTasks(),
        _apiService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _allTasks = results[0] as List<Task>;
          _allCategories = results[1] as List<Category>;
        });
        _filterTasks();
      }

    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTasks() {
    if (!mounted) return;

    List<Task> tempTasks;

    setState(() {
      switch (_currentFilterType) {
        case TaskFilterType.category:
          tempTasks = _allTasks.where((task) {
            return task.categories?.any((cat) => cat.id == _selectedCategoryId) ?? false;
          }).toList();
          
          if (_selectedCategoryId != null && _allCategories.isNotEmpty) {
             try {
               final cat = _allCategories.firstWhere((c) => c.id == _selectedCategoryId);
               _appBarTitle = cat.name;
             } catch (_) {
               _appBarTitle = 'Kategori';
             }
          }
          break;
        case TaskFilterType.starred:
          tempTasks = _allTasks.where((t) => t.isStarred).toList();
          _appBarTitle = 'Bintangi Tugas';
          break;
        case TaskFilterType.all:
        default:
          tempTasks = _allTasks;
          _appBarTitle = 'Semua Tugas';
      }

      final now = DateTime.now();
      List<Task> ongoing = [];
      List<Task> overdue = [];
      List<Task> completed = [];

      for (var task in tempTasks) {
        if (task.statusSelesai) {
          completed.add(task);
        } else if (task.deadline != null && task.deadline!.isBefore(now)) {
          overdue.add(task);
        } else {
          ongoing.add(task);
        }
      }

      _ongoingTasks = ongoing;
      _overdueTasks = overdue;
      _completedTasks = completed..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  void _navigateToStarredPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StarredTasksScreen(
          allTasks: _allTasks, 
          onUpdateTask: _handleTaskUpdate,
          onRefreshData: _loadData,
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }

  void _onFilterSelected(TaskFilterType type, {int? categoryId}) {
    setState(() {
      _currentFilterType = type;
      _selectedCategoryId = categoryId;
      _selectedIndex = 0;
    });
    _filterTasks();
  }

  Future<void> _handleTaskUpdate(Task task, Map<String, dynamic> data) async {
    try {
      final updatedTask = await _apiService.updateTask(task.id, data);
      setState(() {
        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = updatedTask;
        }
      });
      _filterTasks();
    } catch (e) {
      _showError("Gagal update: $e");
    }
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AddTaskSheet(
                    categories: _allCategories,
                    onCreateCategory: (name) async {
                      try {
                        final newCat = await _apiService.createCategory(name);
                        final newCats = await _apiService.getCategories();
                        setState(() => _allCategories = newCats);
                        return newCat;
                      } catch (e) {
                        _showError(e.toString());
                        return null;
                      }
                    },
                    onSave: (judul, deskripsi, deadline, catIds, subtasks, recurrence) async {
                      try {
                        final newTask = await _apiService.createTask(
                          judul: judul,
                          deskripsi: deskripsi,
                          deadline: deadline,
                          categoryIds: catIds,
                          subtasks: subtasks,
                          recurrence: recurrence,
                        );
                        _loadData();
                        return newTask.id;
                      } catch (e) {
                        _showError(e.toString());
                        return null;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    _categoryController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header Judul ---
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        color: Colors.purple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Kategori Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // --- Input Field ---
                TextField(
                  controller: _categoryController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Nama Kategori',
                    hintText: 'Misal: Wishlist, Hobi...',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: const Icon(Icons.label_outline, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  ),
                ),

                const SizedBox(height: 32),

                // --- Tombol Aksi ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tombol Batal
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Simpan
                    ElevatedButton(
                      onPressed: () async {
                        if (_categoryController.text.isEmpty) return;
                        try {
                          Navigator.pop(context);
                          
                          // Proses simpan di background
                          await _apiService.createCategory(_categoryController.text);
                          _loadData();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kategori "${_categoryController.text}" berhasil dibuat!'),
                              backgroundColor: Colors.purple,
                            )
                          );
                        } catch (e) {
                           // Jika gagal, tampilkan error (karena dialog sudah tutup)
                          _showError(e.toString());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Simpan Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleKategori(bool isExpanded) => setState(() { _isKategoriExpanded = isExpanded; });
  void _toggleOngoing(bool isExpanded) => setState(() { _isOngoingExpanded = isExpanded; });
  void _toggleOverdue(bool isExpanded) => setState(() { _isOverdueExpanded = isExpanded; });
  void _toggleCompleted(bool isExpanded) => setState(() { _isCompletedExpanded = isExpanded; });

  @override
  Widget build(BuildContext context) {
    
    final List<Widget> widgetOptions = <Widget>[
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : HomeScreen(
                  ongoingTasks: _ongoingTasks,
                  overdueTasks: _overdueTasks,
                  completedTasks: _completedTasks,
                  onRefresh: _loadData,
                  categories: _allCategories,
                  currentFilterType: _currentFilterType,
                  selectedCategoryId: _selectedCategoryId,
                  onFilterSelected: _onFilterSelected,
                  onUpdateTask: _handleTaskUpdate,
                  isOngoingExpanded: _isOngoingExpanded,
                  isOverdueExpanded: _isOverdueExpanded,
                  isCompletedExpanded: _isCompletedExpanded,
                  onOngoingToggled: _toggleOngoing,
                  onOverdueToggled: _toggleOverdue,
                  onCompletedToggled: _toggleCompleted,
                  
                  categoryShowcaseKey: _categoryKey, 
                ),

      CalendarScreen(
        tasks: _allTasks, 
        onTaskUpdate: (_) => _loadData(),
      ),

      const ProfileScreen(), 
    ];

    return ShowCaseWidget(
      builder: (context) {
        // Cek tutorial setelah data selesai dimuat
        if (!_isLoading) {
          _checkTutorial(context);
        }

        return Scaffold(
          key: _scaffoldKey,

          appBar: AppBar(
            title: Text(
              _selectedIndex == 0 ? _appBarTitle 
              : (_selectedIndex == 1 ? 'Kalender' : 'Profil')
            ),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            actions: [
              if (_selectedIndex == 0)
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)
            ],
          ),

          drawer: AppDrawer(
            categories: _allCategories,
            allTasksCount: _allTasks.length,
            starredTasksCount: _allTasks.where((t) => t.isStarred).length,
            onFilterSelected: _onFilterSelected,
            onAddCategory: _showAddCategoryDialog,
            isKategoriExpanded: _isKategoriExpanded,
            onKategoriToggled: _toggleKategori,
            onOpenStarredPage: _navigateToStarredPage, 
            
            onDeleteCategory: (category) async {
              try {
                await _apiService.deleteCategory(category.id);
                if (_selectedCategoryId == category.id) {
                  setState(() {
                    _currentFilterType = TaskFilterType.all;
                    _selectedCategoryId = null;
                    _selectedIndex = 0;
                  });
                }
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Kategori '${category.name}' dihapus")),
                );
              } catch (e) {
                _showError("Gagal menghapus: $e");
              }
            },
          ),

          body: widgetOptions.elementAt(_selectedIndex),

          floatingActionButton: _selectedIndex == 0 
              ? Showcase(
                  key: _addFabKey,
                  title: 'Buat Tugas Baru',
                  description: 'Tekan tombol ini untuk mulai mencatat tugas.',
                  targetShapeBorder: const CircleBorder(),
                  tooltipBackgroundColor: Colors.purple,
                  textColor: Colors.white,
                  child: FloatingActionButton(
                    onPressed: _showAddTaskSheet,
                    tooltip: 'Tambah Tugas',
                    backgroundColor: Colors.purple[100], 
                    child: const Icon(Icons.add, color: Colors.purple),
                  ),
                )
              : null,

          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Tugas',
              ),
              NavigationDestination(
                icon: Showcase(
                  key: _calendarTabKey,
                  title: 'Kalender',
                  description: 'Lihat deadline tugasmu dalam tampilan kalender.',
                  tooltipBackgroundColor: Colors.purple,
                  textColor: Colors.white,
                  targetShapeBorder: const CircleBorder(),
                  child: const Icon(Icons.calendar_month_outlined),
                ),
                selectedIcon: const Icon(Icons.calendar_month),
                label: 'Kalender',
              ),
              NavigationDestination(
                icon: Showcase(
                  key: _profileTabKey,
                  title: 'Profil',
                  description: 'Atur akun, ganti password, dan lihat statistikmu.',
                  tooltipBackgroundColor: Colors.purple,
                  textColor: Colors.white,
                  targetShapeBorder: const CircleBorder(),
                  child: const Icon(Icons.person_outline),
                ),
                selectedIcon: const Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }
}