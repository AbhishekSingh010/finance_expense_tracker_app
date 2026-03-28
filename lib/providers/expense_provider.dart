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

  List<Expense> get expenses => _expenses;
  double get budget => _budget;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  String? get apiKey => _apiKey;
  bool get aiEnabled => _aiEnabled;

  double get totalMonthlySpending {
    double total = 0;
    for (var expense in _expenses) {
      // Assuming all expenses are from the current month for simplicity,
      // in a full app we'd filter by current month based on the date string
      total += expense.amount;
    }
    return total;
  }

  Map<String, double> get categoryBreakdown {
    Map<String, double> breakdown = {};
    for (var expense in _expenses) {
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
