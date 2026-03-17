// Transaction tile widget — reusable across Dashboard and Transactions screens
import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../models/account.dart';
import '../constants.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final List<AccountModel> accounts;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.tx, required this.accounts, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = kCategories[tx.category] ?? kCategories['other']!;
    final acct = accounts.where((a) => a.id == tx.accountId).firstOrNull;
    final sign   = tx.type == 'income' ? '+' : tx.type == 'transfer' ? '⇄' : '-';
    final amtColor = tx.type == 'income' ? AppTheme.green : tx.type == 'transfer' ? const Color(0xFF1E88E5) : AppTheme.red;
    final acctColor = acct != null ? _hexColor(acct.color) : cat.color;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            // Left accent bar
            Container(width: 4, height: 44, decoration: BoxDecoration(color: acctColor, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            // Category icon
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cat.bg, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            // Title & meta
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.title, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                Text(_fmtDate(tx.date), style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
                if (acct != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: acctColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: acctColor.withOpacity(0.4)),
                    ),
                    child: Text('${acct.icon} ${acct.name}',
                      style: TextStyle(color: acctColor, fontSize: 10, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (tx.isRecurring) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('🔄', style: TextStyle(fontSize: 9)),
                  ),
                ],
              ]),
            ])),
            // Amount
            Text('$sign${fmtRupee(tx.amount)}',
              style: TextStyle(color: amtColor, fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

Color _hexColor(String hex) {
  try { return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); }
  catch (_) { return const Color(0xFF1565C0); }
}
