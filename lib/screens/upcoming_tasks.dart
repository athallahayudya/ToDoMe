import 'package:flutter/material.dart';

class UpcomingTasks extends StatelessWidget {
  const UpcomingTasks({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.calendar_today),
          SizedBox(width: 12),
          Text("Tugas Metpen", style: TextStyle(fontSize: 16)),
          Spacer(),
          Text("11–19"),
        ],
      ),
    );
  }
}
