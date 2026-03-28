import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _apiKeyKey = 'gemini_api_key';
  static const _budgetKey = 'monthly_budget';
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

  Future<void> saveBudget(double budget) async {
    await _storage.write(key: _budgetKey, value: budget.toString());
  }

  Future<double?> getBudget() async {
    final budgetStr = await _storage.read(key: _budgetKey);
    if (budgetStr != null) {
      return double.tryParse(budgetStr);
    }
    return null;
  }

  Future<void> saveAiEnabled(bool enabled) async {
    await _storage.write(key: _aiEnabledKey, value: enabled.toString());
  }

  Future<bool> getAiEnabled() async {
    final enabledStr = await _storage.read(key: _aiEnabledKey);
    return enabledStr != 'false'; // Default to true if not set
  }
}
