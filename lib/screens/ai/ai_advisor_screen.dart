import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ai_service.dart';
import '../../providers/expense_provider.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage(this.text, this.isUser);
}

class AiAdvisorScreen extends ConsumerStatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  ConsumerState<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends ConsumerState<AiAdvisorScreen> {
  final _aiService = AiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  final _suggestions = [
    'Why am I spending more this month?',
    'How can I save money?',
    'What category should I reduce?',
  ];

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(question, true));
      _loading = true;
      _controller.clear();
    });

    final categoryTotals = ref.read(categoryTotalsProvider);
    final income = ref.read(monthlyIncomeProvider);
    final expense = ref.read(monthlyExpenseProvider);

    final answer = await _aiService.getFinancialAdvice(
      question: question,
      categoryTotals: categoryTotals,
      monthlyIncome: income,
      monthlyExpense: expense,
    );

    setState(() {
      _messages.add(_ChatMessage(answer, false));
      _loading = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Financial Advisor')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
                        const SizedBox(height: 16),
                        const Text('Ask me anything about your finances',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ..._suggestions.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OutlinedButton(
                                onPressed: () => _ask(s),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 46),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(s, textAlign: TextAlign.center),
                              ),
                            )),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final m = _messages[i];
                      return Align(
                        alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: m.isUser ? AppColors.primary : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(color: m.isUser ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask about your spending...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _ask,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _ask(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
