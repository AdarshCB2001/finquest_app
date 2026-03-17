// App-wide constants: categories, levels, building tiers, quests, badges
import 'package:flutter/material.dart';

// ── EXPENSE / INCOME CATEGORIES ──────────────────────────────
class AppCategory {
  final String key;
  final String icon;
  final Color color;
  final Color bg;
  const AppCategory({required this.key, required this.icon, required this.color, required this.bg});
}

const Map<String, AppCategory> kCategories = {
  'food':          AppCategory(key:'food',          icon:'🍛', color:Color(0xFFFF6B00), bg:Color(0xFFFFF3E8)),
  'transport':     AppCategory(key:'transport',     icon:'🚌', color:Color(0xFF0050A0), bg:Color(0xFFE8F0FB)),
  'shopping':      AppCategory(key:'shopping',      icon:'🛒', color:Color(0xFF8E24AA), bg:Color(0xFFF3E5F5)),
  'entertainment': AppCategory(key:'entertainment', icon:'🎬', color:Color(0xFFE53935), bg:Color(0xFFFFEBEE)),
  'bills':         AppCategory(key:'bills',         icon:'💡', color:Color(0xFFF9A825), bg:Color(0xFFFFFDE7)),
  'health':        AppCategory(key:'health',        icon:'🏥', color:Color(0xFF00897B), bg:Color(0xFFE0F2F1)),
  'education':     AppCategory(key:'education',     icon:'📚', color:Color(0xFF1565C0), bg:Color(0xFFE3F2FD)),
  'investment':    AppCategory(key:'investment',    icon:'📈', color:Color(0xFF2E7D32), bg:Color(0xFFE8F5E9)),
  'income':        AppCategory(key:'income',        icon:'💰', color:Color(0xFF138808), bg:Color(0xFFE8F5E9)),
  'other':         AppCategory(key:'other',         icon:'📦', color:Color(0xFF546E7A), bg:Color(0xFFECEFF1)),
};

// ── FINANCIAL STAGES (net-worth based, supports demotion) ────
class FinStage {
  final int index;
  final String emoji;
  final String name;
  final double minNetWorth; // inclusive lower bound in ₹
  const FinStage({
    required this.index,
    required this.emoji,
    required this.name,
    required this.minNetWorth,
  });
}

const List<FinStage> kStages = [
  FinStage(index: 0, emoji: '🐷', name: 'Piggy Bank Saver', minNetWorth: 0),
  FinStage(index: 1, emoji: '🛖', name: 'Village Newcomer',  minNetWorth: 5001),
  FinStage(index: 2, emoji: '🏘️', name: 'Town Dweller',      minNetWorth: 25001),
  FinStage(index: 3, emoji: '🏙️', name: 'City Builder',      minNetWorth: 100001),
  FinStage(index: 4, emoji: '🏦', name: 'Urban Investor',    minNetWorth: 500001),
  FinStage(index: 5, emoji: '🏢', name: 'Metro Mogul',       minNetWorth: 2500001),
  FinStage(index: 6, emoji: '🌆', name: 'Corporate Titan',   minNetWorth: 10000001),
  FinStage(index: 7, emoji: '🌇', name: 'Tycoon',            minNetWorth: 100000001),
  FinStage(index: 8, emoji: '🌃', name: 'Business Empire',   minNetWorth: 1000000001),
  FinStage(index: 9, emoji: '💎', name: 'Billionaire',       minNetWorth: 10000000001),
];

/// Returns the current stage for a given net worth.
/// Stage can be demoted if net worth drops below the current stage threshold.
FinStage getStage(double netWorth) {
  for (int i = kStages.length - 1; i >= 0; i--) {
    if (netWorth >= kStages[i].minNetWorth) return kStages[i];
  }
  return kStages[0];
}

// ── ACCOUNT TYPES ─────────────────────────────────────────────
const Map<String, String> kAccountTypes = {
  'bank':    'Bank account',
  'cash':    'Cash wallet',
  'credit':  'Credit card',
  'upi':     'UPI wallet',
  'savings': 'Savings',
  'invest':  'Investment',
};

