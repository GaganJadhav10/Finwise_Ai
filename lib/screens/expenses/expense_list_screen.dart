import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/category_model.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';

enum DateFilter { today, yesterday, thisWeek, thisMonth, lastMonth, all }

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  String _query = '';
  DateFilter _filter = DateFilter.all;
  String? _categoryFilter;

  List<ExpenseModel> _applyFilters(List<ExpenseModel> expenses) {
    var result = expenses;

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result
          .where((e) =>
              e.description.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q) ||
              e.paymentMethod.toLowerCase().contains(q) ||
              e.amount.toString().contains(q))
          .toList();
    }

    if (_categoryFilter != null) {
      result = result.where((e) => e.category == _categoryFilter).toList();
    }

    final now = DateTime.now();
    switch (_filter) {
      case DateFilter.today:
        result = result
            .where((e) =>
                e.date.year == now.year &&
                e.date.month == now.month &&
                e.date.day == now.day)
            .toList();
        break;
      case DateFilter.yesterday:
        final y = now.subtract(const Duration(days: 1));
        result = result
            .where((e) =>
                e.date.year == y.year &&
                e.date.month == y.month &&
                e.date.day == y.day)
            .toList();
        break;
      case DateFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        result = result
            .where((e) =>
                e.date.isAfter(weekStart.subtract(const Duration(days: 1))))
            .toList();
        break;
      case DateFilter.thisMonth:
        result = result
            .where((e) => e.date.month == now.month && e.date.year == now.year)
            .toList();
        break;
      case DateFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        result = result
            .where((e) =>
                e.date.month == lastMonth.month &&
                e.date.year == lastMonth.year)
            .toList();
        break;
      case DateFilter.all:
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by category, amount, keyword...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: DateFilter.values.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_filterLabel(f)),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final filtered = _applyFilters(expenses);
                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No transactions found',
                        style: TextStyle(color: Colors.grey.shade500)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => ref
                          .read(expenseControllerProvider.notifier)
                          .deleteExpense(e.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            child: Icon(CategoryModel.iconFor(e.category),
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(e.description.isEmpty
                              ? e.category
                              : e.description),
                          subtitle: Text(
                              '${e.category} • ${e.paymentMethod} • ${Formatters.date(e.date)}'),
                          trailing: Text(
                            '${e.isIncome ? '+' : '-'}${Formatters.currency(e.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: e.isIncome
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          onTap: () => context.push('/add-expense', extra: e),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-expense'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _filterLabel(DateFilter f) {
    switch (f) {
      case DateFilter.today:
        return 'Today';
      case DateFilter.yesterday:
        return 'Yesterday';
      case DateFilter.thisWeek:
        return 'This Week';
      case DateFilter.thisMonth:
        return 'This Month';
      case DateFilter.lastMonth:
        return 'Last Month';
      case DateFilter.all:
        return 'All';
    }
  }
}
