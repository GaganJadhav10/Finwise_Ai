import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;
  return BudgetRepository(uid: authState.uid);
});

final budgetsStreamProvider = StreamProvider<List<BudgetModel>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  if (repo == null) return const Stream.empty();
  final now = DateTime.now();
  return repo.watchBudgets(now.month, now.year);
});

/// Combines budgets with actual category spend to compute usage %.
final budgetUsageProvider = Provider<Map<String, Map<String, double>>>((ref) {
  final budgets = ref.watch(budgetsStreamProvider).value ?? [];
  final spend = ref.watch(categoryTotalsProvider);

  final Map<String, Map<String, double>> usage = {};
  for (final b in budgets) {
    final spent = spend[b.category] ?? 0;
    usage[b.category] = {
      'limit': b.limit,
      'spent': spent,
      'remaining': (b.limit - spent).clamp(0, double.infinity),
      'percent': b.limit > 0 ? (spent / b.limit * 100) : 0,
    };
  }
  return usage;
});
