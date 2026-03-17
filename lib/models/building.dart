// Building data model for the City Builder
import 'package:hive/hive.dart';

part 'building.g.dart';

@HiveType(typeId: 2)
class BuildingModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String category; // 'house','apartment','school','hospital','gym','restaurant','mall','bank'

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late DateTime createdAt;

  BuildingModel({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.createdAt,
  });
}
