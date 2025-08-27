// lib/models/event_model.dart

import 'package:flutter/foundation.dart';

class EventItem {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? memo;
  final bool useDDay;
  final bool useAutoTimeNotification;
  // 위치 정보 (placename으로 통합)
  final double? latitude;
  final double? longitude;
  final String? placeName;
  final String? placeAddress;

  const EventItem({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.memo,
    this.useDDay = false,
    this.useAutoTimeNotification = false,
    this.latitude,
    this.longitude,
    this.placeName,
    this.placeAddress,
  });

  EventItem copyWith({
    String? id,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    String? memo,
    bool? useDDay,
    bool? useAutoTimeNotification,
    double? latitude,
    double? longitude,
    String? placeName,
    String? placeAddress,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      memo: memo ?? this.memo,
      useDDay: useDDay ?? this.useDDay,
      useAutoTimeNotification: useAutoTimeNotification ?? this.useAutoTimeNotification,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
    );
  }

  // API 응답(JSON)을 EventItem 객체로 변환하는 factory 생성자
  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['scheduleId'].toString(),
      title: json['scheduleName'],
      startAt: DateTime.parse(json['scheduleStartTime']),
      endAt: DateTime.parse(json['scheduleEndTime']),
      memo: json['memo'],
      useDDay: json['d_Day'] ?? false,
      useAutoTimeNotification: json['autoTimeCheck'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      placeName: json['placeName'] ?? json['location'], // 기존 location을 placeName으로 마이그레이션
      placeAddress: json['placeAddress'],
    );
  }

  // EventItem 객체를 API 요청(JSON) 형식으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'scheduleName': title,
      'scheduleStartTime': startAt.toIso8601String(),
      'scheduleEndTime': endAt.toIso8601String(),
      'memo': memo,
      'd_Day': useDDay,
      'autoTimeCheck': useAutoTimeNotification,
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'placeAddress': placeAddress,
    };
  }

  /// 위치 정보가 있는지 확인
  bool get hasLocation => placeName != null && placeName!.isNotEmpty;

  /// 위치 표시 텍스트 생성
  String get locationDisplayText {
    if (placeName != null && placeAddress != null) {
      return '$placeName\n$placeAddress';
    } else if (placeName != null) {
      return placeName!;
    }
    return '위치 정보 없음';
  }
}