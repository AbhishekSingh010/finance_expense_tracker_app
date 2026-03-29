import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../core/theme.dart';
import '../widgets/chart_widget.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Widget _buildTimeframeSelector(ExpenseProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: AppTheme.glassDecoration(
        opacity: 0.1,
        color: AppTheme.surface,
        borderRadius: 30,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['daily', 'weekly', 'monthly', 'yearly'].map((tf) {
          final isSelected = provider.timeframe == tf;
          return GestureDetector(
            onTap: () {
              provider.setTimeframe(tf);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tf[0].toUpperCase() + tf.substring(1),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatistics(ExpenseProvider provider) {
    final expenses = provider.expenses;
    if (expenses.isEmpty) return const SizedBox.shrink();

    final total = provider.totalMonthlySpending;
    final avg = total / (expenses.length > 0 ? expenses.length : 1);

    // Find highest category
    final breakdown = provider.categoryBreakdown;
    String highestCat = '';
    double highestVal = 0;
    breakdown.forEach((key, value) {
      if (value > highestVal) {
        highestVal = value;
        highestCat = key;
      }
    });

    // Calculate median
    final amounts = expenses.map((e) => e.amount).toList()..sort();
    double median = 0;
    if (amounts.isNotEmpty) {
      final middle = amounts.length ~/ 2;
      if (amounts.length % 2 == 1) {
        median = amounts[middle];
      } else {
        median = (amounts[middle - 1] + amounts[middle]) / 2.0;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(
        opacity: 0.1,
        color: AppTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Mean (Avg)', '${provider.currencySymbol}${avg.toStringAsFixed(2)}'),
              _buildStatItem('Median', '${provider.currencySymbol}${median.toStringAsFixed(2)}'),
              _buildStatItem('Count', '${expenses.length}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Total', '${provider.currencySymbol}${total.toStringAsFixed(2)}'),
              _buildStatItem('Highest Cat.', highestCat),
              _buildStatItem('Max Spent', '${provider.currencySymbol}${amounts.last.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildTimeframeSelector(provider),
                      _buildStatistics(provider),
                      if (provider.expenses.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.all(24),
                          height: 250,
                          child: ChartWidget(categoryBreakdown: provider.categoryBreakdown),
                        ),
                      if (provider.expenses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'No data available for this timeframe.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      const SizedBox(height: 100), // padding for navbar
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
