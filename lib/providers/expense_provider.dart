import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import '../data/models/expense.dart';
import '../services/storage_service.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final StorageService _storageService = StorageService();

  List<Expense> _expenses = [];
  double _budget = 0.0;
  String? _apiKey;
  bool _aiEnabled = true;
  String _timeframe = 'monthly'; // 'daily', 'weekly', 'monthly'

  List<Expense> get allExpenses => _expenses;
  String get timeframe => _timeframe;
  double get budget => _budget;
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
        } else {
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
    _budget = await _storageService.getBudget() ?? 0.0;
    _apiKey = await _storageService.getApiKey();
    _aiEnabled = await _storageService.getAiEnabled();
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _dbHelper.insertExpense(expense);
    await loadData();
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.updateExpense(expense);
    await loadData();
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    await loadData();
  }

  Future<void> setBudget(double budget) async {
    await _storageService.saveBudget(budget);
    _budget = budget;
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
