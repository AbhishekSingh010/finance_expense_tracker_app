import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  Future<String> getInsights(Map<String, dynamic> summary, String apiKey) async {
    final prompt = 'Analyze this spending and give financial advice, savings tips, and risks: \n${jsonEncode(summary)}';
    
    return await _makeRequest(prompt, apiKey);
  }

  Future<String> sendChatMessage(String message, Map<String, dynamic> summary, String apiKey) async {
    final prompt = 'You are a financial advisor for the app SpendMind. You MUST ONLY answer questions related to the user\'s expenses and financial summary. If the user asks about anything else, politely decline and say you can only discuss their finances.\n\nUser financial summary: ${jsonEncode(summary)}\n\nUser: $message\n\nAI:';
    
    return await _makeRequest(prompt, apiKey);
  }

  Future<String> _makeRequest(String prompt, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String text = data['candidates'][0]['content']['parts'][0]['text'];
        return text;
      } else {
        return 'Error: Failed to fetch insights (${response.statusCode})';
      }
    } catch (e) {
      return 'Error: Network or processing error occurred - $e';
    }
  }
}
