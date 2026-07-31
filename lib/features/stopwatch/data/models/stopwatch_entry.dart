import 'package:hive/hive.dart';

part 'stopwatch_entry.g.dart';

@HiveType(typeId: 0)
class StopwatchEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int duration; // en milisegundos

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String notes;

  StopwatchEntry({
    required this.id,
    required this.title,
    required this.duration,
    required this.createdAt,
    this.category = 'Otros',
    this.notes = '',
  });

  // Retorna la duración en formato HH:MM:SS
  String get formattedDuration {
    final hours = (duration ~/ 3600000).toString().padLeft(2, '0');
    final minutes = ((duration ~/ 60000) % 60).toString().padLeft(2, '0');
    final seconds = ((duration ~/ 1000) % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  // Retorna solo MM:SS si no hay horas
  String get formattedDurationShort {
    if (duration >= 3600000) {
      return formattedDuration;
    }
    final minutes = (duration ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((duration ~/ 1000) % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Copia con cambios
  StopwatchEntry copyWith({
    String? id,
    String? title,
    int? duration,
    DateTime? createdAt,
    String? category,
    String? notes,
  }) {
    return StopwatchEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}
