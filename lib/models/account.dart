// Account data model (bank, cash, credit, UPI, etc.)
import 'package:hive/hive.dart';

part 'account.g.dart';

@HiveType(typeId: 1)
class AccountModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String type; // 'bank', 'cash', 'credit', 'upi', 'savings', 'invest'

  @HiveField(3)
  late double initialBalance;

  @HiveField(4)
  late String color; // hex string e.g. '#1565C0'

  @HiveField(5)
  late String icon; // emoji e.g. '🏦'

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.color,
    required this.icon,
  });
}
