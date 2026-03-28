import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../core/theme.dart';
import '../widgets/expense_tile.dart';
import '../widgets/chart_widget.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: const Text('SpendMind'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTotalCard(provider),
                        const SizedBox(height: 24),
                        if (provider.budget > 0) _buildBudgetProgress(provider),
                        const SizedBox(height: 24),
                        if (provider.expenses.isNotEmpty) ...[
                          Text(
                            'Category Breakdown',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 16),
                          ChartWidget(categoryBreakdown: provider.categoryBreakdown),
                          const SizedBox(height: 32),
                        ],
                        Text(
                          'Recent Transactions',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (provider.expenses.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text('No expenses yet. Add one!'),
                          ),
                        );
                      }
                      if (index >= provider.expenses.length) return null;
                      
                      final expense = provider.expenses[index];
                      return ExpenseTile(expense: expense);
                    },
                    childCount: provider.expenses.isEmpty ? 1 : provider.expenses.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalCard(ExpenseProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spending',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${provider.totalMonthlySpending.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgress(ExpenseProvider provider) {
    final double percentage = provider.budget > 0 
        ? (provider.totalMonthlySpending / provider.budget).clamp(0.0, 1.0) 
        : 0.0;
    
    final bool isExceeded = provider.totalMonthlySpending > provider.budget;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        opacity: 0.05,
        color: AppTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Budget',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '\$${provider.totalMonthlySpending.toStringAsFixed(0)} / \$${provider.budget.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isExceeded ? AppTheme.error : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: AppTheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded ? AppTheme.error : AppTheme.accent,
              ),
            ),
          ),
          if (isExceeded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Budget exceeded!',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
