// Accounts screen — manage bank/cash/UPI accounts
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../models/account.dart';
import '../theme/app_theme.dart';
import '../constants.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final notifier = ref.read(appProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Column(children: [
                Text('🏦', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text('No accounts yet', style: TextStyle(color: AppTheme.text2, fontSize: 15)),
                SizedBox(height: 4),
                Text('Add a bank account, cash wallet, or credit card below', style: TextStyle(color: AppTheme.text2, fontSize: 12), textAlign: TextAlign.center),
              ])),
            )
          else
            ...state.accounts.map((acct) {
              final bal = notifier.getAccountBalance(acct);
              final color = _hexColor(acct.color);
              final txCount = state.transactions.where((t) => t.accountId == acct.id || t.accountToId == acct.id).length;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(acct.icon, style: const TextStyle(fontSize: 22))),
                  ),
                  title: Text(acct.name, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w600)),
                  subtitle: Text('${kAccountTypes[acct.type] ?? acct.type}  ·  $txCount transactions',
                    style: const TextStyle(color: AppTheme.text2, fontSize: 12)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(fmtRupee(bal),
                      style: TextStyle(color: bal >= 0 ? AppTheme.green : AppTheme.red, fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('balance', style: const TextStyle(color: AppTheme.text2, fontSize: 10)),
                  ]),
                  onLongPress: () {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      backgroundColor: AppTheme.card,
                      title: Text('Remove ${acct.name}?', style: const TextStyle(color: AppTheme.text1)),
                      content: const Text('This will only remove the account, not its transactions.', style: TextStyle(color: AppTheme.text2)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.text2))),
                        TextButton(onPressed: () { notifier.deleteAccount(acct.id); Navigator.pop(context); },
                          child: const Text('Remove', style: TextStyle(color: AppTheme.red))),
                      ],
                    ));
                  },
                ),
              );
            }),

          const SizedBox(height: 8),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),
          // ── ADD ACCOUNT FORM ──
          const Text('Add Account', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          const _AddAccountForm(),
        ],
      ),
    );
  }
}

class _AddAccountForm extends ConsumerStatefulWidget {
  const _AddAccountForm();

  @override
  ConsumerState<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends ConsumerState<_AddAccountForm> {
  final _nameCtrl = TextEditingController();
  final _balCtrl  = TextEditingController();
  String _type  = 'bank';
  String _color = '#1565C0';
  String _icon  = '🏦';

  final _icons   = ['🏦', '💵', '💳', '📱', '💰', '📈', '🏧', '💎'];
  final _colors  = ['#1565C0', '#2E7D32', '#C62828', '#6A1B9A', '#E65100', '#D4AF37', '#00897B', '#546E7A'];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Account name'),
        style: const TextStyle(color: AppTheme.text1)),
      const SizedBox(height: 10),
      TextField(controller: _balCtrl, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Opening balance (₹)', prefixText: '₹ '),
        style: const TextStyle(color: AppTheme.text1)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(
        value: _type, dropdownColor: AppTheme.card,
        decoration: const InputDecoration(labelText: 'Type'),
        style: const TextStyle(color: AppTheme.text1),
        items: kAccountTypes.entries.map((e) => DropdownMenuItem(value: e.key,
          child: Text(e.value, style: const TextStyle(color: AppTheme.text1)))).toList(),
        onChanged: (v) { if (v != null) setState(() => _type = v); },
      ),
      const SizedBox(height: 12),
      // Icon picker
      const Text('Icon', style: TextStyle(color: AppTheme.text2, fontSize: 12)),
      const SizedBox(height: 6),
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _icons.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setState(() => _icon = _icons[i]),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _icon == _icons[i] ? AppTheme.accent.withOpacity(0.2) : AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _icon == _icons[i] ? AppTheme.accent : AppTheme.border, width: _icon == _icons[i] ? 2 : 1),
              ),
              child: Center(child: Text(_icons[i], style: const TextStyle(fontSize: 22))),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      // Color picker
      const Text('Color', style: TextStyle(color: AppTheme.text2, fontSize: 12)),
      const SizedBox(height: 6),
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _colors.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setState(() => _color = _colors[i]),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _hexColor(_colors[i]),
                shape: BoxShape.circle,
                border: _color == _colors[i] ? Border.all(color: Colors.white, width: 3) : null,
                boxShadow: _color == _colors[i] ? [BoxShadow(color: _hexColor(_colors[i]).withOpacity(0.5), blurRadius: 8)] : null,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final bal  = double.tryParse(_balCtrl.text) ?? 0;
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter account name')));
              return;
            }
            ref.read(appProvider.notifier).addAccount(name: name, type: _type, initialBalance: bal, color: _color, icon: _icon);
            _nameCtrl.clear(); _balCtrl.clear();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Account added!')));
          },
          child: const Text('Add Account'),
        ),
      ),
    ]);
  }
}

Color _hexColor(String hex) {
  try { return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); }
  catch (_) { return const Color(0xFF1565C0); }
}
