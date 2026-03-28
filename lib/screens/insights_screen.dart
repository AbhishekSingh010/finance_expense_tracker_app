import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/gemini_service.dart';
import '../core/theme.dart';
import '../widgets/chart_widget.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  _InsightsScreenState createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final GeminiService _geminiService = GeminiService();
  String _insights = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInsights();
    });
  }

  Future<void> _fetchInsights() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    if (!provider.aiEnabled) {
      setState(() {
        _insights = 'AI features are disabled. Please enable them in Settings to view insights.';
      });
      return;
    }

    if (!provider.hasApiKey) {
      setState(() {
        _insights = 'Please enter your Gemini API key in Settings to view AI insights.';
      });
      return;
    }

    if (provider.expenses.isEmpty) {
      setState(() {
        _insights = 'No expenses found. Add some expenses to get insights.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final summary = provider.categoryBreakdown;
    final insights = await _geminiService.getInsights(summary, provider.apiKey!);

    setState(() {
      _insights = insights;
      _isLoading = false;
    });
  }

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
              _fetchInsights();
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
            'Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Average', '${provider.currencySymbol}${avg.toStringAsFixed(2)}'),
              _buildStatItem('Highest', highestCat),
              _buildStatItem('Count', '${expenses.length}'),
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
        title: const Text('Insights & Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInsights,
          ),
        ],
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.insights,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'AI Financial Advisor',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Based on your spending habits',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Container(
                                padding: const EdgeInsets.all(24),
                                decoration: AppTheme.glassDecoration(
                                  opacity: 0.05,
                                  color: AppTheme.surface,
                                ),
                                child: Text(
                                  _insights,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.6,
                                  ),
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
