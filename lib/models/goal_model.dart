import 'package:flutter/foundation.dart';

class SubGoal {
  final String id;
  final String title;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? deadline;   // 하위 목표 디데이

  const SubGoal({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
    this.deadline,        // 하위 목표 디데이
  });

  SubGoal copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? deadline, // 하위 목표 디데이
  }) {
    return SubGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,    // 하위 목표 디데이
    );
  }

  // 디데이 계산을 위한 getter 추가
  int? get dDay {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return due.difference(today).inDays;
  }

}

class Goal {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isCompleted;
  final bool isExpanded;
  final List<SubGoal> subGoals;

  const Goal({
    required this.id,
    required this.title,
    required this.createdAt,
    this.deadline,
    this.isCompleted = false,
    this.isExpanded = true,
    this.subGoals = const [],
  });

  int? get dDay {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return due.difference(today).inDays;
  }

  Goal copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? deadline,
    bool? isCompleted,
    bool? isExpanded,
    List<SubGoal>? subGoals,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      isExpanded: isExpanded ?? this.isExpanded,
      subGoals: subGoals ?? this.subGoals,
    );
  }
}

enum GoalSortOption {
  deadlineAsc, // D-day 적은 순 (가까운 마감일 우선)
  newest,
  oldest,
  name,
  deadlineDesc,
}



