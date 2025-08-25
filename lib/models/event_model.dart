// lib/models/event_model.dart

import 'package:flutter/foundation.dart';

class EventItem {
  final String id;
  final String title;
  final String? location;
  final DateTime startAt;
  final DateTime endAt;
  final String? memo;
  final bool useDDay;
  final bool useAutoTimeNotification;

  const EventItem({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.location,
    this.memo,
    this.useDDay = false,
    this.useAutoTimeNotification = false,
  });

  EventItem copyWith({
    String? id,
    String? title,
    String? location,
    DateTime? startAt,
    DateTime? endAt,
    String? memo,
    bool? useDDay,
    bool? useAutoTimeNotification,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      memo: memo ?? this.memo,
      useDDay: useDDay ?? this.useDDay,
      useAutoTimeNotification: useAutoTimeNotification ?? this.useAutoTimeNotification,
    );
  }

  // API 응답(JSON)을 EventItem 객체로 변환하는 factory 생성자
  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['scheduleId'].toString(),
      title: json['scheduleName'],
      startAt: DateTime.parse(json['scheduleStartTime']),
      endAt: DateTime.parse(json['scheduleEndTime']),
      location: json['location'],
      memo: json['memo'],
      useDDay: json['d_Day'] ?? false,
      useAutoTimeNotification: json['autoTimeCheck'] ?? false,
    );
  }

  // EventItem 객체를 API 요청(JSON) 형식으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'scheduleName': title,
      'scheduleStartTime': startAt.toIso8601String(),
      'scheduleEndTime': endAt.toIso8601String(),
      'location': location,
      'memo': memo,
      'd_Day': useDDay,
      'autoTimeCheck': useAutoTimeNotification,
    };
  }
}