import 'package:flutter/material.dart' hide FilterCallback;
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart'; // Import Showcase
import 'package:todome/screens/task_detail_screen.dart';
import 'package:todome/utils/time_helper.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/subtask.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_tile.dart'; 

typedef TaskUpdateCallback = Function(Task task, Map<String, dynamic> data);

class HomeScreen extends StatelessWidget {
  final List<Task> ongoingTasks;
  final List<Task> overdueTasks;
  final List<Task> completedTasks;

  final RefreshCallback onRefresh;
  final List<Category> categories;
  final TaskFilterType currentFilterType;
  final int? selectedCategoryId;
  final FilterCallback onFilterSelected;
  final TaskUpdateCallback onUpdateTask;

  final bool isOngoingExpanded;
  final bool isOverdueExpanded;
  final bool isCompletedExpanded;
  final Function(bool) onOngoingToggled;
  final Function(bool) onOverdueToggled;
  final Function(bool) onCompletedToggled;

  // PARAMETER BARU: KUNCI SHOWCASE
  final GlobalKey? categoryShowcaseKey;

  HomeScreen({
    Key? key,
    required this.ongoingTasks,
    required this.overdueTasks,
    required this.completedTasks,
    required this.onRefresh,
    required this.categories,
    required this.currentFilterType,
    required this.selectedCategoryId,
    required this.onFilterSelected,
    required this.onUpdateTask,

    required this.isOngoingExpanded,
    required this.isOverdueExpanded,
    required this.isCompletedExpanded,
    required this.onOngoingToggled,
    required this.onOverdueToggled,
    required this.onCompletedToggled,
    
    this.categoryShowcaseKey, // Terima Kunci
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategoryChips(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: _buildTaskList(context),
          ),
        ),
      ],
    );
  }

  // Widget Filter Kategori (DIBUNGKUS SHOWCASE)
  Widget _buildCategoryChips() {
    Widget categoryList = Container(
      height: 50,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          bool isSelected;
          String label;
          if (index == 0) {
            label = "Semua";
            isSelected = currentFilterType != TaskFilterType.category;
          } else {
            final category = categories[index - 1];
            label = category.name;
            isSelected = currentFilterType == TaskFilterType.category &&
                        selectedCategoryId == category.id;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (bool selected) {
                if (index == 0) {
                  onFilterSelected(TaskFilterType.all);
                } else {
                  onFilterSelected(TaskFilterType.category,
                      categoryId: categories[index - 1].id);
                }
              },
            ),
          );
        },
      ),
    );

    // BUNGKUS DENGAN SHOWCASE JIKA KUNCI ADA
    if (categoryShowcaseKey != null) {
      return Showcase(
        key: categoryShowcaseKey!,
        title: 'Filter Kategori',
        description: 'Gunakan ini untuk memfilter tugas berdasarkan kategorinya.',
        tooltipBackgroundColor: Colors.purple,
        textColor: Colors.white,
        child: categoryList,
      );
    }

    return categoryList;
  }

  Widget _buildTaskList(BuildContext context) {
    if (ongoingTasks.isEmpty && overdueTasks.isEmpty && completedTasks.isEmpty) {
      return LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: Text('Tidak ada tugas di daftar ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
        );
      });
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        _buildTaskSection(
          context,
          'Tugas Aktif',
          ongoingTasks,
          isExpanded: isOngoingExpanded,
          onToggled: onOngoingToggled,
        ),

        _buildTaskSection(
          context,
          'Terlambat',
          overdueTasks,
          isExpanded: isOverdueExpanded,
          onToggled: onOverdueToggled,
          isOverdue: true,
        ),

        _buildTaskSection(
          context,
          'Selesai',
          completedTasks,
          isExpanded: isCompletedExpanded,
          onToggled: onCompletedToggled,
        ),
      ],
    );
  }

  Widget _buildTaskSection(
      BuildContext context, String title, List<Task> tasks,
      {required bool isExpanded,
      required Function(bool) onToggled,
      bool isOverdue = false}) {

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 3.0),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),

          title: Text(
            '$title (${tasks.length})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOverdue ? Colors.red : Colors.black,
            ),
          ),

          initiallyExpanded: isExpanded,
          onExpansionChanged: onToggled,

          childrenPadding: const EdgeInsets.only(bottom: 8.0),
          children: tasks.map((task) {
            return _buildTaskListItem(context, task);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskListItem(BuildContext context, Task task) {
    return TaskTile(
      task: task,
      onStatusChanged: (bool? newValue) {
        if (newValue == null) return;
        onUpdateTask(task, {'status_selesai': newValue});
      },
      onStarToggled: () {
        onUpdateTask(task, {'is_starred': !task.isStarred});
      },
      onTap: () async {
        final bool? dataDiperbarui = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(task: task),
          ),
        );

        if (dataDiperbarui == true) {
          onRefresh();
        }
      },
    );
  }
}