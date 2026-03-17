// Dashboard screen — financial overview
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';
import '../widgets/transaction_tile.dart';
import 'transactions_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final notifier = ref.read(appProvider.notifier);
    final now = DateTime.now();

    // Month totals
    final mTx = state.transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
    final income  = mTx.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final expense = mTx.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final savRate = income > 0 ? ((income - expense) / income * 100).clamp(0, 100).round() : 0;

    // Streak calendar (Mon-Sun of current week)
    final monday = now.subtract(Duration(days: (now.weekday - 1)));
    final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── NET WORTH CARD ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF283593)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Net Worth', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(
                fmtRupee(notifier.netWorth),
                style: TextStyle(
                  color: notifier.netWorth >= 0 ? Colors.white : const Color(0xFFFF8A80),
                  fontSize: 34, fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _StatChip(label: 'Income', value: fmtRupee(income), color: const Color(0xFF69F0AE)),
                const SizedBox(width: 12),
                _StatChip(label: 'Expenses', value: fmtRupee(expense), color: const Color(0xFFFF8A80)),
                const SizedBox(width: 12),
                _StatChip(label: 'Saved', value: '$savRate%', color: AppTheme.accent),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── STREAK ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text('Daily Streak', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  Text('${state.streak} days', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final day = monday.add(Duration(days: i));
                    final dayStr = day.toIso8601String().substring(0, 10);
                    final isDone = state.streakDays.contains(dayStr);
                    final isToday = dayStr == todayStr();
                    return Column(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.accent : (isToday ? AppTheme.primary : AppTheme.surface),
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isDone ? Border.all(color: AppTheme.accent, width: 2) : null,
                        ),
                        child: Center(child: Text(
                          dayLetters[i],
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                            color: isDone ? Colors.black : AppTheme.text1),
                        )),
                      ),
                    ]);
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── ACCOUNTS ──
        if (state.accounts.isNotEmpty) ...[
          const Text('Accounts', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final acct = state.accounts[i];
                final bal = notifier.getAccountBalance(acct);
                final color = _hexColor(acct.color);
                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(acct.icon, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ]),
                    const Spacer(),
                    Text(fmtRupee(bal),
                      style: TextStyle(color: bal >= 0 ? AppTheme.text1 : AppTheme.red, fontWeight: FontWeight.w700, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(acct.name, style: const TextStyle(color: AppTheme.text2, fontSize: 11), overflow: TextOverflow.ellipsis),
                  ]),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── THIS MONTH CATEGORY BREAKDOWN ──
        if (expense > 0) ...[
          const Text('This Month', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _CategoryBreakdown(mTx: mTx, total: expense),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── RECENT TRANSACTIONS ──
        Row(children: [
          const Text('Recent Transactions', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
        ]),
        const SizedBox(height: 8),
        if (state.transactions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Column(children: [
                Text('💸', style: TextStyle(fontSize: 36)),
                SizedBox(height: 8),
                Text('No transactions yet', style: TextStyle(color: AppTheme.text2)),
              ])),
            ),
          )
        else
          ...state.transactions.take(6).map((tx) => TransactionTile(tx: tx, accounts: state.accounts)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List txList;
  final double total;

  const _CategoryBreakdown({required List mTx, required this.total}) : txList = mTx;

  @override
  Widget build(BuildContext context) {
    final catTotals = <String, double>{};
    for (final tx in txList) {
      if (tx.type == 'expense') catTotals[tx.category] = (catTotals[tx.category] ?? 0) + tx.amount;
    }
    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.take(5).map((e) {
        final cat = kCategories[e.key] ?? kCategories['other']!;
        final pct = (e.value / total * 100).round();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Text(cat.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(e.key, style: const TextStyle(color: AppTheme.text1, fontSize: 12, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(fmtRupee(e.value), style: const TextStyle(color: AppTheme.text1, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('  ($pct%)', style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: e.value / total,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                  minHeight: 4,
                ),
              ),
            ])),
          ]),
        );
      }).toList(),
    );
  }
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return const Color(0xFF1565C0);
  }
}
