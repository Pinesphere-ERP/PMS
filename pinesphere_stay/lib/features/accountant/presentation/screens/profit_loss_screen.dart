import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/presentation/payment_history_screen.dart';
import 'expense_detail_screen.dart';

class ProfitLossScreen extends ConsumerStatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  ConsumerState<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends ConsumerState<ProfitLossScreen> {
  int _selectedBarIndex = 2; // Default to July

  final List<Map<String, dynamic>> _monthsMock = [
    {
      'month': 'May',
      'income': 85000.0,
      'expenses': 42000.0,
      'details': [
        {'title': 'Room booking revenue', 'type': 'income', 'amount': 85000.0},
        {'title': 'Electricity & Gas bills', 'type': 'expense', 'amount': 12000.0},
        {'title': 'Staff payroll', 'type': 'expense', 'amount': 30000.0},
      ]
    },
    {
      'month': 'June',
      'income': 102000.0,
      'expenses': 38000.0,
      'details': [
        {'title': 'Room booking revenue', 'type': 'income', 'amount': 102000.0},
        {'title': 'Minor infrastructure repair', 'type': 'expense', 'amount': 8000.0},
        {'title': 'Monthly staff payroll', 'type': 'expense', 'amount': 30000.0},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentsListProvider).value ?? [];
    final expenses = ref.watch(expenseListProvider);

    // Calculate dynamic July data from providers
    final double julyIncome = payments.fold(0.0, (sum, p) => sum + p.amount);
    final double julyExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final List<Map<String, dynamic>> dataPoints = [
      ..._monthsMock,
      {
        'month': 'July',
        'income': julyIncome == 0.0 ? 112000.0 : julyIncome,
        'expenses': julyExpenses == 0.0 ? 30000.0 : julyExpenses,
        'details': [
          ...payments.map((p) => {'title': 'Payment from guest (Txn: ${p.transactionId.substring(0, 8)})', 'type': 'income', 'amount': p.amount}),
          ...expenses.map((e) => {'title': e.title, 'type': 'expense', 'amount': e.amount}),
          if (payments.isEmpty) {'title': 'Base booking revenue (Mock)', 'type': 'income', 'amount': 112000.0},
          if (expenses.isEmpty) {'title': 'Standard operating costs (Mock)', 'type': 'expense', 'amount': 30000.0},
        ]
      }
    ];

    final selectedData = dataPoints[_selectedBarIndex];
    final selectedIncome = selectedData['income'] as double;
    final selectedExpenses = selectedData['expenses'] as double;
    final selectedProfit = selectedIncome - selectedExpenses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profit & Loss Statement'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartSection(dataPoints),
            const SizedBox(height: 24),
            _buildMetricsBreakdown(selectedIncome, selectedExpenses, selectedProfit),
            const SizedBox(height: 24),
            _buildDetailsSection(selectedData['month'] as String, selectedData['details'] as List<dynamic>),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(List<Map<String, dynamic>> dataPoints) {
    // Find max value to scale chart bars correctly
    double maxVal = 10000.0;
    for (var dp in dataPoints) {
      if (dp['income'] > maxVal) maxVal = dp['income'] as double;
      if (dp['expenses'] > maxVal) maxVal = dp['expenses'] as double;
    }
    maxVal = maxVal * 1.15; // 15% padding at top

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Chart',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap any column to inspect specific monthly figures.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(dataPoints.length, (idx) {
                  final dp = dataPoints[idx];
                  final inc = dp['income'] as double;
                  final exp = dp['expenses'] as double;
                  final isSelected = _selectedBarIndex == idx;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedBarIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      color: Colors.transparent, // expand tap area
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Income Bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 16,
                                height: (inc / maxVal) * 150,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.green : Colors.green.withValues(alpha: 0.4),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Expense Bar
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 16,
                                height: (exp / maxVal) * 150,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.red : Colors.red.withValues(alpha: 0.4),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dp['month'],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Income', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem('Expenses', Colors.red),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMetricsBreakdown(double income, double expenses, double profit) {
    final isLoss = profit < 0;
    return Row(
      children: [
        _buildMetricBox('Income', '₹${income.toStringAsFixed(0)}', Colors.green),
        const SizedBox(width: 12),
        _buildMetricBox('Expenses', '₹${expenses.toStringAsFixed(0)}', Colors.red),
        const SizedBox(width: 12),
        _buildMetricBox(
          isLoss ? 'Loss' : 'Profit',
          '₹${profit.abs().toStringAsFixed(0)}',
          isLoss ? Colors.red.shade900 : Colors.green.shade900,
          containerColor: isLoss ? Colors.red.shade50 : Colors.green.shade50,
        ),
      ],
    );
  }

  Widget _buildMetricBox(String title, String value, Color textColor, {Color? containerColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: containerColor ?? AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(String month, List<dynamic> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions / Ledger - $month',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (details.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No details available for this period.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: details.length,
            itemBuilder: (context, index) {
              final det = details[index];
              final isIncome = det['type'] == 'income';
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: Icon(
                    isIncome ? Icons.trending_up : Icons.trending_down,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                  title: Text(det['title'] as String),
                  trailing: Text(
                    '${isIncome ? "+" : "-"}₹${(det['amount'] as double).toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
