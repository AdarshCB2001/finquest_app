# 🏙️ FinQuest — Gamified Personal Finance Tracker

> Track your money. Build your city. Level up your finances.

FinQuest is an offline-first Flutter Android app that turns personal finance management into a rewarding game. Save money, complete quests, earn achievements, and watch your digital city grow!

---

## ✨ Features

| Feature | Description |
|---|---|
| 📊 **Dashboard** | Overview of your net worth, income, expenses, and recent transactions |
| 💸 **Transactions** | Log income and expenses with categories, notes, and account assignment |
| 🏦 **Accounts** | Manage multiple accounts (cash, bank, savings, etc.) |
| 📈 **Reports** | Visualise spending trends with charts, category breakdowns, and summaries |
| 🏙️ **City Builder** | A 3D-style city that grows as your savings increase — gamified saving! |
| 🏆 **Achievements** | Unlock badges and milestones for good financial habits |
| ⚙️ **Settings** | Customise the app, export data, and manage preferences |

---

## 🎮 Gamification

FinQuest makes finance fun by rewarding healthy money habits:

- **City Level** — Every rupee saved contributes XP to grow your city from a small village to a sprawling metropolis
- **Buildings** — Unlock new buildings (houses, parks, towers) as your savings milestones are hit
- **Achievements** — Earn badges for streaks, first transactions, savings goals, and more
- **Quests** *(coming soon)* — Complete weekly financial challenges for bonus XP

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | [Flutter](https://flutter.dev/) (Dart) |
| State Management | [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) |
| Local Database | [Hive](https://docs.hivedb.dev/) (fully offline, no backend needed) |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Unique IDs | [uuid](https://pub.dev/packages/uuid) |
| File Export | [path_provider](https://pub.dev/packages/path_provider) |

---

## 📁 Project Structure

```
lib/
├── main.dart               # App entry point & Hive initialisation
├── constants.dart          # App-wide constants (categories, colors, XP values)
├── theme/                  # App theme and color scheme
├── models/                 # Hive data models (Transaction, Account, Building)
├── providers/              # Riverpod state providers
├── screens/                # All app screens
│   ├── dashboard_screen.dart
│   ├── transactions_screen.dart
│   ├── accounts_screen.dart
│   ├── reports_screen.dart
│   ├── city_screen.dart
│   ├── achievements_screen.dart
│   ├── settings_screen.dart
│   ├── onboarding_screen.dart
│   └── main_shell.dart     # Bottom navigation shell
└── widgets/                # Reusable UI components
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.0.0)
- Android Studio or VS Code with the Flutter extension
- An Android device or emulator (API level 21+)

### Installation

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd finquest_app

# 2. Install dependencies
flutter pub get

# 3. Run code generation for Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run on a connected Android device
flutter run
```

### Build APK (for direct installation)

```bash
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📦 Data & Privacy

- **100% Offline** — All data is stored locally on your device using Hive
- **No internet required** — The app works completely without a network connection
- **No accounts or tracking** — Your financial data never leaves your device

---

## 🗺️ Roadmap

- [ ] Weekly quests system
- [ ] Budget / spending limits with alerts
- [ ] Data export to CSV
- [ ] Recurring transactions
- [ ] Dark / Light theme toggle
- [ ] React web companion app

---

## 📄 License

This project is for personal use. All rights reserved.
