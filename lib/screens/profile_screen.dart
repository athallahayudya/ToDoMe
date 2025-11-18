import 'package:flutter/material.dart';
import 'profile_header.dart';
import 'task_summary_cards.dart';
import 'weekly_line_chart.dart';
import 'upcoming_tasks.dart';
import 'unfinished_pie_chart.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ProfileHeader(),
              SizedBox(height: 20),

              Text("Ringkasan Tugas",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              TaskSummaryCards(),
              SizedBox(height: 16),

              WeeklyLineChart(),
              SizedBox(height: 16),

              UpcomingTasks(),
              SizedBox(height: 16),

              UnfinishedPieChart(),
            ],
          ),
        ),
      ),
    );
  }
}
