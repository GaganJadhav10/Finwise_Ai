import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/ai_service.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/gradient_button.dart';
import '../../models/expense_model.dart';
import '../../providers/expense_provider.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseModel? existing;
  const AddExpenseScreen({super.key, this.existing});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _aiService = AiService();

  String _category = AppStrings.defaultCategories.first;
  String _paymentMethod = AppStrings.paymentMethods.first;
  DateTime _date = DateTime.now();
  bool _isIncome = false;
  bool _isCategorizing = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountController.text = e.amount.toString();
      _descriptionController.text = e.description;
      _category = e.category;
      _paymentMethod = e.paymentMethod;
      _date = e.date;
      _isIncome = e.isIncome;
    }
  }

  Future<void> _autoCategorize() async {
    if (_descriptionController.text.trim().isEmpty) return;
    setState(() => _isCategorizing = true);
    final result = await _aiService.categorizeExpense(
      _descriptionController.text,
      AppStrings.defaultCategories,
    );
    setState(() {
      _category = result;
      _isCategorizing = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final expense = ExpenseModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      amount: double.parse(_amountController.text),
      category: _category,
      date: _date,
      description: _descriptionController.text.trim(),
      paymentMethod: _paymentMethod,
      isIncome: _isIncome,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final controller = ref.read(expenseControllerProvider.notifier);
    final ok = widget.existing == null
        ? await controller.addExpense(expense)
        : await controller.updateExpense(expense);

    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ref
                    .read(expenseControllerProvider.notifier)
                    .deleteExpense(widget.existing!.id);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Income / Expense toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ToggleTab(
                        label: 'Expense',
                        selected: !_isIncome,
                        color: AppColors.error,
                        onTap: () => setState(() => _isIncome = false),
                      ),
                    ),
                    Expanded(
                      child: _ToggleTab(
                        label: 'Income',
                        selected: _isIncome,
                        color: AppColors.success,
                        onTap: () => setState(() => _isIncome = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _amountController,
                label: 'Amount (₹)',
                prefixIcon: Icons.currency_rupee,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.amount,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (e.g. "Swiggy dinner")',
                prefixIcon: Icons.notes_outlined,
                suffixIcon: _isCategorizing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.auto_awesome,
                            color: AppColors.primary),
                        tooltip: 'AI Auto-Categorize',
                        onPressed: _autoCategorize,
                      ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppStrings.defaultCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: AppStrings.paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text('${_date.day}/${_date.month}/${_date.year}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: isEditing ? 'Update' : 'Save Transaction',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
