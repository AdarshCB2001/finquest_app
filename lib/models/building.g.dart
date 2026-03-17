// GENERATED CODE - DO NOT MODIFY BY HAND
// Hive TypeAdapter for BuildingModel

part of 'building.dart';

class BuildingModelAdapter extends TypeAdapter<BuildingModel> {
  @override
  final int typeId = 2;

  @override
  BuildingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BuildingModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      amount: fields[3] as double,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BuildingModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
