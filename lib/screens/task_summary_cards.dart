import 'package:flutter/material.dart';

class TaskSummaryCards extends StatelessWidget {
  const TaskSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCard("3", "Tugas Selesai", Colors.blue[100]!),
        SizedBox(width: 12),
        _buildCard("2", "Tugas Tertunda", Colors.red[100]!),
      ],
    );
  }

  Widget _buildCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
