// Transactions screen — list, filter, add/edit/delete
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../constants.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final filtered = state.transactions.where((tx) {
      final matchType = _filterType == 'all' || tx.type == _filterType;
      final matchSearch = _searchQuery.isEmpty || tx.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchType && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── SEARCH BAR ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Search transactions…',
                prefixIcon: Icon(Icons.search, color: AppTheme.text2),
                isDense: true,
              ),
              style: const TextStyle(color: AppTheme.text1),
            ),
          ),
          // ── FILTER CHIPS ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              _FilterChip(label: 'All',      type: 'all',      selected: _filterType, onTap: (t) => setState(() => _filterType = t)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Income',   type: 'income',   selected: _filterType, onTap: (t) => setState(() => _filterType = t)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Expense',  type: 'expense',  selected: _filterType, onTap: (t) => setState(() => _filterType = t)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Transfer', type: 'transfer', selected: _filterType, onTap: (t) => setState(() => _filterType = t)),
            ]),
          ),
          // ── LIST ──
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('💸', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('No transactions found', style: TextStyle(color: AppTheme.text2)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => TransactionTile(
                      tx: filtered[i],
                      accounts: state.accounts,
                      onTap: () => _openTxSheet(context, existing: filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTxSheet(context),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _openTxSheet(BuildContext context, {TransactionModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _TxSheet(existing: existing),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, type, selected;
  final void Function(String) onTap;
  const _FilterChip({required this.label, required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.accent : AppTheme.border),
        ),
        child: Text(label, style: TextStyle(
          color: isActive ? Colors.black87 : AppTheme.text2,
          fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        )),
      ),
    );
  }
}

// ── ADD / EDIT TRANSACTION BOTTOM SHEET ──────────────────────
class _TxSheet extends ConsumerStatefulWidget {
  final TransactionModel? existing;
  const _TxSheet({this.existing});

  @override
  ConsumerState<_TxSheet> createState() => _TxSheetState();
}

class _TxSheetState extends ConsumerState<_TxSheet> {
  final _titleCtrl   = TextEditingController();
  final _amountCtrl  = TextEditingController();
  String _type = 'expense';
  String _category = 'food';
  DateTime _date = DateTime.now();
  String? _accountId;
  String? _accountToId;
  bool _recurring = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.existing;
    if (tx != null) {
      _titleCtrl.text  = tx.title;
      _amountCtrl.text = tx.amount.toString();
      _type            = tx.type;
      _category        = tx.category;
      _date            = tx.date;
      _accountId       = tx.accountId;
      _accountToId     = tx.accountToId;
      _recurring       = tx.isRecurring;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title  = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title and valid amount')));
      return;
    }
    final notifier = ref.read(appProvider.notifier);
    if (widget.existing != null) {
      final updated = widget.existing!
        ..title      = title
        ..amount     = amount
        ..type       = _type
        ..category   = _category
        ..date       = _date
        ..accountId  = _accountId
        ..accountToId= _accountToId
        ..isRecurring= _recurring;
      notifier.updateTransaction(updated);
    } else {
      notifier.addTransaction(
        title: title, amount: amount, type: _type, category: _category,
        date: _date, accountId: _accountId, accountToId: _accountToId, isRecurring: _recurring,
      );
    }
    Navigator.pop(context);
  }

  void _delete() {
    ref.read(appProvider.notifier).deleteTransaction(widget.existing!.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(appProvider);
    final accounts = state.accounts;
    final isEdit   = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(children: [
              Text(isEdit ? 'Edit Transaction' : 'Add Transaction',
                style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 18)),
              const Spacer(),
              if (isEdit) IconButton(icon: const Icon(Icons.delete, color: AppTheme.red), onPressed: _delete),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.text2), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            // Type selector
            Row(children: [
              _TypeBtn(label: 'Expense',  type: 'expense',  active: _type, color: AppTheme.red,   onTap: (t) => setState(() { _type=t; if(_category=='income') _category='food'; })),
              const SizedBox(width: 8),
              _TypeBtn(label: 'Income',   type: 'income',   active: _type, color: AppTheme.green, onTap: (t) => setState(() { _type=t; _category='income'; })),
              const SizedBox(width: 8),
              _TypeBtn(label: 'Transfer', type: 'transfer', active: _type, color: const Color(0xFF1E88E5), onTap: (t) => setState(() => _type=t)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              style: const TextStyle(color: AppTheme.text1),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
              style: const TextStyle(color: AppTheme.text1),
            ),
            const SizedBox(height: 10),
            // Category
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: AppTheme.card,
              decoration: const InputDecoration(labelText: 'Category'),
              style: const TextStyle(color: AppTheme.text1),
              items: kCategories.entries.map((e) => DropdownMenuItem(
                value: e.key,
                child: Row(children: [Text(e.value.icon), const SizedBox(width: 8), Text(e.key, style: const TextStyle(color: AppTheme.text1))]),
              )).toList(),
              onChanged: (v) { if (v != null) setState(() => _category = v); },
            ),
            const SizedBox(height: 10),
            // Account
            if (accounts.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _accountId,
                dropdownColor: AppTheme.card,
                decoration: const InputDecoration(labelText: 'Account'),
                style: const TextStyle(color: AppTheme.text1),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No account', style: TextStyle(color: AppTheme.text2))),
                  ...accounts.map((a) => DropdownMenuItem(value: a.id,
                    child: Row(children: [Text(a.icon), const SizedBox(width: 6), Text(a.name, style: const TextStyle(color: AppTheme.text1))]))),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              ),
              const SizedBox(height: 10),
            ],
            // To account (transfer)
            if (_type == 'transfer' && accounts.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _accountToId,
                dropdownColor: AppTheme.card,
                decoration: const InputDecoration(labelText: 'To Account'),
                style: const TextStyle(color: AppTheme.text1),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select account', style: TextStyle(color: AppTheme.text2))),
                  ...accounts.map((a) => DropdownMenuItem(value: a.id,
                    child: Row(children: [Text(a.icon), const SizedBox(width: 6), Text(a.name, style: const TextStyle(color: AppTheme.text1))]))),
                ],
                onChanged: (v) => setState(() => _accountToId = v),
              ),
              const SizedBox(height: 10),
            ],
            // Date
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _date,
                  firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accent)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface, border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: AppTheme.text2, size: 16),
                  const SizedBox(width: 8),
                  Text('${_date.day} / ${_date.month} / ${_date.year}', style: const TextStyle(color: AppTheme.text1)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            // Recurring toggle
            Row(children: [
              const Text('Recurring monthly', style: TextStyle(color: AppTheme.text2, fontSize: 13)),
              const Spacer(),
              Switch(
                value: _recurring,
                onChanged: (v) => setState(() => _recurring = v),
                activeColor: AppTheme.accent,
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Save Changes' : 'Add Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label, type, active;
  final Color color;
  final void Function(String) onTap;
  const _TypeBtn({required this.label, required this.type, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = type == active;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isActive ? color : AppTheme.border, width: isActive ? 1.5 : 1),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: isActive ? color : AppTheme.text2, fontSize: 13, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500)),
        ),
      ),
    );
  }
}
