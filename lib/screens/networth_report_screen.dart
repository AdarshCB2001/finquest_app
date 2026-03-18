// My Financial Report screen — tapped from Net Worth card on Dashboard
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';
import 'reports_screen.dart';

class NetworthReportScreen extends ConsumerWidget {
  const NetworthReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state   = ref.watch(appProvider);
    final notifier = ref.read(appProvider.notifier);
    final now     = DateTime.now();

    // ── This month transactions ──────────────────────────────
    final mTx = state.transactions
        .where((t) => t.date.month == now.month && t.date.year == now.year)
        .toList();
    final income  = mTx.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final expense = mTx.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final saved   = income - expense;
    final savRate = income > 0 ? (saved / income * 100).clamp(-100, 100) : 0.0;

    // ── Net Worth breakdown ──────────────────────────────────
    final netWorth = notifier.netWorth;
    double totalAssets      = 0;
    double totalLiabilities = 0;
    for (final a in state.accounts) {
      final bal = notifier.getAccountBalance(a);
      if (bal >= 0) {
        totalAssets += bal;
      } else {
        totalLiabilities += bal.abs();
      }
    }

    // ── Last-month change estimate ───────────────────────────
    final lastMonth = DateTime(now.year, now.month - 1);
    final lmTx = state.transactions
        .where((t) => t.date.month == lastMonth.month && t.date.year == lastMonth.year)
        .toList();
    final lmIncome  = lmTx.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final lmExpense = lmTx.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final monthChange = (income - expense) - (lmIncome - lmExpense);

    // ── This-month category breakdown ────────────────────────
    final catTotals = <String, double>{};
    for (final tx in mTx) {
      if (tx.type == 'expense') catTotals[tx.category] = (catTotals[tx.category] ?? 0) + tx.amount;
    }
    final sortedCats = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // ── Last 6 months income vs expense ─────────────────────
    final monthly = <String, Map<String, double>>{};
    for (final tx in state.transactions) {
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
      monthly[key] ??= {'income': 0, 'expense': 0};
      if (tx.type == 'income')  monthly[key]!['income']  = (monthly[key]!['income']  ?? 0) + tx.amount;
      if (tx.type == 'expense') monthly[key]!['expense'] = (monthly[key]!['expense'] ?? 0) + tx.amount;
    }
    final sortedMonths = monthly.keys.toList()..sort();
    final last6 = sortedMonths.length > 6
        ? sortedMonths.sublist(sortedMonths.length - 6)
        : sortedMonths;