// ── BUILDING CATEGORIES ───────────────────────────────────────
class BuildingCat {
  final String key;
  final String icon;
  final Color color;
  final Color bg;
  final String label;
  final String desc;
  const BuildingCat({required this.key, required this.icon, required this.color, required this.bg, required this.label, required this.desc});
}

const Map<String, BuildingCat> kBuildingCats = {
  'house':      BuildingCat(key:'house',      icon:'🏠', color:Color(0xFFE65100), bg:Color(0xFFFFF3E8), label:'House',      desc:'Personal savings goals — car, trip, gadget, wedding'),
  'apartment':  BuildingCat(key:'apartment',  icon:'🏢', color:Color(0xFF1565C0), bg:Color(0xFFE3F2FD), label:'Apartment',  desc:'SIPs, mutual funds, stocks, gold, crypto, PPF'),
  'school':     BuildingCat(key:'school',     icon:'🏫', color:Color(0xFF6A1B9A), bg:Color(0xFFF3E5F5), label:'School',     desc:'Education — courses, certificates, college fees'),
  'hospital':   BuildingCat(key:'hospital',   icon:'🏥', color:Color(0xFF00897B), bg:Color(0xFFE0F2F1), label:'Hospital',   desc:'Medical — doctor, surgery, medicines, insurance'),
  'gym':        BuildingCat(key:'gym',        icon:'🏋️', color:Color(0xFF2E7D32), bg:Color(0xFFE8F5E9), label:'Gym',        desc:'Health & fitness — memberships, gear, yoga'),
  'restaurant': BuildingCat(key:'restaurant', icon:'🍽️', color:Color(0xFFFF6B00), bg:Color(0xFFFFF3E8), label:'Restaurant', desc:'Food & dining — eating out, Swiggy, Zomato'),
  'mall':       BuildingCat(key:'mall',       icon:'🛍️', color:Color(0xFF8E24AA), bg:Color(0xFFF3E5F5), label:'Mall',       desc:'Lifestyle & retail — clothes, electronics, subs'),
  'bank':       BuildingCat(key:'bank',       icon:'🏦', color:Color(0xFFD4AF37), bg:Color(0xFFFFFDE7), label:'Bank',       desc:'Emergency fund, FDs, liquid savings'),
};

// ── BUILDING TIERS ────────────────────────────────────────────
class BuildingTier {
  final int index;
  final String name;
  final String emoji;
  final double minAmount;
  final double maxAmount;
  const BuildingTier({required this.index, required this.name, required this.emoji, required this.minAmount, required this.maxAmount});
}

const List<BuildingTier> kBuildingTiers = [
  BuildingTier(index:0, name:'Empty Plot',  emoji:'🟫', minAmount:0,      maxAmount:4999),
  BuildingTier(index:1, name:'Hut',         emoji:'🛖', minAmount:5000,   maxAmount:9999),
  BuildingTier(index:2, name:'Basic House', emoji:'🏚️', minAmount:10000,  maxAmount:24999),
  BuildingTier(index:3, name:'House',       emoji:'🏠', minAmount:25000,  maxAmount:49999),
  BuildingTier(index:4, name:'Bungalow',    emoji:'🏡', minAmount:50000,  maxAmount:99999),
  BuildingTier(index:5, name:'Villa',       emoji:'🏘️', minAmount:100000, maxAmount:499999),
  BuildingTier(index:6, name:'Mansion',     emoji:'🏰', minAmount:500000, maxAmount:999999999),
];

BuildingTier getBuildingTier(double amount) {
  for (int i = kBuildingTiers.length - 1; i >= 0; i--) {
    if (amount >= kBuildingTiers[i].minAmount) return kBuildingTiers[i];
  }
  return kBuildingTiers[0];
}

// ── CITY LEVELS ───────────────────────────────────────────────
class CityLevel {
  final String name;
  final int minBuildings;
  const CityLevel({required this.name, required this.minBuildings});
}

const List<CityLevel> kCityLevels = [
  CityLevel(name:'Empty Land',  minBuildings:0),
  CityLevel(name:'Village',     minBuildings:1),
  CityLevel(name:'Town',        minBuildings:5),
  CityLevel(name:'City',        minBuildings:10),
  CityLevel(name:'Metropolis',  minBuildings:20),
  CityLevel(name:'Megacity',    minBuildings:35),
];

