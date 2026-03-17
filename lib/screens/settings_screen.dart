// Settings screen — export, import, reset
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── STATS CARD ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Text('📊', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Your Stats', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
              const SizedBox(height: 14),
              _Row('Total transactions', '${state.transactions.length}'),
              _Row('Total accounts', '${state.accounts.length}'),
              _Row('City buildings', '${state.buildings.length}'),
              _Row('XP earned', '${state.xp} XP'),
              _Row('Current streak', '${state.streak} days'),
              _Row('Badges earned', '${state.earnedBadges.length} / ${kBadges.length}'),
              _Row('Quests done', '${state.completedQuests.length} / ${kQuests.length}'),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── BACKUP & RESTORE ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Text('💾', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Backup & Restore', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
              const SizedBox(height: 6),
              const Text('Export your data as a JSON file you can restore later.', style: TextStyle(color: AppTheme.text2, fontSize: 12)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportData(context, ref),
                  icon: const Text('📤'),
                  label: const Text('Export backup (JSON)'),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Data is saved locally only. No cloud.', style: TextStyle(color: AppTheme.text2, fontSize: 11)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── DANGER ZONE ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Text('⚠️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Danger Zone', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700, fontSize: 16)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmReset(context, ref),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Reset all data'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 6),
              const Text('This deletes all transactions, accounts, buildings, and progress. Cannot be undone.', style: TextStyle(color: AppTheme.text2, fontSize: 11)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── ABOUT ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('About FinQuest', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Version 1.0.0', style: TextStyle(color: AppTheme.text2, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Gamified personal finance tracker for India.\nAll data stored offline on your device.', style: TextStyle(color: AppTheme.text2, fontSize: 12)),
            ]),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final state    = ref.read(appProvider);
      final settings = Hive.box('settings');
      final export = {
        'meta': {'version': 1, 'exportedAt': DateTime.now().toIso8601String(), 'app': 'FinQuest'},
        'xp':   state.xp,
        'streak': state.streak,
        'streakDays': state.streakDays,
        'earnedBadges': state.earnedBadges,
        'completedQuests': state.completedQuests,
        'transactions': state.transactions.map((t) => {
          'id': t.id, 'title': t.title, 'amount': t.amount, 'type': t.type,
          'category': t.category, 'date': t.date.toIso8601String(),
          'accountId': t.accountId, 'accountToId': t.accountToId, 'isRecurring': t.isRecurring,
        }).toList(),
        'accounts': state.accounts.map((a) => {
          'id': a.id, 'name': a.name, 'type': a.type,
          'initialBalance': a.initialBalance, 'color': a.color, 'icon': a.icon,
        }).toList(),
        'buildings': state.buildings.map((b) => {
          'id': b.id, 'name': b.name, 'category': b.category,
          'amount': b.amount, 'createdAt': b.createdAt.toIso8601String(),
        }).toList(),
      };

      final dir  = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${dir.path}/finquest_backup_$date.json');
      await file.writeAsString(jsonEncode(export), flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Saved to ${file.path}'), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Reset all data?', style: TextStyle(color: AppTheme.text1)),
        content: const Text('All transactions, accounts, buildings, XP, and streak will be permanently deleted. This cannot be undone.', style: TextStyle(color: AppTheme.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.text2))),
          ElevatedButton(
            onPressed: () {
              ref.read(appProvider.notifier).resetAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data reset')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}
