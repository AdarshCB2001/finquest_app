// Onboarding screen — shown only on first launch
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  void _proceed(BuildContext context, WidgetRef ref, bool loadDemo) {
    if (loadDemo) {
      ref.read(appProvider.notifier).seedDemoData();
    } else {
      Hive.box('settings').put('hasOnboarded', true);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              // Logo & title
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Center(child: Text('🏙️', style: TextStyle(fontSize: 44))),
              ),
              const SizedBox(height: 24),
              const Text(
                'FinQuest',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.text1, letterSpacing: -1),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your finances. Your city.',
                style: TextStyle(fontSize: 16, color: AppTheme.text2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Feature pills
              Wrap(
                spacing: 10, runSpacing: 10,
                alignment: WrapAlignment.center,
                children: const [
                  _FeaturePill(icon: '🏦', text: 'Track accounts'),
                  _FeaturePill(icon: '💸', text: 'Log expenses'),
                  _FeaturePill(icon: '🏙️', text: 'Build your city'),
                  _FeaturePill(icon: '🎯', text: 'Complete quests'),
                  _FeaturePill(icon: '📊', text: 'View reports'),
                  _FeaturePill(icon: '✈️', text: '100% offline'),
                ],
              ),
              const Spacer(),
              // CTA buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _proceed(context, ref, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎮', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text('Load demo data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _proceed(context, ref, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.text1,
                    side: const BorderSide(color: AppTheme.border, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text('Start fresh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'All data stays on your phone. No sign-up needed.',
                style: TextStyle(color: AppTheme.text2, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String icon;
  final String text;
  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppTheme.text1, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
