# 🏙️ FinQuest — App Flow & Structure

> Gamified offline personal finance tracker for Android, built with Flutter + Riverpod + Hive.

---

## App Launch Flow

```
App open
  │
  ├─ Hive boxes initialised (transactions, accounts, buildings, settings)
  │
  └─ hasOnboarded? ──No──▶ OnboardingScreen
                               │
                    ┌──────────┴──────────┐
                    │                     │
              Load demo data         Start fresh
                    │                     │
                    └──────────┬──────────┘
                               ▼
                          MainShell
                   (bottom nav + XP header)
```

---

## Folder Structure

```
lib/
├── main.dart                    # Entry point — Hive init, ProviderScope, routing
├── constants.dart               # All shared constants (categories, stages, building tiers, quests, badges)
│
├── models/                      # Hive data models (TypeAdapters generated via build_runner)
│   ├── transaction.dart / .g.dart
│   ├── account.dart / .g.dart
│   └── building.dart / .g.dart
│
├── providers/
│   └── app_state.dart           # Single Riverpod StateNotifier — all state + Hive persistence
│
├── theme/
│   └── app_theme.dart           # Dark theme colours, card styles, text styles
│
├── widgets/
│   ├── transaction_tile.dart     # Reusable transaction list row
│   └── city_painter.dart        # CustomPainter — isometric city canvas
│
└── screens/
    ├── onboarding_screen.dart   # First-launch welcome screen
    ├── main_shell.dart          # Scaffold + bottom nav + stage header
    ├── dashboard_screen.dart    # Home tab
    ├── transactions_screen.dart # Transactions tab
    ├── accounts_screen.dart     # Accounts tab
    ├── city_screen.dart         # City Builder tab
    ├── achievements_screen.dart # Achievements tab
    ├── reports_screen.dart      # Reports tab
    ├── settings_screen.dart     # Settings tab
    ├── stages_screen.dart       # ← Full stage info page (opened from header)
    └── streak_heatmap_screen.dart # ← Activity heatmap (opened from streak card)
```

---

## State Management

All state lives in **one** `AppNotifier` (`StateNotifier<AppState>`) inside `app_state.dart`, exposed via:

```dart
final appProvider = StateNotifierProvider<AppNotifier, AppState>(...);
```

### AppState fields

| Field | Type | Description |
|---|---|---|
| `transactions` | `List<TransactionModel>` | All logged transactions (sorted newest-first) |
| `accounts` | `List<AccountModel>` | Bank / cash / credit accounts |
| `buildings` | `List<BuildingModel>` | City buildings (savings goals) |
| `xp` | `int` | Internal XP (used for quests & badges — not displayed) |
| `streak` | `int` | Current consecutive-day streak |
| `streakDays` | `List<String>` | ISO date strings of logged days |
| `earnedBadges` | `List<String>` | Badge IDs unlocked |
| `completedQuests` | `List<String>` | Quest IDs completed |

### Persistence
- Every state-mutating method calls `_save()` which writes to a Hive `settings` box.
- `TransactionModel`, `AccountModel`, `BuildingModel` are each stored in their own named Hive box.
- On `AppNotifier` construction, `_load()` restores all state from Hive.

### Key computed helpers

```dart
double getAccountBalance(AccountModel acct)  // initial + income - expense +/- transfers
double get netWorth                          // sum of all account balances
```

---

## Data Models

### TransactionModel
| Field | Type |
|---|---|
| `id` | `String` (UUID) |
| `title` | `String` |
| `amount` | `double` |
| `type` | `'income' \| 'expense' \| 'transfer'` |
| `category` | `String` (key from `kCategories`) |
| `date` | `DateTime` |
| `accountId` | `String?` |
| `accountToId` | `String?` (transfer destination) |
| `isRecurring` | `bool` |

### AccountModel
| Field | Type |
|---|---|
| `id` | `String` (UUID) |
| `name` | `String` |
| `type` | `'bank' \| 'cash' \| 'credit' \| 'upi' \| 'savings' \| 'invest'` |
| `initialBalance` | `double` |
| `color` | `String` (hex) |
| `icon` | `String` (emoji) |

### BuildingModel
| Field | Type |
|---|---|
| `id` | `String` (UUID) |
| `name` | `String` |
| `category` | `String` (key from `kBuildingCats`) |
| `amount` | `double` |
| `createdAt` | `DateTime` |

