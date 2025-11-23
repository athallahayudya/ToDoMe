import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../screens/task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task)? onTaskUpdate; // Callback jika user mengedit task dari sini

  const CalendarScreen({
    Key? key, 
    required this.tasks, 
    this.onTaskUpdate
  }) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _selectedTasks = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Load tugas hari ini saat pertama buka
    _selectedTasks = _getTasksForDay(_focusedDay);
  }

  // --- LOGIKA FILTER TUGAS ---
  List<Task> _getTasksForDay(DateTime day) {
    // Filter tugas yang deadline-nya sama dengan hari yang dipilih
    return widget.tasks.where((task) {
      if (task.deadline == null) return false;
      return isSameDay(task.deadline, day);
    }).toList();
  }

  // Update list saat parent mengirim data baru (misal setelah refresh)
  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedDay != null) {
      _selectedTasks = _getTasksForDay(_selectedDay!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Tugas', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // --- 1. WIDGET KALENDER ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              
              // Style Kalender agar mirip tema aplikasimu (Ungu/Putih)
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                // Warna hari ini
                todayDecoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.5), 
                  shape: BoxShape.circle,
                ),
                // Warna hari yang dipilih
                selectedDecoration: const BoxDecoration(
                  color: Colors.purple, // Sesuaikan dengan warna primer aplikasimu
                  shape: BoxShape.circle,
                ),
                // Warna penanda tugas (titik kecil)
                markerDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),

              // Logika Seleksi
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTasks = _getTasksForDay(selectedDay);
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },

              // Logika Marker (Titik di bawah tanggal)
              eventLoader: _getTasksForDay,
            ),
          ),

          const SizedBox(height: 16),
          
          // --- 2. HEADER LIST ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Text(
                  _selectedDay == null 
                      ? "Tugas" 
                      : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDay!),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  "${_selectedTasks.length} Tugas",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // --- 3. LIST TUGAS HARIAN ---
          Expanded(
            child: _selectedTasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _selectedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _selectedTasks[index];
                    return _buildTaskItem(task);
                  },
                ),
          ),
        ],
      ),
    );
  }

  // Widget Tampilan Kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Tidak ada deadline hari ini",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Widget Item Tugas (Mirip dengan Home)
  Widget _buildTaskItem(Task task) {
    return Card(
      elevation: 0,
      color: Colors.blue[50], // Sesuaikan warna background card
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: task.statusSelesai,
          activeColor: Colors.purple,
          onChanged: (val) {
             // Opsional: Handle update status langsung disini jika diinginkan
          },
        ),
        title: Text(
          task.judul,
          style: TextStyle(
            decoration: task.statusSelesai ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          DateFormat('HH:mm').format(task.deadline!),
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Icon(
          task.isStarred ? Icons.star : Icons.star_border,
          color: task.isStarred ? Colors.amber : Colors.grey,
        ),
        onTap: () async {
          // Buka Detail
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          );
          // Refresh list jika ada perubahan (perlu callback ke parent idealnya)
          setState(() {
            _selectedTasks = _getTasksForDay(_selectedDay!);
          });
        },
      ),
    );
  }
}