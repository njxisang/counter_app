import 'package:equatable/equatable.dart';

class CounterProject extends Equatable {
  final int? id;
  final String name;
  final DateTime createdAt;
  final String? note;
  final int colorIndex;

  const CounterProject({
    this.id,
    required this.name,
    required this.createdAt,
    this.note,
    this.colorIndex = 0,
  });

  CounterProject copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? note,
    int? colorIndex,
  }) {
    return CounterProject(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'note': note,
      'color_index': colorIndex,
    };
  }

  factory CounterProject.fromMap(Map<String, dynamic> map) {
    return CounterProject(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      note: map['note'] as String?,
      colorIndex: map['color_index'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, note, colorIndex];
}
