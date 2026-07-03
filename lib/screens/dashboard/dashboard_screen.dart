import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/category_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expense = ref.watch(monthlyExpenseProvider);
    final balance = income - expense;
    final recentExpenses = ref.watch(currentMonthExpensesProvider).take(5).toList();
    final budgetUsage = ref.watch(budgetUsageProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(expensesStreamProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back 👋',
                            style: TextStyle(color: Colors.grey.shade600)),
                        userAsync.when(
                          data: (u) => Text(
                            u?.name ?? 'FinWise User',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          loading: () => const SizedBox(
                              height: 20,
                              width: 100,
                              child: LinearProgressIndicator()),
                          error: (_, __) => const Text('FinWise User'),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Balance',
                          style: TextStyle(color: Colors.white.withOpacity(0.85))),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.currency(balance),
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.arrow_downward_rounded,
                              label: 'Income',
                              value: Formatters.currency(income),
                            ),
                          ),
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.arrow_upward_rounded,
                              label: 'Expense',
                              value: Formatters.currency(expense),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_circle_outline,
                        label: 'Add Expense',
                        onTap: () => context.push('/add-expense'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.mic_none_rounded,
                        label: 'Voice Entry',
                        onTap: () => context.push('/voice-entry'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.auto_awesome_outlined,
                        label: 'AI Advisor',
                        onTap: () => context.push('/ai-advisor'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Budget Progress
                if (budgetUsage.isNotEmpty) ...[
                  const Text('Budget Progress',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...budgetUsage.entries.take(3).map((entry) {
                    final percent = (entry.value['percent'] ?? 0).clamp(0, 100).toDouble();
                    final over = (entry.value['percent'] ?? 0) >= 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    '${Formatters.currency(entry.value['spent']!)} / ${Formatters.currency(entry.value['limit']!)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percent / 100,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  color: over ? AppColors.error : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Transactions',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => context.push('/expenses'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                if (recentExpenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No transactions yet. Add your first expense!',
                          style: TextStyle(color: Colors.grey.shade500)),
                    ),
                  )
                else
                  ...recentExpenses.map((e) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Icon(CategoryModel.iconFor(e.category),
                                color: AppColors.primary, size: 20),
                          ),
                          title: Text(e.description.isEmpty ? e.category : e.description),
                          subtitle: Text('${e.category} • ${Formatters.relativeDate(e.date)}'),
                          trailing: Text(
                            '${e.isIncome ? '+' : '-'}${Formatters.currency(e.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: e.isIncome ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      )),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-expense'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 0:
              break;
            case 1:
              context.push('/expenses');
              break;
            case 2:
              context.push('/analytics');
              break;
            case 3:
              context.push('/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
