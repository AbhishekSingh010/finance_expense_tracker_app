import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _dailyBudgetController = TextEditingController();
  final _weeklyBudgetController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();
  final _yearlyBudgetController = TextEditingController();
  String _selectedCurrency = '\$';

  final List<String> _currencies = ['\$', '₹', '€', '£', '¥'];

  bool _isApiVisible = false;
  bool _aiEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (provider.apiKey != null) {
        _apiKeyController.text = provider.apiKey!;
      }

      _dailyBudgetController.text = provider.dailyBudget > 0 ? provider.dailyBudget.toStringAsFixed(0) : '';
      _weeklyBudgetController.text = provider.weeklyBudget > 0 ? provider.weeklyBudget.toStringAsFixed(0) : '';
      _monthlyBudgetController.text = provider.monthlyBudget > 0 ? provider.monthlyBudget.toStringAsFixed(0) : '';
      _yearlyBudgetController.text = provider.yearlyBudget > 0 ? provider.yearlyBudget.toStringAsFixed(0) : '';

      _selectedCurrency = provider.currencySymbol;
      if (!_currencies.contains(_selectedCurrency)) {
        _currencies.add(_selectedCurrency);
      }
      _aiEnabled = provider.aiEnabled;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _dailyBudgetController.dispose();
    _weeklyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    _yearlyBudgetController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    
    if (_apiKeyController.text.isNotEmpty) {
      provider.setApiKey(_apiKeyController.text);
    } else {
      provider.removeApiKey();
    }

    final dailyBudget = double.tryParse(_dailyBudgetController.text) ?? 0.0;
    provider.setBudget('daily', dailyBudget);

    final weeklyBudget = double.tryParse(_weeklyBudgetController.text) ?? 0.0;
    provider.setBudget('weekly', weeklyBudget);

    final monthlyBudget = double.tryParse(_monthlyBudgetController.text) ?? 0.0;
    provider.setBudget('monthly', monthlyBudget);

    final yearlyBudget = double.tryParse(_yearlyBudgetController.text) ?? 0.0;
    provider.setBudget('yearly', yearlyBudget);

    provider.setCurrencySymbol(_selectedCurrency);
    
    provider.setAiEnabled(_aiEnabled);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Goals',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassDecoration(
                    opacity: 0.05,
                    color: AppTheme.surface,
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Currency Symbol',
                          prefixIcon: Icon(Icons.money, color: AppTheme.textSecondary),
                        ),
                        dropdownColor: AppTheme.surface,
                        items: _currencies.map((String symbol) {
                          return DropdownMenuItem(
                            value: symbol,
                            child: Text(symbol),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            if (newValue != null) {
                              _selectedCurrency = newValue;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dailyBudgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Daily Budget',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(_selectedCurrency, style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                          ),
                          hintText: 'e.g. 50',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _weeklyBudgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Weekly Budget',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(_selectedCurrency, style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                          ),
                          hintText: 'e.g. 350',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _monthlyBudgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Monthly Budget',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(_selectedCurrency, style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                          ),
                          hintText: 'e.g. 1500',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _yearlyBudgetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Yearly Budget',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(_selectedCurrency, style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                          ),
                          hintText: 'e.g. 18000',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'AI Integration',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your financial data stays on-device. Only aggregated summaries are sent to Gemini for insights.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
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
                          const Text('Enable AI Features:'),
                          Switch(
                            value: _aiEnabled,
                            onChanged: (value) {
                              setState(() {
                                _aiEnabled = value;
                              });
                            },
                            activeColor: AppTheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AI Insights Status:'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: provider.hasApiKey 
                                  ? AppTheme.success.withOpacity(0.2)
                                  : AppTheme.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              provider.hasApiKey ? 'Connected' : 'Not Connected',
                              style: TextStyle(
                                color: provider.hasApiKey ? AppTheme.success : AppTheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _apiKeyController,
                        obscureText: !_isApiVisible,
                        decoration: InputDecoration(
                          labelText: 'Gemini API Key',
                          prefixIcon: const Icon(Icons.key, color: AppTheme.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isApiVisible ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isApiVisible = !_isApiVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Link to get API key
                          },
                          child: const Text(
                            'Get API Key',
                            style: TextStyle(color: AppTheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
