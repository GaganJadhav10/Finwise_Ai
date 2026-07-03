import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/expense_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expense = ref.watch(monthlyExpenseProvider);
    final allExpenses = ref.watch(currentMonthExpensesProvider);

    final categories = categoryTotals.keys.toList();
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    // Weekly spend for bar chart (last 7 days)
    final now = DateTime.now();
    final weeklyTotals = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return allExpenses
          .where((e) =>
              !e.isIncome &&
              e.date.year == day.year &&
              e.date.month == day.month &&
              e.date.day == day.day)
          .fold(0.0, (sum, e) => sum + e.amount);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income vs Expense
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Income vs Expense',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _barColumn('Income', income,
                              income > expense ? income : expense, AppColors.success),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _barColumn('Expense', expense,
                              income > expense ? income : expense, AppColors.error),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Pie Chart
            const Text('Category-wise Spending',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (categoryTotals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No expense data yet this month',
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                    sections: List.generate(categories.length, (i) {
                      final value = categoryTotals[categories[i]]!;
                      final percent = total > 0 ? (value / total * 100) : 0;
                      return PieChartSectionData(
                        value: value,
                        color: AppColors.categoryColors[i % AppColors.categoryColors.length],
                        title: '${percent.toStringAsFixed(0)}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: List.generate(categories.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.categoryColors[i % AppColors.categoryColors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${categories[i]} • ${Formatters.currency(categoryTotals[categories[i]]!)}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                );
              }),
            ),
            const SizedBox(height: 28),

            // Weekly Spending Bar Chart
            const Text('Weekly Spending',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = now.subtract(Duration(days: 6 - value.toInt()));
                          const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[day.weekday - 1],
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyTotals[i],
                          color: AppColors.primary,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _barColumn(String label, double value, double max, Color color) {
    final percent = max > 0 ? (value / max) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 6),
        Text(Formatters.currency(value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ],
    );
  }
}
