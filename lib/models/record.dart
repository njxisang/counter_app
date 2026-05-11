import 'package:equatable/equatable.dart';

class CounterRecord extends Equatable {
  final int? id;
  final int projectId;
  final int delta;
  final int totalAfter;
  final DateTime createdAt;

  const CounterRecord({
    this.id,
    required this.projectId,
    required this.delta,
    required this.totalAfter,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'delta': delta,
      'total_after': totalAfter,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CounterRecord.fromMap(Map<String, dynamic> map) {
    return CounterRecord(
      id: map['id'] as int?,
      projectId: map['project_id'] as int,
      delta: map['delta'] as int,
      totalAfter: map['total_after'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, projectId, delta, totalAfter, createdAt];
}
