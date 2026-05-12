import 'package:equatable/equatable.dart';

enum CountMode {
  /// 增量计数：累计值从历史基础上继续累加，永不清零
  incremental,
  /// 每日计数：新的一天从零开始，只统计当日的增量
  daily,
}

class CounterProject extends Equatable {
  final int? id;
  final String name;
  final DateTime createdAt;
  final String? note;
  final int colorIndex;
  /// 计数模式：incremental=累计计数（永不清零），daily=每日计数（每日清零）
  final CountMode countMode;

  const CounterProject({
    this.id,
    required this.name,
    required this.createdAt,
    this.note,
    this.colorIndex = 0,
    this.countMode = CountMode.incremental,
  });

  CounterProject copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? note,
    int? colorIndex,
    CountMode? countMode,
  }) {
    return CounterProject(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      colorIndex: colorIndex ?? this.colorIndex,
      countMode: countMode ?? this.countMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'note': note,
      'color_index': colorIndex,
      'count_mode': countMode.index,
    };
  }

  factory CounterProject.fromMap(Map<String, dynamic> map) {
    return CounterProject(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      note: map['note'] as String?,
      colorIndex: map['color_index'] as int? ?? 0,
      countMode: CountMode.values[map['count_mode'] as int? ?? 0],
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, note, colorIndex, countMode];
}
