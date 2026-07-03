import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';
import 'auth_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;
  return ExpenseRepository(uid: authState.uid);
});

final expensesStreamProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchExpenses();
});

/// Derived provider: current month's expenses only.
final currentMonthExpensesProvider = Provider<List<ExpenseModel>>((ref) {
  final all = ref.watch(expensesStreamProvider).value ?? [];
  final now = DateTime.now();
  return all
      .where((e) => e.date.month == now.month && e.date.year == now.year)
      .toList();
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount);
});

final monthlyExpenseProvider = Provider<double>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);
  return expenses.where((e) => !e.isIncome).fold(0.0, (sum, e) => sum + e.amount);
});

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final expenses =
      ref.watch(currentMonthExpensesProvider).where((e) => !e.isIncome);
  final Map<String, double> totals = {};
  for (final e in expenses) {
    totals[e.category] = (totals[e.category] ?? 0) + e.amount;
  }
  return totals;
});

class ExpenseController extends StateNotifier<AsyncValue<void>> {
  final ExpenseRepository? _repo;
  ExpenseController(this._repo) : super(const AsyncData(null));

  Future<bool> addExpense(ExpenseModel expense) async {
    if (_repo == null) return false;
    state = const AsyncLoading();
    try {
      await _repo.addExpense(expense);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateExpense(ExpenseModel expense) async {
    if (_repo == null) return false;
    try {
      await _repo.updateExpense(expense);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    if (_repo == null) return false;
    try {
      await _repo.deleteExpense(id);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final expenseControllerProvider =
    StateNotifierProvider<ExpenseController, AsyncValue<void>>(
        (ref) => ExpenseController(ref.watch(expenseRepositoryProvider)));
