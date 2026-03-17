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
    final state = ref.watch(appProvider);
    final level = getLevel(state.xp);
    final pct = level.maxXp < 999999
        ? ((state.xp - level.minXp) / (level.maxXp - level.minXp)).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      body: Column(
        children: [
          // ── XP HEADER ──
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text('${state.xp} XP', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${level.name}', style: const TextStyle(color: AppTheme.text1, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
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
