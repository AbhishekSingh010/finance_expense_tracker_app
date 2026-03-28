import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import '../data/models/expense.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final StorageService _storageService = StorageService();

  List<Expense> _expenses = [];
  double _dailyBudget = 0.0;
  double _weeklyBudget = 0.0;
  double _monthlyBudget = 0.0;
  double _yearlyBudget = 0.0;
  String _currencySymbol = '\$';
  String? _apiKey;
  bool _aiEnabled = true;
  String _timeframe = 'monthly'; // 'daily', 'weekly', 'monthly', 'yearly'

  List<Expense> get allExpenses => _expenses;
  String get timeframe => _timeframe;
  double get dailyBudget => _dailyBudget;
  double get weeklyBudget => _weeklyBudget;
  double get monthlyBudget => _monthlyBudget;
  double get yearlyBudget => _yearlyBudget;
  String get currencySymbol => _currencySymbol;

  double get currentBudget {
    switch (_timeframe) {
      case 'daily': return _dailyBudget;
      case 'weekly': return _weeklyBudget;
      case 'yearly': return _yearlyBudget;
      case 'monthly':
      default: return _monthlyBudget;
    }
  }

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  String? get apiKey => _apiKey;
  bool get aiEnabled => _aiEnabled;

  void setTimeframe(String tf) {
    _timeframe = tf;
    notifyListeners();
  }

  List<Expense> get expenses {
    final now = DateTime.now();
    return _expenses.where((expense) {
      try {
        final expenseDate = DateTime.parse(expense.date);
        if (_timeframe == 'daily') {
          return expenseDate.year == now.year && expenseDate.month == now.month && expenseDate.day == now.day;
        } else if (_timeframe == 'weekly') {
          final diff = now.difference(expenseDate).inDays;
          return diff >= 0 && diff < 7;
        } else if (_timeframe == 'yearly') {
          return expenseDate.year == now.year;
        } else { // monthly
          return expenseDate.year == now.year && expenseDate.month == now.month;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  double get totalMonthlySpending {
    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  Map<String, double> get categoryBreakdown {
    Map<String, double> breakdown = {};
    for (var expense in expenses) {
      if (breakdown.containsKey(expense.category)) {
        breakdown[expense.category] = breakdown[expense.category]! + expense.amount;
      } else {
        breakdown[expense.category] = expense.amount;
      }
    }
    return breakdown;
  }

  ExpenseProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _expenses = await _dbHelper.getExpenses();
    _dailyBudget = await _storageService.getBudget('daily') ?? 0.0;
    _weeklyBudget = await _storageService.getBudget('weekly') ?? 0.0;
    _monthlyBudget = await _storageService.getBudget('monthly') ?? 0.0;
    _yearlyBudget = await _storageService.getBudget('yearly') ?? 0.0;
    _currencySymbol = await _storageService.getCurrencySymbol() ?? '\$';
    _apiKey = await _storageService.getApiKey();
    _aiEnabled = await _storageService.getAiEnabled();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insertExpense(expense);
    await loadData();
    _checkBudgetAndNotify(expense.amount);
  }

  void _checkBudgetAndNotify(double justAdded) {
    if (_dailyBudget > 0) {
      final now = DateTime.now();
      final dailyExpenses = _expenses.where((e) {
        try {
          final ed = DateTime.parse(e.date);
          return ed.year == now.year && ed.month == now.month && ed.day == now.day;
        } catch (_) { return false; }
      }).fold(0.0, (sum, item) => sum + item.amount);

      final ratio = dailyExpenses / _dailyBudget;
      String title = 'Expense Added: $_currencySymbol${justAdded.toStringAsFixed(2)}';
      String body = 'Total daily: $_currencySymbol${dailyExpenses.toStringAsFixed(2)}';

      if (ratio >= 1.0) {
        title = '🚨 Daily Budget Exceeded!';
        body = 'You have exceeded your daily budget of $_currencySymbol${_dailyBudget.toStringAsFixed(0)}';
      } else if (ratio >= 0.8) {
        title = '⚠️ Near Daily Budget';
        body = 'You have spent ${(ratio*100).toStringAsFixed(0)}% of your daily budget';
      }

      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
      );
    } else {
      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: 'Expense Added',
        body: 'You just spent $_currencySymbol${justAdded.toStringAsFixed(2)}',
      );
    }
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    await loadData();
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    await loadData();
  }

  Future<void> setBudget(String type, double budget) async {
    await _storageService.saveBudget(type, budget);
    if (type == 'daily') _dailyBudget = budget;
    else if (type == 'weekly') _weeklyBudget = budget;
    else if (type == 'yearly') _yearlyBudget = budget;
    else _monthlyBudget = budget;
    notifyListeners();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    await _storageService.saveCurrencySymbol(symbol);
    _currencySymbol = symbol;
    notifyListeners();
  }

  Future<void> setApiKey(String apiKey) async {
    await _storageService.saveApiKey(apiKey);
    _apiKey = apiKey;
    notifyListeners();
  }

  Future<void> removeApiKey() async {
    await _storageService.deleteApiKey();
    _apiKey = null;
    notifyListeners();
  }

  Future<void> setAiEnabled(bool enabled) async {
    await _storageService.saveAiEnabled(enabled);
    _aiEnabled = enabled;
    notifyListeners();
  }
}
