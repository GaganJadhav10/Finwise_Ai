import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_service.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _dailyReminder = true;
  String _currency = 'INR (₹)';
  String _language = 'English';

  Future<void> _exportPdf() async {
    final expenses = ref.read(currentMonthExpensesProvider);
    final income = ref.read(monthlyIncomeProvider);
    final expenseTotal = ref.read(monthlyExpenseProvider);
    final file = await PdfService.instance.generateExpenseReport(
      expenses: expenses,
      periodLabel: 'This Month',
      totalIncome: income,
      totalExpense: expenseTotal,
    );
    await PdfService.instance.shareFile(file);
  }

  Future<void> _exportCsv() async {
    final expenses = ref.read(currentMonthExpensesProvider);
    final file = await PdfService.instance.generateCsvReport(expenses);
    await PdfService.instance.shareFile(file);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const _SectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: const Text('Currency'),
            trailing: Text(_currency),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: Text(_language),
            onTap: () {},
          ),
          const _SectionHeader('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Login'),
            value: _biometricEnabled,
            onChanged: (val) async {
              if (val) {
                final supported = await BiometricService.instance.isSupported;
                if (!supported) return;
                final ok = await BiometricService.instance.authenticate();
                if (!ok) return;
              }
              setState(() => _biometricEnabled = val);
            },
          ),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Daily Expense Reminder'),
            value: _dailyReminder,
            onChanged: (val) async {
              setState(() => _dailyReminder = val);
              if (val) {
                await NotificationService.instance.scheduleDailyReminder();
              }
            },
          ),
          const _SectionHeader('Export'),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Export as PDF'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportPdf,
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('Export as CSV'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportCsv,
          ),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About FinWise AI'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
