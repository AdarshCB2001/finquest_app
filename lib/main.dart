// FinQuest - Main Entry Point
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/transaction.dart';
import 'models/account.dart';
import 'models/building.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local database
  await Hive.initFlutter();

  // Register type adapters
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(AccountModelAdapter());
  Hive.registerAdapter(BuildingModelAdapter());

  // Open boxes (offline storage)
  await Hive.openBox<TransactionModel>('transactions');
  await Hive.openBox<AccountModel>('accounts');
  await Hive.openBox<BuildingModel>('buildings');
  await Hive.openBox('settings');

  runApp(
    const ProviderScope(child: FinQuestApp()),
  );
}

class FinQuestApp extends StatelessWidget {
  const FinQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasOnboarded =
        Hive.box('settings').get('hasOnboarded', defaultValue: false) as bool;
    return MaterialApp(
      title: 'FinQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: hasOnboarded ? const MainShell() : const OnboardingScreen(),
    );
  }
}
