// Main shell with bottom navigation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../constants.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'accounts_screen.dart';
import 'city_screen.dart';
import 'achievements_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'stages_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    AccountsScreen(),
    CityScreen(),
    AchievementsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(appProvider.notifier);
    // Watch state so header rebuilds when net worth changes
    ref.watch(appProvider);
    final netWorth = notifier.netWorth;
    final stage = getStage(netWorth);
    final isMax = stage.index == kStages.length - 1;

    // Progress toward next stage threshold
    double stagePct;
    if (isMax) {
      stagePct = 1.0;
    } else {
      final next = kStages[stage.index + 1];
      final range = next.minNetWorth - stage.minNetWorth;
      stagePct = ((netWorth - stage.minNetWorth) / range).clamp(0.0, 1.0);
    }

    return Scaffold(
      body: Column(
        children: [
          // ── STAGE HEADER ──
          Container(
            color: AppTheme.surface,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16, right: 16, bottom: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🏙️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text('FinQuest', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.text1)),
                    const Spacer(),
                    // Tappable stage chip → opens StagesScreen
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StagesScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(stage.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Text(
                              stage.name,
                              style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, color: AppTheme.accent, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Stage progress bar (net worth toward next stage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stagePct,
                    backgroundColor: AppTheme.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          // ── SCREENS ──
          Expanded(child: IndexedStack(index: _selectedIndex, children: _screens)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppTheme.accent,
          unselectedItemColor: AppTheme.text2,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Text('🏠', style: TextStyle(fontSize: 20)), label: 'Home'),
            BottomNavigationBarItem(icon: Text('💸', style: TextStyle(fontSize: 20)), label: 'Transactions'),
            BottomNavigationBarItem(icon: Text('🏦', style: TextStyle(fontSize: 20)), label: 'Accounts'),
            BottomNavigationBarItem(icon: Text('🏙️', style: TextStyle(fontSize: 20)), label: 'City'),
            BottomNavigationBarItem(icon: Text('🏅', style: TextStyle(fontSize: 20)), label: 'Achievements'),
            BottomNavigationBarItem(icon: Text('📊', style: TextStyle(fontSize: 20)), label: 'Reports'),
            BottomNavigationBarItem(icon: Text('⚙️', style: TextStyle(fontSize: 20)), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