    // ── Account list sorted by balance ───────────────────────
    final acctBalances = state.accounts
        .map((a) => MapEntry(a, notifier.getAccountBalance(a)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ── City progress (FinStage) ─────────────────────────────
    final stage     = getStage(netWorth);
    final nextStage = stage.index + 1 < kStages.length ? kStages[stage.index + 1] : null;
    final xpProgress = nextStage != null && nextStage.minNetWorth > stage.minNetWorth
        ? ((netWorth - stage.minNetWorth) / (nextStage.minNetWorth - stage.minNetWorth)).clamp(0.0, 1.0)
        : 1.0;

    String motivationMsg;
    if (savRate >= 30) {
      motivationMsg = 'You saved ${savRate.round()}% this month — great habit! 🎉';
    } else if (savRate >= 10) {
      motivationMsg = "You're saving ${savRate.round()}% — keep it up! 💪";
    } else if (savRate >= 0) {
      motivationMsg = 'No savings yet — every rupee counts! 🌱';
    } else {
      motivationMsg = 'You overspent this month — let\'s fix it next month! 🔧';
    }

    // ── Max bar value for chart scaling ─────────────────────
    double maxBar = 1000;
    for (final m in last6) {
      final inc = monthly[m]?['income'] ?? 0;
      final exp = monthly[m]?['expense'] ?? 0;
      if (inc > maxBar) maxBar = inc;
      if (exp > maxBar) maxBar = exp;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Financial Report'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [

          // ══════════════════════════════════════════════
          // SECTION 1 — Net Worth Summary
          // ══════════════════════════════════════════════
          _SectionHeader(emoji: '💰', title: 'Net Worth Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Total Net Worth',
                      style: TextStyle(color: AppTheme.text2, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    fmtRupee(netWorth),
                    style: TextStyle(
                      color: netWorth >= 0 ? AppTheme.green : AppTheme.red,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Month-over-month change
                  Row(children: [
                    Icon(
                      monthChange >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 14,
                      color: monthChange >= 0 ? AppTheme.green : AppTheme.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${fmtRupee(monthChange.abs())} vs last month',
                      style: TextStyle(
                        color: monthChange >= 0 ? AppTheme.green : AppTheme.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  const Divider(color: AppTheme.border, height: 1),
                  const SizedBox(height: 16),
                  Row(children: [
                    _NetWorthStat(
                      label: 'Total Assets',
                      value: fmtRupee(totalAssets),
                      color: const Color(0xFF69F0AE),
                    ),
                    const SizedBox(width: 16),
                    _NetWorthStat(
                      label: 'Total Liabilities',
                      value: totalLiabilities > 0 ? fmtRupee(totalLiabilities) : '—',
                      color: totalLiabilities > 0 ? AppTheme.red : AppTheme.text2,
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // ══════════════════════════════════════════════
          // SECTION 2 — This Month at a Glance
          // ══════════════════════════════════════════════
          _SectionHeader(emoji: '📅', title: 'This Month at a Glance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _MonthRow(label: 'Total Income',  value: fmtRupee(income),  color: AppTheme.green),
                _MonthRow(label: 'Total Expenses', value: fmtRupee(expense), color: AppTheme.red),
                _MonthRow(
                  label: 'Money Saved',
                  value: fmtRupee(saved.abs()),
                  color: saved >= 0 ? AppTheme.green : AppTheme.red,
                  prefix: saved < 0 ? '−' : '',
                ),
                const SizedBox(height: 14),
                // Savings rate bar
                Row(children: [
                  const Text('Savings Rate', style: TextStyle(color: AppTheme.text2, fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${savRate.round()}%',
                    style: TextStyle(
                      color: savRate >= 20 ? AppTheme.green : savRate >= 0 ? AppTheme.accent : AppTheme.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: savRate.clamp(0.0, 100.0) / 100,
                    minHeight: 10,
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      savRate >= 20 ? AppTheme.green : savRate >= 0 ? AppTheme.accent : AppTheme.red,
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // ══════════════════════════════════════════════
          // SECTION 3 — Where Did My Money Go?
          // ══════════════════════════════════════════════
          _SectionHeader(emoji: '📊', title: 'Where Did My Money Go?'),
          if (sortedCats.isEmpty)
            _EmptyCard(msg: 'No expenses this month yet')
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: sortedCats.take(5).map((e) {
                    final cat  = kCategories[e.key] ?? kCategories['other']!;
                    final pct  = expense > 0 ? (e.value / expense * 100).round() : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              e.key[0].toUpperCase() + e.key.substring(1),
                              style: const TextStyle(color: AppTheme.text1, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(fmtRupee(e.value),
                                style: const TextStyle(color: AppTheme.text1, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('  $pct%',
                                style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
                          ]),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: expense > 0 ? e.value / expense : 0,
                              minHeight: 7,
                              backgroundColor: AppTheme.border,
                              valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // ══════════════════════════════════════════════
          // SECTION 4 — Income vs Expense — Last 6 Months
          // ══════════════════════════════════════════════
          _SectionHeader(emoji: '📈', title: 'Income vs Expense — Last 6 Months'),
          if (last6.isEmpty)
            _EmptyCard(msg: 'Not enough data yet')
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          maxY: maxBar * 1.2,
                          barGroups: List.generate(last6.length, (i) {
                            final inc = monthly[last6[i]]?['income'] ?? 0;
                            final exp = monthly[last6[i]]?['expense'] ?? 0;
                            return BarChartGroupData(
                              x: i,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: inc,
                                  color: AppTheme.green,
                                  width: 10,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                                BarChartRodData(
                                  toY: exp,
                                  color: AppTheme.red,
                                  width: 10,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) =>
                                const FlLine(color: AppTheme.border, strokeWidth: 0.5),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 24,
                                getTitlesWidget: (v, _) {
                                  final i = v.round();
                                  if (i < 0 || i >= last6.length) return const SizedBox();
                                  final parts = last6[i].split('-');
                                  final monthNum = int.tryParse(parts[1]) ?? 1;
                                  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                  return Text(months[monthNum],
                                      style: const TextStyle(color: AppTheme.text2, fontSize: 10));
                                },
                              ),
                            ),
                          ),
                          barTouchData: BarTouchData(enabled: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      _LegendDot(color: AppTheme.green, label: 'Income'),
                      const SizedBox(width: 16),
                      _LegendDot(color: AppTheme.red, label: 'Expenses'),
                    ]),
                  ],
                ),
              ),
            ),

          // ══════════════════════════════════════════════
          // SECTION 5 — Account Balances
          // ══════════════════════════════════════════════
          _SectionHeader(emoji: '🏦', title: 'Account Balances'),
          if (acctBalances.isEmpty)
            _EmptyCard(msg: 'No accounts added yet')
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: acctBalances.asMap().entries.map((entry) {
                    final i      = entry.key;
                    final acct   = entry.value.key;
                    final bal    = entry.value.value;
                    final isTop  = i == 0 && acctBalances.length > 1;
                    final isLow  = i == acctBalances.length - 1 && acctBalances.length > 1;
                    final acctColor = _hexColor(acct.color);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTop
                              ? AppTheme.accent.withOpacity(0.7)
                              : isLow
                                  ? AppTheme.red.withOpacity(0.5)
                                  : AppTheme.border,
                          width: isTop || isLow ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: acctColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(acct.icon, style: const TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(acct.name,
                                  style: const TextStyle(color: AppTheme.text1, fontSize: 14, fontWeight: FontWeight.w600)),
                              if (isTop) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Highest', style: TextStyle(color: AppTheme.accent, fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ],
                              if (isLow) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Lowest', style: TextStyle(color: AppTheme.red, fontSize: 9, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ]),
                            Text(kAccountTypes[acct.type] ?? acct.type,
                                style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
                          ],
                        )),
                        Text(
                          fmtRupee(bal),
                          style: TextStyle(
                            color: bal >= 0 ? AppTheme.text1 : AppTheme.red,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ),

          // ══════════════════════════════════════════════
          // SECTION 6 — City Progress Teaser
          // ══════════════════════════════════════════════
          _SectionHeader(emoji: '🏙️', title: 'City Progress'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(stage.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stage.name,
                            style: const TextStyle(color: AppTheme.text1, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                          nextStage != null
                              ? 'Next: ${nextStage.name} at ${fmtRupee(nextStage.minNetWorth)}'
                              : 'Maximum stage reached! 🎉',
                          style: const TextStyle(color: AppTheme.text2, fontSize: 12),
                        ),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('Progress', style: TextStyle(color: AppTheme.text2, fontSize: 12)),
                    const Spacer(),
                    Text('${(xpProgress * 100).round()}%',
                        style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: xpProgress,
                      minHeight: 10,
                      backgroundColor: AppTheme.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          motivationMsg,
                          style: const TextStyle(color: AppTheme.text1, fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // ══════════════════════════════════════════════
          // FOOTER — View Full Reports button
          // ══════════════════════════════════════════════
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('View Full Reports'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  const _SectionHeader({required this.emoji, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 6),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
      );
}

class _NetWorthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NetWorthStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _MonthRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String prefix;
  const _MonthRow({required this.label, required this.value, required this.color, this.prefix = ''});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 13)),
          const Spacer(),
          Text('$prefix$value',
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 12)),
      ]);
}

class _EmptyCard extends StatelessWidget {
  final String msg;
  const _EmptyCard({required this.msg});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(msg, style: const TextStyle(color: AppTheme.text2, fontSize: 13)),
          ),
        ),
      );
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return const Color(0xFF1565C0);
  }
}
