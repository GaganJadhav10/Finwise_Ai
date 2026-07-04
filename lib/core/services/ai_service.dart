import 'dart:convert';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';

/// Wraps calls to the Gemini API for expense categorization,
/// voice-to-expense parsing, and financial advisory insights.
///
/// Store your key securely (e.g. via --dart-define=GEMINI_API_KEY=xxx)
/// rather than hardcoding it in source.
class AiService {
  static const String _apiKey = "Gemini_API_Key";
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';
  final Dio _dio = DioClient.instance;

  Future<String> _generate(String prompt) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "X-goog-api-key": _apiKey,
          },
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.2},
        },
      );

      print("========== GEMINI RESPONSE ==========");
      print(response.data);
      print("=====================================");

      final candidates = response.data['candidates'] as List;
      final text = candidates.first['content']['parts'][0]['text'] as String;
      return text.trim();
    } on DioException catch (e) {
      print("========== GEMINI ERROR ==========");
      print("Status Code: ${e.response?.statusCode}");
      print("Response: ${e.response?.data}");
      print("==================================");
      rethrow;
    }
  }

  /// Classifies free text like "Swiggy 450" into one of our categories.
  Future<String> categorizeExpense(String text, List<String> categories) async {
    final prompt =
        'Classify this expense description into exactly one of these '
        'categories: ${categories.join(", ")}. '
        'Respond with ONLY the category name, nothing else.\n\n'
        'Expense: "$text"';
    try {
      final result = await _generate(prompt);
      final match = categories.firstWhere(
        (c) => result.toLowerCase().contains(c.toLowerCase()),
        orElse: () => 'Others',
      );
      return match;
    } catch (_) {
      return 'Others';
    }
  }

  /// Parses a spoken sentence like "I spent 650 rupees on dinner today"
  /// into structured expense fields.
  Future<Map<String, dynamic>> parseVoiceExpense(String speech) async {
    final prompt = '''
Extract structured expense data from this sentence and respond with STRICT
JSON only, no markdown, in this exact shape:
{"amount": number, "category": string, "description": string, "date": "YYYY-MM-DD"}

Valid categories: Food, Travel, Shopping, Entertainment, Healthcare, Bills,
Salary, Investment, Education, Others.
Use today's date (${DateTime.now().toIso8601String().split('T').first}) if no date is mentioned.

Sentence: "$speech"
''';
    try {
      final raw = await _generate(prompt);
      final cleaned =
          raw.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return {
        'amount': 0,
        'category': 'Others',
        'description': speech,
        'date': DateTime.now().toIso8601String().split('T').first,
      };
    }
  }

  /// Generates a personalized financial insight from a summary of the
  /// user's recent transactions.
  Future<String> getFinancialAdvice({
    required String question,
    required Map<String, double> categoryTotals,
    required double monthlyIncome,
    required double monthlyExpense,
  }) async {
    final breakdown = categoryTotals.entries
        .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}')
        .join(', ');
    final prompt = '''
You are a friendly personal finance advisor. Based on this month's data:
Income: ₹$monthlyIncome, Expense: ₹$monthlyExpense
Category breakdown: $breakdown

User question: "$question"

Give a concise, specific, encouraging answer (max 120 words). Use actual
numbers from the data above where relevant.
''';
    try {
      return await _generate(prompt);
    } catch (_) {
      return "I couldn't reach the AI service right now. Please check your "
          "connection and try again.";
    }
  }
}
