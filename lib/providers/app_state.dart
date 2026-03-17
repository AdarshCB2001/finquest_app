// Riverpod state provider — central app state management
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../models/account.dart';
import '../models/building.dart';
import '../constants.dart';

const _uuid = Uuid();

// ── APP STATE CLASS ───────────────────────────────────────────
class AppState {
  final List<TransactionModel> transactions;
  final List<AccountModel> accounts;
  final List<BuildingModel> buildings;
  final int xp;
  final int streak;
  final List<String> streakDays;
  final List<String> earnedBadges;
  final List<String> completedQuests;

  const AppState({
    this.transactions = const [],
    this.accounts = const [],
    this.buildings = const [],
    this.xp = 0,
    this.streak = 0,
    this.streakDays = const [],
    this.earnedBadges = const [],
    this.completedQuests = const [],
  });

  AppState copyWith({
    List<TransactionModel>? transactions,
    List<AccountModel>? accounts,
    List<BuildingModel>? buildings,
    int? xp,
    int? streak,
    List<String>? streakDays,
    List<String>? earnedBadges,
    List<String>? completedQuests,
  }) => AppState(
    transactions: transactions ?? this.transactions,
    accounts: accounts ?? this.accounts,
    buildings: buildings ?? this.buildings,
    xp: xp ?? this.xp,
    streak: streak ?? this.streak,
    streakDays: streakDays ?? this.streakDays,
    earnedBadges: earnedBadges ?? this.earnedBadges,
    completedQuests: completedQuests ?? this.completedQuests,
  );
}

