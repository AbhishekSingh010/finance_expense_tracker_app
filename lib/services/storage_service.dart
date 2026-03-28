import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _apiKeyKey = 'gemini_api_key';
  static const _monthlyBudgetKey = 'monthly_budget';
  static const _dailyBudgetKey = 'daily_budget';
  static const _weeklyBudgetKey = 'weekly_budget';
  static const _yearlyBudgetKey = 'yearly_budget';
  static const _currencySymbolKey = 'currency_symbol';
  static const _aiEnabledKey = 'ai_enabled';

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
  }

  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }

  Future<void> saveBudget(String type, double budget) async {
    String key = _monthlyBudgetKey;
    if (type == 'daily') key = _dailyBudgetKey;
    else if (type == 'weekly') key = _weeklyBudgetKey;
    else if (type == 'yearly') key = _yearlyBudgetKey;
    await _storage.write(key: key, value: budget.toString());
  }

  Future<double?> getBudget(String type) async {
    String key = _monthlyBudgetKey;
    if (type == 'daily') key = _dailyBudgetKey;
    else if (type == 'weekly') key = _weeklyBudgetKey;
    else if (type == 'yearly') key = _yearlyBudgetKey;
    final budgetStr = await _storage.read(key: key);
    if (budgetStr != null) {
      return double.tryParse(budgetStr);
    }
    return null;
  }

  Future<void> saveCurrencySymbol(String symbol) async {
    await _storage.write(key: _currencySymbolKey, value: symbol);
  }

  Future<String?> getCurrencySymbol() async {
    return await _storage.read(key: _currencySymbolKey);
  }

  Future<void> saveAiEnabled(bool enabled) async {
    await _storage.write(key: _aiEnabledKey, value: enabled.toString());
  }

  Future<bool> getAiEnabled() async {
    final enabledStr = await _storage.read(key: _aiEnabledKey);
    return enabledStr != 'false'; // Default to true if not set
  }
}