CityLevel getCityLevel(int count) {
  for (int i = kCityLevels.length - 1; i >= 0; i--) {
    if (count >= kCityLevels[i].minBuildings) return kCityLevels[i];
  }
  return kCityLevels[0];
}

// ── QUESTS ────────────────────────────────────────────────────
class QuestDef {
  final String id;
  final String icon;
  final String name;
  final int xp;
  final String type;
  final double? target;
  final String? cat;
  final double? limit;
  const QuestDef({required this.id, required this.icon, required this.name, required this.xp, required this.type, this.target, this.cat, this.limit});
}

const List<QuestDef> kQuests = [
  QuestDef(id:'q1', icon:'📝', name:'Track ₹5,000 in expenses',     xp:100, type:'spend_total', target:5000),
  QuestDef(id:'q2', icon:'🔥', name:'Log 7 days in a row',           xp:150, type:'streak',      target:7),
  QuestDef(id:'q3', icon:'🏗️', name:'Build your first building',     xp:80,  type:'buildings',   target:1),
  QuestDef(id:'q4', icon:'🏘️', name:'Build 5 buildings',             xp:150, type:'buildings',   target:5),
  QuestDef(id:'q5', icon:'👥', name:'Add 2 accounts',                xp:60,  type:'accounts',    target:2),
  QuestDef(id:'q6', icon:'🍛', name:'Keep food spend under ₹3,000',  xp:120, type:'cat_limit',   cat:'food', limit:3000),
  QuestDef(id:'q7', icon:'💎', name:'Reach ₹10,000 net savings',     xp:200, type:'net_savings', target:10000),
];

// ── BADGES ────────────────────────────────────────────────────
class BadgeDef {
  final String id;
  final String icon;
  final String name;
  final String desc;
  const BadgeDef({required this.id, required this.icon, required this.name, required this.desc});
}

const List<BadgeDef> kBadges = [
  BadgeDef(id:'first_tx',        icon:'🌱', name:'First Step',      desc:'Log your first transaction'),
  BadgeDef(id:'first_building',  icon:'🏗️', name:'First Brick',     desc:'Build your first building'),
  BadgeDef(id:'building_5',      icon:'🏘️', name:'Neighbourhood',   desc:'Have 5 buildings'),
  BadgeDef(id:'mansion',         icon:'🏰', name:'Mansion Owner',   desc:'Reach Mansion tier'),
  BadgeDef(id:'city_10',         icon:'🏙️', name:'City Builder',    desc:'Reach 10 buildings'),
  BadgeDef(id:'first_acct',      icon:'🏦', name:'First Account',   desc:'Add an account'),
  BadgeDef(id:'accounts_3',      icon:'👥', name:'Full Portfolio',  desc:'Add 3 accounts'),
  BadgeDef(id:'streak_7',        icon:'🔥', name:'Week Warrior',    desc:'7-day streak'),
  BadgeDef(id:'streak_30',       icon:'⚡', name:'Month Master',    desc:'30-day streak'),
  BadgeDef(id:'save_10k',        icon:'💎', name:'Lakhpati Jr.',    desc:'Save ₹10,000 net'),
  BadgeDef(id:'invest_1',        icon:'📈', name:'Niveshak',        desc:'Log an investment'),
  BadgeDef(id:'transfer_1',      icon:'🔄', name:'Mover',           desc:'Make a transfer'),
  BadgeDef(id:'edited_tx',       icon:'✏️', name:'Corrector',       desc:'Edit a transaction'),
  BadgeDef(id:'quests_3',        icon:'🗡️', name:'Quest Hero',      desc:'Complete 3 quests'),
];

// ── FORMATTING HELPERS ────────────────────────────────────────
String fmtRupee(double n) {
  // Format as ₹1,23,456 (Indian number system)
  final s = n.round().abs().toString();
  final result = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final fromRight = s.length - 1 - i;
    if (fromRight == 2 && s.length > 3) {
      result.write(',');
    } else if (fromRight > 2 && (fromRight - 2) % 2 == 0) {
      result.write(',');
    }
    result.write(s[i]);
  }
  return '₹${n < 0 ? "-" : ""}$result';
}

String todayStr() => DateTime.now().toIso8601String().substring(0, 10);
