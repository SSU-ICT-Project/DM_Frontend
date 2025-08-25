import 'package:flutter/foundation.dart';

class SubGoal {
  final int id;
  final String title;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? deadline;
  final int? dDay;

  const SubGoal({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
    this.deadline,
    this.dDay,
  });

  // JSON 데이터를 Dart 객체로 변환하는 팩토리 메서드
  factory SubGoal.fromJson(Map<String, dynamic> json) {
    // D-day 필드 처리 로직을 강화합니다.
    int? parsedDDay;
    if (json.containsKey('dday') && json['dday'] != null) {
      final dynamic dDayValue = json['dday'];
      if (dDayValue is String) {
        if (dDayValue == 'D-Day') {
          parsedDDay = 0;
        } else if (dDayValue.startsWith('D-') || dDayValue.startsWith('D+')) {
          final numericPart = dDayValue.substring(2);
          parsedDDay = int.tryParse(numericPart);
        }
      } else if (dDayValue is int) { // dday가 int로 올 경우를 대비
        parsedDDay = dDayValue;
      }
    }

    //  모든 필드를 Null-Safe하게 처리합니다.
    final subGoalId = (json['id'] as int?) ?? 0;
    final title = (json['content'] as String?) ?? '';
    final createdAtString = json['createdAt'] as String?;
    final createdAt = createdAtString != null ? DateTime.parse(createdAtString) : DateTime.now();
    final isCompleted = (json['checked'] as bool?) ?? false;
    final deadline = json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null;

    return SubGoal(
      id: subGoalId,
      title: title,
      createdAt: createdAt,
      isCompleted: isCompleted,
      deadline: deadline,
      dDay: parsedDDay,
    );
  }

  // Dart 객체를 JSON 형식으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'content': title, //  'title' 대신 'content' 사용
      'checked': isCompleted, //  'status' 대신 'checked' 사용
      'deadline': deadline?.toIso8601String(),
    };
  }

  SubGoal copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? deadline,
    int? dDay,
  }) {
    return SubGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
      dDay: dDay ?? this.dDay,
    );
  }

  int? get dDayComputed {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return due.difference(today).inDays;
  }
}

class Goal {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isCompleted;
  final bool isExpanded;
  final List<SubGoal> subGoals;
  final int? dDay;

  const Goal({
    required this.id,
    required this.title,
    required this.createdAt,
    this.deadline,
    this.isCompleted = false,
    this.isExpanded = true,
    this.subGoals = const [],
    this.dDay,
  });

  // JSON 데이터를 Dart 객체로 변환하는 팩토리 메서드
  factory Goal.fromJson(Map<String, dynamic> json) {
    //  JSON 객체에서 mainGoal과 subGoals 데이터를 추출
    final mainGoalData = json['mainGoal'] as Map<String, dynamic>? ?? {};
    final subGoalsList = json['subGoals'] as List? ?? [];

    List<SubGoal> subGoals = subGoalsList.map((i) => SubGoal.fromJson(i as Map<String, dynamic>)).toList();

    int? parsedDDay;
    if (mainGoalData['dday'] is String) {
      String dDayString = mainGoalData['dday'];
      if (dDayString == 'D-Day') {
        parsedDDay = 0;
      } else if (dDayString.startsWith('D-') || dDayString.startsWith('D+')) {
        final numericPart = dDayString.substring(2);
        parsedDDay = int.tryParse(numericPart);
      }
    } else if (mainGoalData['dday'] is int) {
      parsedDDay = mainGoalData['dday'];
    }

    //  모든 필드를 Null-Safe하게 처리
    final mainGoalId = (mainGoalData['id'] as int?) ?? 0;
    final title = (mainGoalData['content'] as String?) ?? '';
    final createdAtString = mainGoalData['createdAt'] as String?;
    final createdAt = createdAtString != null ? DateTime.parse(createdAtString) : DateTime.now();
    final deadline = mainGoalData['deadline'] != null ? DateTime.parse(mainGoalData['deadline'] as String) : null;
    final isCompleted = (mainGoalData['checked'] as bool?) ?? false;

    return Goal(
      id: mainGoalId,
      title: title,
      createdAt: createdAt,
      deadline: deadline,
      isCompleted: isCompleted,
      isExpanded: true,
      subGoals: subGoals,
      dDay: parsedDDay,
    );
  }

  // Dart 객체를 JSON 형식으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'content': title, //  'title' 대신 'content' 사용
      'deadline': deadline?.toIso8601String(),
      'checked': isCompleted, //  'status' 대신 'checked' 사용
      'subGoals': subGoals.map((sub) => sub.toJson()).toList(),
    };
  }

  Goal copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? deadline,
    bool? isCompleted,
    bool? isExpanded,
    List<SubGoal>? subGoals,
    int? dDay,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      isExpanded: isExpanded ?? this.isExpanded,
      subGoals: subGoals ?? this.subGoals,
      dDay: dDay ?? this.dDay,
    );
  }

  //  dDay 값으로부터 계산된 마감일을 반환하는 게터 추가
  DateTime? get computedDeadline {
    if (dDay == null) return null;
    final now = DateTime.now();
    // 현재 날짜에서 dDay만큼 더하거나 빼서 계산
    return now.add(Duration(days: dDay!));
  }

}
enum GoalSortOption {
  deadlineAsc, // D-day 적은 순 (가까운 마감일 우선)
  newest,
  oldest,
  name,
  deadlineDesc,
}