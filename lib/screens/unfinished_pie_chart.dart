import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class UnfinishedPieChart extends StatelessWidget {
  const UnfinishedPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Klasifikasi tugas yang belum selesai",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text("Semua"),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 45,
                sections: [
                  PieChartSectionData(
                    value: 1,
                    color: Colors.blue,
                    title: "",
                  ),
                  PieChartSectionData(
                    value: 1,
                    color: Colors.lightBlue,
                    title: "",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
