import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ai_service.dart';
import '../../core/widgets/gradient_button.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';

class VoiceEntryScreen extends ConsumerStatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  ConsumerState<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends ConsumerState<VoiceEntryScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AiService _aiService = AiService();

  bool _isListening = false;
  bool _isParsing = false;
  String _transcript = '';
  Map<String, dynamic>? _parsedExpense;

  Future<void> _startListening() async {
    debugPrint("🎤 Mic button pressed");

    final available = await _speech.initialize(
      onStatus: (status) {
        debugPrint("Speech Status: $status");
      },
      onError: (error) {
        debugPrint("Speech Error: $error");
      },
    );

    debugPrint("Speech Available: $available");

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Speech recognition is not available"),
          ),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _transcript = '';
      _parsedExpense = null;
    });

    await _speech.listen(
      localeId: "en_IN",
      partialResults: true,
      onResult: (result) {
        debugPrint("Recognized: ${result.recognizedWords}");

        setState(() {
          _transcript = result.recognizedWords;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (_transcript.trim().isEmpty) return;

    setState(() => _isParsing = true);
    final parsed = await _aiService.parseVoiceExpense(_transcript);
    setState(() {
      _parsedExpense = parsed;
      _isParsing = false;
    });
  }

  Future<void> _confirmAndSave() async {
    if (_parsedExpense == null) return;
    final expense = ExpenseModel(
      id: const Uuid().v4(),
      amount: (_parsedExpense!['amount'] as num).toDouble(),
      category: _parsedExpense!['category'] ?? 'Others',
      date: DateTime.tryParse(_parsedExpense!['date'] ?? '') ?? DateTime.now(),
      description: _parsedExpense!['description'] ?? _transcript,
      paymentMethod: 'Cash',
      createdAt: DateTime.now(),
    );
    final ok =
        await ref.read(expenseControllerProvider.notifier).addExpense(expense);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Expense Entry')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              _isListening
                  ? 'Listening... speak naturally'
                  : 'Tap the mic and say something like\n"I spent 650 rupees on dinner today"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: _isListening ? 0.5 : 0.3),
                      blurRadius: _isListening ? 30 : 16,
                      spreadRadius: _isListening ? 6 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_transcript.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('"$_transcript"',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ),
              ),
            if (_isParsing)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            if (_parsedExpense != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detected Expense',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _row('Amount', '₹${_parsedExpense!['amount']}'),
                      _row('Category', '${_parsedExpense!['category']}'),
                      _row('Description', '${_parsedExpense!['description']}'),
                      _row('Date', '${_parsedExpense!['date']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                  label: 'Confirm & Save', onPressed: _confirmAndSave),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
