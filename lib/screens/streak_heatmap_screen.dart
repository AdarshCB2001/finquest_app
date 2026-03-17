// Daily Streak Heatmap Screen — month-wise activity calendar
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';

class StreakHeatmapScreen extends ConsumerStatefulWidget {
  const StreakHeatmapScreen({super.key});

  @override
  ConsumerState<StreakHeatmapScreen> createState() => _StreakHeatmapScreenState();
}

class _StreakHeatmapScreenState extends ConsumerState<StreakHeatmapScreen> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(() {
    _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
  });

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_viewMonth.year, _viewMonth.month + 1);
    if (next.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() => _viewMonth = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(appProvider);
    final now     = DateTime.now();
    final today   = DateTime(now.year, now.month, now.day);
    final isCurrentMonth = _viewMonth.year == now.year && _viewMonth.month == now.month;

    // ── Build per-day income/expense map for the current view month ──
    final Map<String, _DayData> dayMap = {};

    for (final tx in state.transactions) {
      if (tx.date.year != _viewMonth.year || tx.date.month != _viewMonth.month) continue;
      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2,'0')}-${tx.date.day.toString().padLeft(2,'0')}';
      dayMap[key] ??= _DayData();
      if (tx.type == 'income')  dayMap[key]!.income  += tx.amount;
      if (tx.type == 'expense') dayMap[key]!.expense += tx.amount;
    }

    // ── Calendar grid setup ──
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_viewMonth.year, _viewMonth.month, 1).weekday; // 1=Mon .. 7=Sun
    final leadingBlanks = firstWeekday - 1;

    // ── Streak count: consecutive days (ending today or yesterday) where income > expense ──
    int streak = 0;
    DateTime cursor = today;
    while (true) {
      final key = '${cursor.year}-${cursor.month.toString().padLeft(2,'0')}-${cursor.day.toString().padLeft(2,'0')}';
      final data = _dayDataFromState(state, cursor);
      if (data == null || data.income <= data.expense) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final monthLabel = _monthName(_viewMonth.month);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.text1, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Activity Heatmap',
          style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── STREAK BANNER ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$streak', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
                const Text('day surplus streak', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Streak = days where', style: TextStyle(color: Colors.white54, fontSize: 10)),
                const Text('Income > Expense', style: TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // ── MONTH NAVIGATOR ──
          Row(children: [
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.text1),
            ),
            Expanded(child: Center(
              child: Text('$monthLabel ${_viewMonth.year}',
                style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w800, fontSize: 16)),
            )),
            IconButton(
              onPressed: isCurrentMonth ? null : _nextMonth,
              icon: Icon(Icons.chevron_right_rounded,
                color: isCurrentMonth ? AppTheme.text2.withOpacity(0.3) : AppTheme.text1),
            ),
          ]),
          const SizedBox(height: 8),

          // ── DAY HEADERS (Mon–Sun) ──
          const Row(
            children: [
              _DayHeader('M'), _DayHeader('T'), _DayHeader('W'),
              _DayHeader('T'), _DayHeader('F'), _DayHeader('S'), _DayHeader('S'),
            ],
          ),
          const SizedBox(height: 6),

          // ── HEATMAP GRID ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final date = DateTime(_viewMonth.year, _viewMonth.month, day);
              final isFuture = date.isAfter(today);
              final key = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
              final data = dayMap[key];
              final isToday = date.year == today.year && date.month == today.month && date.day == today.day;

              Color cellColor;
              String statusEmoji;
              if (isFuture) {
                cellColor = AppTheme.surface;
                statusEmoji = '';
              } else if (data == null || (data.income == 0 && data.expense == 0)) {
                cellColor = const Color(0xFFB71C1C).withOpacity(0.7); // Red — missed
                statusEmoji = '🔴';
              } else if (data.income > data.expense) {
                cellColor = const Color(0xFF1B5E20).withOpacity(0.85); // Green — surplus
                statusEmoji = '🟢';
              } else {
                cellColor = const Color(0xFFE65100).withOpacity(0.85); // Orange — deficit
                statusEmoji = '🟠';
              }

              return GestureDetector(
                onTapUp: (details) => _showDayTooltip(context, details.globalPosition, day, date, data, isFuture, statusEmoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(7),
                    border: isToday
                        ? Border.all(color: AppTheme.accent, width: 2)
                        : Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Center(
                    child: Text('$day',
                      style: TextStyle(
                        color: isFuture ? AppTheme.text2 : Colors.white,
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── LEGEND ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Legend', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                _LegendRow(color: const Color(0xFF1B5E20), emoji: '🟢', label: 'Surplus — Income > Expense'),
                const SizedBox(height: 7),
                _LegendRow(color: const Color(0xFFE65100), emoji: '🟠', label: 'Deficit — Expense ≥ Income'),
                const SizedBox(height: 7),
                _LegendRow(color: const Color(0xFFB71C1C), emoji: '🔴', label: 'Missed — No transactions recorded'),
                const SizedBox(height: 7),
                _LegendRow(color: AppTheme.surface, emoji: '⬜', label: 'Future — Not yet reached'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── MONTH SUMMARY ──
          _MonthSummary(dayMap: dayMap, daysInMonth: daysInMonth, today: today, viewMonth: _viewMonth),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showDayTooltip(BuildContext context, Offset globalPos, int day, DateTime date,
      _DayData? data, bool isFuture, String statusEmoji) {
    if (isFuture) return;

    final net   = (data?.income ?? 0) - (data?.expense ?? 0);
    final label = '$statusEmoji ${_monthName(date.month)} $day, ${date.year}';

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 15)),
            const Divider(color: AppTheme.border, height: 20),
            if (data == null || (data.income == 0 && data.expense == 0))
              const Text('No transactions recorded this day.',
                style: TextStyle(color: AppTheme.text2, fontSize: 13))
            else ...[
              _TooltipRow('💰 Income',  fmtRupee(data!.income),  const Color(0xFF69F0AE)),
              const SizedBox(height: 8),
              _TooltipRow('💸 Expense', fmtRupee(data.expense), const Color(0xFFFF8A80)),
              const Divider(color: AppTheme.border, height: 16),
              _TooltipRow('📊 Net',     '${net >= 0 ? '+' : ''}${fmtRupee(net)}',
                net >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80)),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: AppTheme.accent)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Compute per-day income/expense across ALL transactions quickly
  _DayData? _dayDataFromState(AppState state, DateTime date) {
    double inc = 0, exp = 0;
    for (final tx in state.transactions) {
      if (tx.date.year == date.year && tx.date.month == date.month && tx.date.day == date.day) {
        if (tx.type == 'income')  inc += tx.amount;
        if (tx.type == 'expense') exp += tx.amount;
      }
    }
    if (inc == 0 && exp == 0) return null;
    return _DayData()..income = inc..expense = exp;
  }

  String _monthName(int m) => const [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ][m];
}

// ── DATA MODEL ────────────────────────────────────────────────
class _DayData {
  double income  = 0;
  double expense = 0;
}

// ── WIDGETS ───────────────────────────────────────────────────
class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader(this.label);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Text(label,
        style: const TextStyle(color: AppTheme.text2, fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  );
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String emoji;
  final String label;
  const _LegendRow({required this.color, required this.emoji, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 16, height: 16,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    ),
    const SizedBox(width: 10),
    Text('$emoji $label', style: const TextStyle(color: AppTheme.text2, fontSize: 12)),
  ]);
}

class _TooltipRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _TooltipRow(this.label, this.value, this.valueColor);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 13)),
    const Spacer(),
    Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w700, fontSize: 13)),
  ]);
}

