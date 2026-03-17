// Stages screen — shows all 10 financial stages based on net worth
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';

class StagesScreen extends ConsumerWidget {
  const StagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appProvider.notifier);
    final netWorth = notifier.netWorth;
    final currentStage = getStage(netWorth);
    final isMax = currentStage.index == kStages.length - 1;

    // Progress toward next stage
    double stagePct = 1.0;
    String progressLabel = 'MAX';
    FinStage? nextStage;
    if (!isMax) {
      nextStage = kStages[currentStage.index + 1];
      final range = nextStage.minNetWorth - currentStage.minNetWorth;
      stagePct = ((netWorth - currentStage.minNetWorth) / range).clamp(0.0, 1.0);
      final remaining = nextStage.minNetWorth - netWorth;
      progressLabel = '${fmtRupee(remaining)} more to ${nextStage.name}';
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.text1, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Financial Stages',
          style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── CURRENT STAGE CARD ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF283593)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Stage', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(children: [
                  Text(currentStage.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        currentStage.name,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stage ${currentStage.index + 1} of ${kStages.length}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ]),
                  ),
                  if (isMax)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD700)),
                      ),
                      child: const Text('👑 MAX', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                ]),
                const SizedBox(height: 16),
                // Net worth display
                Text(
                  'Net Worth: ${fmtRupee(netWorth)}',
                  style: TextStyle(
                    color: netWorth >= 0 ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isMax) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stagePct,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    progressLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── HOW STAGES WORK ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('📖', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Text('How Stages Work', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
                const SizedBox(height: 12),
                _InfoRow(
                  emoji: '📈',
                  title: 'Based on net worth',
                  body: 'Your stage is determined by your total net worth — the combined balance of all your accounts.',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  emoji: '⬆️',
                  title: 'Automatic promotion',
                  body: 'As your net worth grows past a threshold, you are automatically promoted to the next stage.',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  emoji: '⬇️',
                  title: 'Demotion is real',
                  body: 'Just like in real life — if your net worth drops below the minimum for your current stage, you get demoted. There are no shortcuts.',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  emoji: '🌍',
                  title: 'Real-life simulation',
                  body: 'The thresholds are designed to reflect actual financial milestones in the Indian context. Reaching Billionaire (₹100 Cr+) is intentionally very hard.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── ALL STAGES LIST ────────────────────────────────────
          const Text('All Stages', style: TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 10),
          ...kStages.map((stage) => _StageTile(
                stage: stage,
                isCurrent: stage.index == currentStage.index,
                isUnlocked: netWorth >= stage.minNetWorth,
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── INFO ROW ──────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _InfoRow({required this.emoji, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(emoji, style: const TextStyle(fontSize: 15)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: AppTheme.text2, fontSize: 12, height: 1.4)),
        ]),
      ),
    ]);
  }
}

// ── STAGE TILE ────────────────────────────────────────────────
class _StageTile extends StatelessWidget {
  final FinStage stage;
  final bool isCurrent;
  final bool isUnlocked;
  const _StageTile({required this.stage, required this.isCurrent, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final isMax = stage.index == kStages.length - 1;
    final nextMin = isMax ? null : kStages[stage.index + 1].minNetWorth;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.accent.withOpacity(0.08) : AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppTheme.accent : AppTheme.border,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Stage index bubble
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: isUnlocked
                ? (isCurrent ? AppTheme.accent : const Color(0xFF2E7D32).withOpacity(0.2))
                : AppTheme.surface,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${stage.index + 1}',
              style: TextStyle(
                color: isUnlocked
                    ? (isCurrent ? Colors.black : const Color(0xFF69F0AE))
                    : AppTheme.text2,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Emoji
        Text(
          stage.emoji,
          style: TextStyle(fontSize: 22, color: isUnlocked ? null : null),
        ),
        const SizedBox(width: 10),

        // Name & range
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              stage.name,
              style: TextStyle(
                color: isCurrent ? AppTheme.accent : AppTheme.text1,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isMax
                  ? '${fmtRupee(stage.minNetWorth)} and above'
                  : '${fmtRupee(stage.minNetWorth)} – ${fmtRupee(nextMin!)}',
              style: const TextStyle(color: AppTheme.text2, fontSize: 11),
            ),
          ]),
        ),

        // Status badge
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('YOU', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 10)),
          )
        else if (isUnlocked)
          const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18)
        else if (isMax)
          const Text('👑', style: TextStyle(fontSize: 14))
        else
          const Icon(Icons.lock_outline_rounded, color: AppTheme.text2, size: 16),
      ]),
    );
  }
}
