import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MoodPieChart extends StatelessWidget {
  final Map<String, double> data;

  const MoodPieChart({Key? key, required this.data}) : super(key: key);

  static const Map<String, Color> _colorMap = {
    'joy': Color(0xFF4CAF50), // green
    'sadness': Color(0xFF2196F3), // blue
    'anger': Color(0xFFF44336), // red
    'anxiety': Color(0xFFFF9800), // orange
    'neutral': Color(0xFF9C27B0), // purple
  };

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No mood data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final sections = data.entries.map((e) {
      final pct = e.value;
      final color = _colorMap[e.key.toLowerCase()] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: pct,
        title: '${pct.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        const SizedBox(height: 80),
        AspectRatio(
          aspectRatio: 1.5,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: 90,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 80),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: data.keys.map((k) {
        final color = _colorMap[k.toLowerCase()] ?? Colors.grey;
        final label = k.isEmpty ? k : '${k[0].toUpperCase()}${k.substring(1)}';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}