// ── MONTH SUMMARY ─────────────────────────────────────────────
class _MonthSummary extends StatelessWidget {
  final Map<String, _DayData> dayMap;
  final int daysInMonth;
  final DateTime today;
  final DateTime viewMonth;
  const _MonthSummary({required this.dayMap, required this.daysInMonth, required this.today, required this.viewMonth});

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = viewMonth.year == today.year && viewMonth.month == today.month;
    final pastDays = isCurrentMonth ? today.day : daysInMonth;

    int green = 0, orange = 0, red = 0;
    for (int d = 1; d <= pastDays; d++) {
      final key = '${viewMonth.year}-${viewMonth.month.toString().padLeft(2,'0')}-${d.toString().padLeft(2,'0')}';
      final data = dayMap[key];
      if (data == null || (data.income == 0 && data.expense == 0)) {
        red++;
      } else if (data.income > data.expense) {
        green++;
      } else {
        orange++;
      }
    }

    double totalIncome  = dayMap.values.fold(0, (s, d) => s + d.income);
    double totalExpense = dayMap.values.fold(0, (s, d) => s + d.expense);
    double net = totalIncome - totalExpense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Month Summary', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          Row(children: [
            _SummaryChip(label: '🟢 Surplus', value: '$green days', color: const Color(0xFF1B5E20)),
            const SizedBox(width: 8),
            _SummaryChip(label: '🟠 Deficit', value: '$orange days', color: const Color(0xFFE65100)),
            const SizedBox(width: 8),
            _SummaryChip(label: '🔴 Missed',  value: '$red days',   color: const Color(0xFFB71C1C)),
          ]),
          const Divider(color: AppTheme.border, height: 20),
          _TooltipRow('💰 Total Income',  fmtRupee(totalIncome),  const Color(0xFF69F0AE)),
          const SizedBox(height: 6),
          _TooltipRow('💸 Total Expense', fmtRupee(totalExpense), const Color(0xFFFF8A80)),
          const SizedBox(height: 6),
          _TooltipRow('📊 Net',
            '${net >= 0 ? '+' : ''}${fmtRupee(net)}',
            net >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80)),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 9), textAlign: TextAlign.center),
      ]),
    ),
  );
}