// ── NOTIFIER ──────────────────────────────────────────────────
class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState()) {
    _load();
  }

  Box<TransactionModel> get _txBox => Hive.box<TransactionModel>('transactions');
  Box<AccountModel>     get _acctBox => Hive.box<AccountModel>('accounts');
  Box<BuildingModel>    get _bldgBox => Hive.box<BuildingModel>('buildings');
  Box                   get _settingsBox => Hive.box('settings');

  void _load() {
    final txs   = _txBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    final acts  = _acctBox.values.toList();
    final bldgs = _bldgBox.values.toList();
    final settings = _settingsBox;

    final streakDaysList = List<String>.from(settings.get('streakDays', defaultValue: <String>[]));
    final badges = List<String>.from(settings.get('earnedBadges', defaultValue: <String>[]));
    final quests = List<String>.from(settings.get('completedQuests', defaultValue: <String>[]));

    state = AppState(
      transactions: txs,
      accounts: acts,
      buildings: bldgs,
      xp: settings.get('xp', defaultValue: 0) as int,
      streak: _recalcStreak(streakDaysList),
      streakDays: streakDaysList,
      earnedBadges: badges,
      completedQuests: quests,
    );
  }

  void _save() {
    _settingsBox.put('xp', state.xp);
    _settingsBox.put('streak', state.streak);
    _settingsBox.put('streakDays', state.streakDays);
    _settingsBox.put('earnedBadges', state.earnedBadges);
    _settingsBox.put('completedQuests', state.completedQuests);
  }

  int _recalcStreak(List<String> days) {
    if (days.isEmpty) return 0;
    final sorted = [...{...days}]..sort();
    final today = todayStr();
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final last = sorted.last;
    if (last != today && last != yesterday) return 0;
    int count = 1;
    for (int i = sorted.length - 1; i > 0; i--) {
      final a = DateTime.parse(sorted[i]);
      final b = DateTime.parse(sorted[i - 1]);
      if (a.difference(b).inDays == 1) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  // ── XP ──────────────────────────────────────────────────
  void addXp(int amount) {
    state = state.copyWith(xp: state.xp + amount);
    _checkBadges();
    _checkQuests();
    _save();
  }

  // ── TRANSACTIONS ─────────────────────────────────────────
  void addTransaction({
    required String title,
    required double amount,
    required String type,
    required String category,
    required DateTime date,
    String? accountId,
    String? accountToId,
    bool isRecurring = false,
  }) {
    final tx = TransactionModel(
      id: _uuid.v4(),
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: date,
      accountId: accountId,
      accountToId: accountToId,
      isRecurring: isRecurring,
    );
    _txBox.put(tx.id, tx);

    // Update streak
    final today = todayStr();
    final days = [...state.streakDays];
    if (!days.contains(today)) days.add(today);
    final streak = _recalcStreak(days);

    state = state.copyWith(
      transactions: [tx, ...state.transactions],
      streakDays: days,
      streak: streak,
      xp: state.xp + (type == 'income' ? 20 : type == 'transfer' ? 5 : 10),
    );
    _checkBadges();
    _checkQuests();
    _save();
  }

  void updateTransaction(TransactionModel updated) {
    _txBox.put(updated.id, updated);
    final txs = state.transactions.map((t) => t.id == updated.id ? updated : t).toList();
    state = state.copyWith(transactions: txs, xp: state.xp + 5);
    _save();
  }

  void deleteTransaction(String id) {
    _txBox.delete(id);
    state = state.copyWith(transactions: state.transactions.where((t) => t.id != id).toList());
    _save();
  }

  // ── ACCOUNTS ─────────────────────────────────────────────
  void addAccount({
    required String name,
    required String type,
    required double initialBalance,
    required String color,
    required String icon,
  }) {
    final acct = AccountModel(
      id: _uuid.v4(),
      name: name,
      type: type,
      initialBalance: initialBalance,
      color: color,
      icon: icon,
    );
    _acctBox.put(acct.id, acct);
    state = state.copyWith(
      accounts: [...state.accounts, acct],
      xp: state.xp + 25,
    );
    _checkBadges();
    _save();
  }

  void deleteAccount(String id) {
    _acctBox.delete(id);
    state = state.copyWith(accounts: state.accounts.where((a) => a.id != id).toList());
    _save();
  }

  // ── BUILDINGS ─────────────────────────────────────────────
  void addBuilding({required String name, required String category, required double amount}) {
    final b = BuildingModel(
      id: _uuid.v4(),
      name: name,
      category: category,
      amount: amount,
      createdAt: DateTime.now(),
    );
    _bldgBox.put(b.id, b);
    final tier = getBuildingTier(amount);
    state = state.copyWith(
      buildings: [...state.buildings, b],
      xp: state.xp + 30 + (tier.index * 10),
    );
    _checkBadges();
    _checkQuests();
    _save();
  }

  void addFundsToBuilding(String id, double amount) {
    final bldg = state.buildings.firstWhere((b) => b.id == id);
    final oldTier = getBuildingTier(bldg.amount);
    bldg.amount += amount;
    _bldgBox.put(bldg.id, bldg);
    final newTier = getBuildingTier(bldg.amount);
    final upgraded = newTier.index > oldTier.index;
    final xpGain = upgraded ? (50 + newTier.index * 15) : 15;
    state = state.copyWith(
      buildings: [...state.buildings],
      xp: state.xp + xpGain,
    );
    _checkBadges();
    _save();
  }

  void deleteBuilding(String id) {
    _bldgBox.delete(id);
    state = state.copyWith(buildings: state.buildings.where((b) => b.id != id).toList());
    _save();
  }

  // ── DERIVED HELPERS ───────────────────────────────────────
  double getAccountBalance(AccountModel acct) {
    double bal = acct.initialBalance;
    for (final tx in state.transactions) {
      if (tx.type == 'expense' && tx.accountId == acct.id) bal -= tx.amount;
      else if (tx.type == 'income' && tx.accountId == acct.id) bal += tx.amount;
      else if (tx.type == 'transfer') {
        if (tx.accountId == acct.id) bal -= tx.amount;
        if (tx.accountToId == acct.id) bal += tx.amount;
      }
    }
    return bal;
  }

  double get netWorth {
    double total = 0;
    for (final a in state.accounts) { total += getAccountBalance(a); }
    return total;
  }

  // ── BADGES ────────────────────────────────────────────────
  void _checkBadges() {
    final badges = [...state.earnedBadges];
    bool changed = false;

    void chk(String id, bool cond) {
      if (!badges.contains(id) && cond) { badges.add(id); changed = true; }
    }

    chk('first_tx',       state.transactions.isNotEmpty);
    chk('first_building', state.buildings.isNotEmpty);
    chk('building_5',     state.buildings.length >= 5);
    chk('mansion',        state.buildings.any((b) => getBuildingTier(b.amount).index >= 6));
    chk('city_10',        state.buildings.length >= 10);
    chk('first_acct',    state.accounts.isNotEmpty);
    chk('accounts_3',    state.accounts.length >= 3);
    chk('streak_7',       state.streak >= 7);
    chk('streak_30',      state.streak >= 30);
    chk('invest_1',       state.transactions.any((t) => t.category == 'investment'));
    chk('transfer_1',     state.transactions.any((t) => t.type == 'transfer'));
    chk('quests_3',       state.completedQuests.length >= 3);
    chk('save_10k',       netWorth >= 10000);

    if (changed) state = state.copyWith(earnedBadges: badges);
  }

  // ── QUESTS ────────────────────────────────────────────────
  void _checkQuests() {
    final quests = [...state.completedQuests];
    bool changed = false;

    for (final q in kQuests) {
      if (quests.contains(q.id)) continue;
      bool done = false;
      switch (q.type) {
        case 'spend_total':
          final total = state.transactions.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
          done = total >= (q.target ?? 0);
          break;
        case 'streak':
          done = state.streak >= (q.target ?? 0);
          break;
        case 'buildings':
          done = state.buildings.length >= (q.target ?? 0);
          break;
        case 'accounts':
          done = state.accounts.length >= (q.target ?? 0);
          break;
        case 'cat_limit':
          final now = DateTime.now();
          final spent = state.transactions
              .where((t) => t.type == 'expense' && t.category == q.cat && t.date.month == now.month && t.date.year == now.year)
              .fold<double>(0, (s, t) => s + t.amount);
          done = spent > 0 && spent <= (q.limit ?? 0);
          break;
        case 'net_savings':
          done = netWorth >= (q.target ?? 0);
          break;
      }
      if (done) {
        quests.add(q.id);
        state = state.copyWith(xp: state.xp + q.xp, completedQuests: quests);
        changed = true;
      }
    }
    if (changed) state = state.copyWith(completedQuests: quests);
  }

  // ── SEED DEMO DATA ────────────────────────────────────────
  void seedDemoData() {
    // Accounts
    final accts = [
      AccountModel(id: 'demo_a1', name: 'SBI Savings',   type: 'bank',   initialBalance: 80000, color: '#1565C0', icon: '🏦'),
      AccountModel(id: 'demo_a2', name: 'Cash Wallet',   type: 'cash',   initialBalance: 5000,  color: '#2E7D32', icon: '💵'),
      AccountModel(id: 'demo_a3', name: 'HDFC Credit',   type: 'credit', initialBalance: 0,     color: '#C62828', icon: '💳'),
    ];
    for (final a in accts) _acctBox.put(a.id, a);

    // Buildings
    final bldgs = [
      BuildingModel(id:'demo_b1', name:'Goa Trip Fund',     category:'house',     amount:18000,  createdAt:DateTime.now()),
      BuildingModel(id:'demo_b2', name:'Zerodha Portfolio', category:'apartment', amount:85000,  createdAt:DateTime.now()),
      BuildingModel(id:'demo_b3', name:'AWS Course',        category:'school',    amount:12000,  createdAt:DateTime.now()),
      BuildingModel(id:'demo_b4', name:'Emergency Fund',    category:'bank',      amount:120000, createdAt:DateTime.now()),
      BuildingModel(id:'demo_b5', name:'Gym Membership',    category:'gym',       amount:7500,   createdAt:DateTime.now()),
    ];
    for (final b in bldgs) _bldgBox.put(b.id, b);

    // Transactions
    final now = DateTime.now();
    final txs = [
      TransactionModel(id:'demo_t1', title:'Monthly Salary',   amount:75000, type:'income',   category:'income',      date:now, accountId:'demo_a1'),
      TransactionModel(id:'demo_t2', title:'Swiggy Dinner',    amount:480,   type:'expense',  category:'food',        date:now, accountId:'demo_a3'),
      TransactionModel(id:'demo_t3', title:'Petrol Fill',      amount:1200,  type:'expense',  category:'transport',   date:now, accountId:'demo_a2'),
      TransactionModel(id:'demo_t4', title:'Transfer to Cash', amount:3000,  type:'transfer', category:'other',       date:now, accountId:'demo_a1', accountToId:'demo_a2'),
      TransactionModel(id:'demo_t5', title:'Electricity Bill', amount:1800,  type:'expense',  category:'bills',       date:now, accountId:'demo_a1'),
      TransactionModel(id:'demo_t6', title:'Blinkit Groceries',amount:2200,  type:'expense',  category:'food',        date:now, accountId:'demo_a3'),
    ];
    for (final t in txs) _txBox.put(t.id, t);

    _settingsBox.put('xp', 180);
    _settingsBox.put('streakDays', [todayStr()]);
    _settingsBox.put('hasOnboarded', true);
    _load();
  }

  void resetAllData() {
    _txBox.clear();
    _acctBox.clear();
    _bldgBox.clear();
    _settingsBox.clear();
    _settingsBox.put('hasOnboarded', true);
    state = const AppState();
  }
}

// ── PROVIDER ──────────────────────────────────────────────────
final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) => AppNotifier());