---

## Constants (`constants.dart`)

### Financial Stages — `kStages` / `getStage(double netWorth)`
Driven by **net worth** (total account balances). Supports automatic promotion **and demotion**.

| # | Emoji | Stage | Min Net Worth |
|---|---|---|---|
| 1 | 🐷 | Piggy Bank Saver | ₹0 |
| 2 | 🛖 | Village Newcomer | ₹5,001 |
| 3 | 🏘️ | Town Dweller | ₹25,001 |
| 4 | 🏙️ | City Builder | ₹1,00,001 |
| 5 | 🏦 | Urban Investor | ₹5,00,001 |
| 6 | 🏢 | Metro Mogul | ₹25,00,001 |
| 7 | 🌆 | Corporate Titan | ₹1,00,00,001 |
| 8 | 🌇 | Tycoon | ₹10,00,00,001 |
| 9 | 🌃 | Business Empire | ₹1,00,00,00,001 |
| 10 | 💎 | Billionaire | ₹10,00,00,00,001 |

### Building Tiers — `kBuildingTiers` / `getBuildingTier(double amount)`
Determined by the **amount invested in a single building**.

| Tier | Emoji | Name | Min Amount |
|---|---|---|---|
| 0 | 🟫 | Empty Plot | ₹0 |
| 1 | 🛖 | Hut | ₹5,000 |
| 2 | 🏚️ | Basic House | ₹10,000 |
| 3 | 🏠 | House | ₹25,000 |
| 4 | 🏡 | Bungalow | ₹50,000 |
| 5 | 🏘️ | Villa | ₹1,00,000 |
| 6 | 🏰 | Mansion | ₹5,00,000 |

### City Levels — `kCityLevels` / `getCityLevel(int count)`
Determined by the **number of buildings** in the city.

| Name | Min Buildings |
|---|---|
| Empty Land | 0 |
| Village | 1 |
| Town | 5 |
| City | 10 |
| Metropolis | 20 |
| Megacity | 35 |

### Transaction Categories — `kCategories`
`food`, `transport`, `shopping`, `entertainment`, `bills`, `health`, `education`, `investment`, `income`, `other`

### Building Categories — `kBuildingCats`
`house`, `apartment`, `school`, `hospital`, `gym`, `restaurant`, `mall`, `bank`

---

## Screen-by-Screen Reference

### `OnboardingScreen`
- Shown only on first launch (`hasOnboarded` flag in Hive settings box).
- Two CTAs: **Load demo data** (calls `seedDemoData()`) or **Start fresh**.
- Redirects to `MainShell` using `pushReplacement`.

---

### `MainShell`
- Hosts the **global stage header** (top bar) and a `BottomNavigationBar` with 7 tabs.
- Header shows:
  - `🏙️ FinQuest` logo/title
  - Tappable **stage chip** (emoji + stage name + `›`) → opens `StagesScreen`
  - Thin progress bar showing net worth progress toward the next stage threshold
- Uses `IndexedStack` so all tab states are preserved.

**Tabs:**

| Tab | Screen |
|---|---|
| 🏠 Home | `DashboardScreen` |
| 💸 Transactions | `TransactionsScreen` |
| 🏦 Accounts | `AccountsScreen` |
| 🏙️ City | `CityScreen` |
| 🏅 Achievements | `AchievementsScreen` |
| 📊 Reports | `ReportsScreen` |
| ⚙️ Settings | `SettingsScreen` |

---

### `DashboardScreen`
- **Net Worth card** — gradient card showing total net worth, this-month income, expense, and savings rate %.
- **Daily Streak card** — shows current streak + Mon–Sun week dots. **Tappable → `StreakHeatmapScreen`**.
- **Accounts carousel** — horizontal scroll of account balance cards (if accounts exist).
- **This Month breakdown** — top expense categories with bar indicators.
- **Recent Transactions** — last 6 transactions using `TransactionTile`.

---

### `TransactionsScreen`
- Search bar (full-text filter on title).
- Filter chips: All / Income / Expense / Transfer.
- Scrollable list of `TransactionTile` widgets.
- FAB → opens `_TxSheet` (modal bottom sheet) to Add.
- Tapping a tile → opens `_TxSheet` pre-filled to Edit or Delete.
- **`_TxSheet`**: type selector (Expense / Income / Transfer), title, amount, category dropdown, account dropdown, to-account (for transfers), date picker, recurring toggle.

