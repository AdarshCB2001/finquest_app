// Reports screen — charts and spending analysis
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state  = ref.watch(appProvider);
    final now    = DateTime.now();

    // Category totals (expense only)
    final catTotals = <String, double>{};
    for (final tx in state.transactions) {
      if (tx.type == 'expense') catTotals[tx.category] = (catTotals[tx.category] ?? 0) + tx.amount;
    }
    final totalExpense = catTotals.values.fold<double>(0, (s, v) => s + v);

    // Monthly income vs expense (last 6 months)
    final monthly = <String, Map<String, double>>{};
    for (final tx in state.transactions) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      monthly[key] ??= {'income': 0, 'expense': 0};
      if (tx.type == 'income') monthly[key]!['income'] = (monthly[key]!['income'] ?? 0) + tx.amount;
      if (tx.type == 'expense') monthly[key]!['expense'] = (monthly[key]!['expense'] ?? 0) + tx.amount;
    }
    final sortedMonths = monthly.keys.toList()..sort();
    final last6 = sortedMonths.length > 6 ? sortedMonths.sublist(sortedMonths.length - 6) : sortedMonths;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── PIE CHART ──
        if (catTotals.isNotEmpty) ...[
          const Text('Expense Breakdown', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                SizedBox(
                  height: 200,
                  child: PieChart(PieChartData(
                    sections: catTotals.entries.map((e) {
                      final cat = kCategories[e.key] ?? kCategories['other']!;
                      final pct = e.value / totalExpense * 100;
                      return PieChartSectionData(
                        value: e.value,
                        color: cat.color,
                        title: '${pct.round()}%',
                        radius: 70,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10),
                      );
                    }).toList(),
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  )),
                ),
                const SizedBox(height: 12),
                // Legend
                Wrap(
                  spacing: 10, runSpacing: 6,
                  children: catTotals.entries.map((e) {
                    final cat = kCategories[e.key] ?? kCategories['other']!;
                    return Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('${cat.icon} ${e.key}', style: const TextStyle(color: AppTheme.text2, fontSize: 10)),
                    ]);
                  }).toList(),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Column(children: [
                Text('📊', style: TextStyle(fontSize: 36)),
                SizedBox(height: 8),
                Text('Add expenses to see charts', style: TextStyle(color: AppTheme.text2)),
              ])),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── LINE CHART (income vs expense) ──
        if (last6.isNotEmpty) ...[
          const Text('Income vs Expense', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 200,
                child: LineChart(LineChartData(
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.border, strokeWidth: 0.5),
                    getDrawingVerticalLine: (_) => FlLine(color: AppTheme.border, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i < 0 || i >= last6.length) return const SizedBox();
                        final m = last6[i].split('-')[1];
                        return Text(m, style: const TextStyle(color: AppTheme.text2, fontSize: 9));
                      },
                    )),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _line(last6, monthly, 'income', AppTheme.green),
                    _line(last6, monthly, 'expense', AppTheme.red),
                  ],
                )),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _LegendDot(color: AppTheme.green, label: 'Income'),
            const SizedBox(width: 16),
            _LegendDot(color: AppTheme.red, label: 'Expense'),
          ]),
          const SizedBox(height: 20),
        ],

        // ── SUMMARY STATS ──
        const Text('Summary', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        _SummaryRow(label: 'Total transactions', value: '${state.transactions.length}'),
        _SummaryRow(label: 'Total income',        value: fmtRupee(state.transactions.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount))),
        _SummaryRow(label: 'Total expenses',      value: fmtRupee(totalExpense)),
        _SummaryRow(label: 'Net balance',         value: fmtRupee(state.transactions.fold<double>(0, (s, t) => t.type == 'income' ? s + t.amount : t.type == 'expense' ? s - t.amount : s))),
        _SummaryRow(label: 'Buildings invested',  value: fmtRupee(state.buildings.fold<double>(0, (s, b) => s + b.amount))),
        const SizedBox(height: 80),
      ],
    );
  }

  LineChartBarData _line(List<String> months, Map<String, Map<String, double>> monthly, String key, Color color) {
    return LineChartBarData(
      spots: List.generate(months.length, (i) => FlSpot(i.toDouble(), monthly[months[i]]?[key] ?? 0)),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
      ),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color; final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 12)),
  ]);
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}
