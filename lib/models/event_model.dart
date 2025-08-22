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
}