---

### `AccountsScreen`
- List of accounts: icon, name, type, transaction count, live balance.
- Long-press → confirm-delete dialog.
- Inline **Add Account form**: name, opening balance, type dropdown, emoji icon picker, colour swatch picker.

---

### `CityScreen`
- **City header**: city level name, building count, total invested.
- **Isometric canvas** (`CityIsometricPainter` via `CustomPaint`): 320px high interactive city map. Tap to cycle through buildings.
- **Selected building card**: shows tier, current amount, next tier target, and an **Add Funds** input.
- **Buildings list**: each card shows category icon, tier badge, progress bar to next tier, with delete option.
- **Add Building form**: category picker (horizontal scroll), name field, amount field → calls `addBuilding()`.

---

### `AchievementsScreen`
- **Stage card** — purple gradient card showing current stage, progress bar to next stage, and net worth remaining.
- **Streak row** — current streak count.
- **Quests list** — each quest shows progress bar + reward label. Completed quests show ✅.
- **Badges grid** — 4-column grid of all badges. Earned ones glow with accent border; unearned are dimmed.

---

### `ReportsScreen`
- **Expense Pie Chart** (`fl_chart`) — category breakdown with colour legend.
- **Income vs Expense Line Chart** — last 6 months trend (two lines: green = income, red = expense).
- **Summary stats** — all-time totals: transactions count, income, expenses, net balance, city investment.

---

### `SettingsScreen`
- **Your Stats** card — transactions, accounts, buildings, streak, badges, quests.
- **Backup & Restore** — exports full data as `finquest_backup_YYYY-MM-DD.json` to device storage.
- **Danger Zone** — Reset all data (with confirmation dialog).
- **About** — version & description.

---

### `StagesScreen` *(new — tapped from header)*
- **Current Stage card** — navy gradient, shows emoji, stage name, stage number, net worth, and progress bar to next stage.
- **How Stages Work** section — explains promotion, demotion, and real-life grounding.
- **All 10 stages list** — each row shows: index bubble, emoji, name, ₹ range. Current stage highlighted in accent with `YOU` chip; unlocked show ✅; locked show 🔒.

---

### `StreakHeatmapScreen` *(new — tapped from streak card)*
- **Streak banner** — shows current surplus streak (days where income > expense).
- **Month navigator** — `◀ ▶` buttons to move between months (capped at current month).
- **Heatmap grid** — 7-column (Mon–Sun), one cell per day:
  - 🟢 Green — Income > Expense
  - 🟠 Orange — Expense ≥ Income
  - 🔴 Red — No transactions recorded
  - ⬜ Grey — Future date
  - Today highlighted with accent border
- **Day detail dialog** — tap any past day to see income, expense, and net for that day.
- **Legend** — colour key.
- **Month Summary card** — count of green/orange/red days + total income, expense, net for the month.

---

## Gamification System

### XP
XP is earned internally and tracked in `AppState.xp`. It is **not displayed in the UI** but drives badge and quest unlock logic.

| Action | XP |
|---|---|
| Log income | +20 |
| Log expense | +10 |
| Transfer | +5 |
| Edit transaction | +5 |
| Add account | +25 |
| Add/upgrade building | +30–80+ |

### Financial Stages
Computed live from `netWorth` via `getStage()`. No stored value — demotes automatically if net worth drops.

### Quests (7 total)
One-time completion quests tracked by `completedQuests` list. Examples:
- Track ₹5,000 in expenses (+100 XP)
- 7-day streak (+150 XP)
- Build 5 buildings (+150 XP)
- Reach ₹10,000 net savings (+200 XP)

### Badges (14 total)
One-time unlock badges tracked by `earnedBadges`. Examples: First Step, First Brick, Week Warrior, Lakhpati Jr., Niveshak.

---

## Key Dependencies

| Package | Version | Use |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | State management |
| `hive` + `hive_flutter` | ^2.2.3 / ^1.1.0 | Offline local database |
| `fl_chart` | ^0.68.0 | Pie chart & line chart in Reports |
| `uuid` | ^4.3.3 | UUID generation for IDs |
| `path_provider` | ^2.1.2 | File path for JSON backup export |
