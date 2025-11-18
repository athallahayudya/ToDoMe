import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyLineChart extends StatelessWidget {
  const WeeklyLineChart({super.key});

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
          Text("Penyelesaian tugas harian",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 8,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"];
                        return Text(days[value.toInt()]);
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(1, 0),
                      FlSpot(2, 0),
                      FlSpot(3, 2),
                      FlSpot(4, 0),
                      FlSpot(5, 0),
                      FlSpot(6, 1),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
