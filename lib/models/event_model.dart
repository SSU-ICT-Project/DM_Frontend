// lib/models/event_model.dart

import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

class EventItem {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? memo;
  final bool useDDay;
  final bool useAutoTimeNotification;
  // 위치 정보를 백엔드 API 스펙에 맞게 location 객체로 통합
  final LocationInfo? location;

  const EventItem({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.memo,
    this.useDDay = false,
    this.useAutoTimeNotification = false,
    this.location,
  });

  EventItem copyWith({
    String? id,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    String? memo,
    bool? useDDay,
    bool? useAutoTimeNotification,
    LocationInfo? location,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      memo: memo ?? this.memo,
      useDDay: useDDay ?? this.useDDay,
      useAutoTimeNotification: useAutoTimeNotification ?? this.useAutoTimeNotification,
      location: location ?? this.location,
    );
  }

  // API 응답(JSON)을 EventItem 객체로 변환하는 factory 생성자
  factory EventItem.fromJson(Map<String, dynamic> json) {
    LocationInfo? locationInfo;
    
    // 백엔드에서 location 객체로 전송하는 경우
    if (json['location'] != null) {
      locationInfo = LocationInfo.fromJson(json['location']);
    }
    // 기존 데이터와의 호환성을 위해 개별 필드도 처리
    else if (json['placeName'] != null || json['latitude'] != null || json['longitude'] != null) {
      locationInfo = LocationInfo(
        placeName: json['placeName'] ?? '',
        placeAddress: json['placeAddress'] ?? '',
        latitude: json['latitude']?.toString() ?? '',
        longitude: json['longitude']?.toString() ?? '',
      );
    }

    return EventItem(
      id: json['scheduleId'].toString(),
      title: json['scheduleName'],
      startAt: DateTime.parse(json['scheduleStartTime']),
      endAt: DateTime.parse(json['scheduleEndTime']),
      memo: json['memo'],
      useDDay: json['d_Day'] ?? false,
      useAutoTimeNotification: json['autoTimeCheck'] ?? false,
      location: locationInfo,
    );
  }

  // EventItem 객체를 API 요청(JSON) 형식으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    final json = {
      'scheduleName': title,
      'scheduleStartTime': startAt.toIso8601String(),
      'scheduleEndTime': endAt.toIso8601String(),
      'memo': memo,
      'd_Day': useDDay,
      'autoTimeCheck': useAutoTimeNotification,
      'location': location?.toJson(),
    };
    
    // 기존 일정 수정 시에만 ID 포함 (새 일정 생성 시에는 ID 제외)
    if (id != 'new' && id.isNotEmpty) {
      json['scheduleId'] = id;
    }
    
    print('📤 EventItem.toJson() 결과:');
    print('   🆔 ID: $id');
    print('   📋 제목: $title');
    print('   🕐 시작: ${startAt.toIso8601String()}');
    print('   🕐 종료: ${endAt.toIso8601String()}');
    print('   📝 메모: $memo');
    print('   📅 디데이: $useDDay');
    print('   ⏰ 자동시간계산: $useAutoTimeNotification');
    if (location != null) {
      print('   📍 위치: ${location!.placeName} (${location!.placeAddress})');
      print('   🗺️ 좌표: ${location!.latitude}, ${location!.longitude}');
    } else {
      print('   📍 위치: 없음');
    }
    
    return json;
  }

  /// 위치 정보가 있는지 확인
  bool get hasLocation => location != null && location!.placeName.isNotEmpty;

  /// 위치 표시 텍스트 생성
  String get locationDisplayText {
    if (location != null) {
      if (location!.placeAddress.isNotEmpty) {
        return '${location!.placeName}\n${location!.placeAddress}';
      } else {
        return location!.placeName;
      }
    }
    return '위치 정보 없음';
  }

  // 기존 코드와의 호환성을 위한 getter들
  double? get latitude => location?.latitudeDouble;
  double? get longitude => location?.longitudeDouble;
  String? get placeName => location?.placeName;
  String? get placeAddress => location?.placeAddress;
}