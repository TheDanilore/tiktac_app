// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stopwatch_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StopwatchEntryAdapter extends TypeAdapter<StopwatchEntry> {
  @override
  final int typeId = 0;

  @override
  StopwatchEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StopwatchEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      duration: fields[2] as int,
      createdAt: fields[3] as DateTime,
      category: fields[4] as String,
      notes: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StopwatchEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopwatchEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
