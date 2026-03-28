import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/gemini_service.dart';
import '../core/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchInsights,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
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
              const SizedBox(height: 32),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Container(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
