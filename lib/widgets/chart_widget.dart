import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';

class ChartWidget extends StatelessWidget {
  final Map<String, double> categoryBreakdown;

  const ChartWidget({Key? key, required this.categoryBreakdown}) : super(key: key);

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'travel':
        return Colors.blue;
      case 'bills':
        return Colors.red;
      case 'shopping':
        return Colors.purple;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categoryBreakdown.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('No data for chart', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    double total = categoryBreakdown.values.fold(0, (sum, amount) => sum + amount);

    List<PieChartSectionData> sections = [];
    int i = 0;
    categoryBreakdown.forEach((category, amount) {
      final isTouched = false; // Could add state for interactivity
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final percentage = (amount / total * 100).toStringAsFixed(1);

      sections.add(
        PieChartSectionData(
          color: _getColorForCategory(category),
          value: amount,
          title: '$percentage%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        opacity: 0.1,
        color: AppTheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categoryBreakdown.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorForCategory(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
