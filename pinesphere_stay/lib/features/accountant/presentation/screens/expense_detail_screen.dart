import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

class ExpenseItem {
  final String title;
  final String category;
  final double amount;
  final DateTime date;

  ExpenseItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });
}

// In-memory persistent session list for expenses
class ExpenseListNotifier extends Notifier<List<ExpenseItem>> {
  @override
  List<ExpenseItem> build() {
    return [
      ExpenseItem(title: 'Electricity Bill - June', category: 'Electricity', amount: 8500.0, date: DateTime(2026, 6, 20)),
      ExpenseItem(title: 'Kitchen gas refill', category: 'Gas', amount: 2400.0, date: DateTime(2026, 6, 22)),
      ExpenseItem(title: 'Staff Salary - Alicia', category: 'Salary', amount: 15000.0, date: DateTime(2026, 7, 1)),
      ExpenseItem(title: 'Restocking restaurant ingredients', category: 'Food', amount: 12000.0, date: DateTime(2026, 7, 5)),
      ExpenseItem(title: 'Chair repair', category: 'Repairs', amount: 1000.0, date: DateTime(2026, 7, 10)),
      ExpenseItem(title: 'Petty Cash - Guest toiletries', category: 'Petty Cash', amount: 1500.0, date: DateTime(2026, 7, 12)),
    ];
  }

  void addExpense(String title, String category, double amount) {
    state = [
      ExpenseItem(title: title, category: category, amount: amount, date: DateTime.now()),
      ...state,
    ];
  }
}

final expenseListProvider = NotifierProvider<ExpenseListNotifier, List<ExpenseItem>>(() {
  return ExpenseListNotifier();
});

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({super.key});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Electricity';

  final List<String> _categories = [
    'Electricity',
    'Gas',
    'Salary',
    'Food',
    'Repairs',
    'Petty Cash',
    'Other Expenses'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Property Expense'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Expense Description'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: 'Amount (₹)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid amount' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final amount = double.parse(_amountController.text);
                      ref.read(expenseListProvider.notifier).addExpense(
                        _titleController.text,
                        _selectedCategory,
                        amount,
                      );
                      _titleController.clear();
                      _amountController.clear();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseListProvider);
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Management'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryCard(totalExpenses, expenses.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final exp = expenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.errorContainer,
                      child: Icon(_getIconForCategory(exp.category), color: AppColors.onErrorContainer),
                    ),
                    title: Text(
                      exp.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Category: ${exp.category} • ${exp.date.day}/${exp.date.month}/${exp.date.year}'),
                    trailing: Text(
                      '-₹${exp.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add Expense'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSummaryCard(double total, int count) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.onErrorContainer.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Expenses (This Property)',
            style: TextStyle(color: AppColors.onErrorContainer, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.onErrorContainer,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count expenses registered',
            style: const TextStyle(color: AppColors.onErrorContainer, fontSize: 14),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Electricity': return Icons.bolt;
      case 'Gas': return Icons.local_fire_department;
      case 'Salary': return Icons.people;
      case 'Food': return Icons.restaurant;
      case 'Repairs': return Icons.build;
      case 'Petty Cash': return Icons.wallet;
      default: return Icons.category;
    }
  }
}
