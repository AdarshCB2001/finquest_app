// Achievements screen — stages, quests, badges
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(appProvider);
    final notifier = ref.read(appProvider.notifier);
    final netWorth = notifier.netWorth;
    final stage    = getStage(netWorth);
    final isMax    = stage.index == kStages.length - 1;
    final double stagePct = isMax
        ? 1.0
        : ((netWorth - stage.minNetWorth) /
               (kStages[stage.index + 1].minNetWorth - stage.minNetWorth))
            .clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── STAGE CARD ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF7B1FA2).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(stage.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Stage ${stage.index + 1} of ${kStages.length}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(stage.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                ]),
              ),
              if (isMax)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700)),
                  ),
                  child: const Text('👑 MAX', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w800, fontSize: 11)),
                ),
            ]),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stagePct, backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMax
                ? '🏆 You have reached the highest stage!'
                : '${fmtRupee(kStages[stage.index + 1].minNetWorth - netWorth)} more to ${kStages[stage.index + 1].name}',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 20),

        // ── STREAK ──
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${state.streak} day streak', style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 18)),
                Text('Log every day to keep it going!', style: const TextStyle(color: AppTheme.text2, fontSize: 12)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        // ── QUESTS ──
        const Text('Quests', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        ...kQuests.map((q) {
          final done = state.completedQuests.contains(q.id);
          double progress = 0;
          String label = '';
          switch (q.type) {
            case 'spend_total':
              final v = state.transactions.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
              progress = (v / (q.target ?? 1)).clamp(0, 1);
              label = '${fmtRupee(v.clamp(0, q.target ?? 0))} / ${fmtRupee(q.target ?? 0)}';
              break;
            case 'streak':
              progress = (state.streak / (q.target ?? 1)).clamp(0, 1);
              label = '${state.streak} / ${q.target?.round()} days';
              break;
            case 'buildings':
              progress = (state.buildings.length / (q.target ?? 1)).clamp(0, 1);
              label = '${state.buildings.length} / ${q.target?.round()} buildings';
              break;
            case 'accounts':
              progress = (state.accounts.length / (q.target ?? 1)).clamp(0, 1);
              label = '${state.accounts.length} / ${q.target?.round()} accounts';
              break;
            case 'cat_limit':
              final now = DateTime.now();
              final spent = state.transactions.where((t) => t.type == 'expense' && t.category == q.cat && t.date.month == now.month).fold<double>(0, (s, t) => s + t.amount);
              progress = spent <= (q.limit ?? 0) && spent > 0 ? 1 : 0;
              label = spent <= (q.limit ?? 0) ? 'On track: ${fmtRupee(spent)}' : 'Over: ${fmtRupee(spent)}';
              break;
            case 'net_savings':
              final net = state.transactions.fold<double>(0, (s, t) => t.type == 'income' ? s + t.amount : t.type == 'expense' ? s - t.amount : s);
              progress = (net / (q.target ?? 1)).clamp(0, 1);
              label = '${fmtRupee(net.clamp(0, q.target ?? 0))} / ${fmtRupee(q.target ?? 0)}';
              break;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: done ? const Color(0xFF1B5E20).withOpacity(0.3) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(q.icon, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(q.name, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (!done) ...[
                    Text(label, style: const TextStyle(color: AppTheme.text2, fontSize: 11)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress, backgroundColor: AppTheme.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                        minHeight: 4,
                      ),
                    ),
                  ] else
                    const Text('✅ Completed!', style: TextStyle(color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.w600)),
                ])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: done ? AppTheme.green.withOpacity(0.15) : AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('+${q.xp} XP', style: TextStyle(color: done ? AppTheme.green : AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 20),

        // ── BADGES ──
        const Text('Badges', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: kBadges.length,
          itemBuilder: (_, i) {
            final b    = kBadges[i];
            final earned = state.earnedBadges.contains(b.id);
            return Tooltip(
              message: b.desc,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: earned ? AppTheme.accent.withOpacity(0.12) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: earned ? AppTheme.accent.withOpacity(0.5) : AppTheme.border),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(b.icon, style: TextStyle(fontSize: 26, color: earned ? null : const Color(0xFF000000))),
                  const SizedBox(height: 4),
                  Text(b.name, style: TextStyle(color: earned ? AppTheme.text1 : AppTheme.text2.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  if (earned) Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 3), decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}


