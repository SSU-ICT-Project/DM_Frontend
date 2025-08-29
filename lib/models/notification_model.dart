import 'package:flutter/material.dart';

enum TargetObject {
  COMMENT,
  FOLLOW,
  GOAL,
  EVENT,
  // 필요에 따라 추가
}

class NotificationModel {
  final int id;
  final int senderId;
  final String senderNickname;
  final String? senderProfileUrl;
  final int receiverId;
  final int objectId;
  final String content;
  final bool isRead;
  final TargetObject targetObject;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    this.senderProfileUrl,
    required this.receiverId,
    required this.objectId,
    required this.content,
    required this.isRead,
    required this.targetObject,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    print('🔍 NotificationModel.fromJson 시작');
    print('🔍 입력 JSON: $json');
    
    try {
      // ID 필드들을 안전하게 파싱
      final id = _safeParseInt(json['id'], 'id');
      final senderId = _safeParseInt(json['senderId'], 'senderId');
      final receiverId = _safeParseInt(json['receiverId'], 'receiverId');
      final objectId = _safeParseInt(json['objectId'], 'objectId');
      
      print('🔍 파싱된 ID들: id=$id, senderId=$senderId, receiverId=$receiverId, objectId=$objectId');
      
      // 문자열 필드들
      final senderNickname = json['senderNickname']?.toString() ?? '';
      final senderProfileUrl = json['senderProfileUrl']?.toString();
      final content = json['content']?.toString() ?? '';
      
      print('🔍 파싱된 문자열들: senderNickname="$senderNickname", content="$content"');
      
      // 불린 필드
      final isRead = json['isRead'] == true;
      print('🔍 파싱된 불린: isRead=$isRead');
      
      // TargetObject 파싱
      final targetObject = _parseTargetObject(json['targetObject']);
      print('🔍 파싱된 TargetObject: $targetObject');
      
      // DateTime 파싱
      DateTime createdAt;
      try {
        final dateString = json['createdAt']?.toString();
        print('🔍 날짜 문자열: $dateString');
        if (dateString != null && dateString.isNotEmpty) {
          createdAt = DateTime.parse(dateString);
        } else {
          createdAt = DateTime.now();
        }
        print('🔍 파싱된 DateTime: $createdAt');
      } catch (e) {
        print('⚠️ DateTime 파싱 실패, 현재 시간 사용: $e');
        createdAt = DateTime.now();
      }
      
      final notification = NotificationModel(
        id: id,
        senderId: senderId,
        senderNickname: senderNickname,
        senderProfileUrl: senderProfileUrl,
        receiverId: receiverId,
        objectId: objectId,
        content: content,
        isRead: isRead,
        targetObject: targetObject,
        createdAt: createdAt,
      );
      
      print('✅ NotificationModel 생성 성공: ${notification.id}');
      return notification;
      
    } catch (e, stackTrace) {
      print('❌ NotificationModel.fromJson 실패: $e');
      print('❌ 스택 트레이스: $stackTrace');
      print('❌ 실패한 JSON: $json');
      
      // 에러 발생 시 기본값으로 생성
      return NotificationModel(
        id: 0,
        senderId: 0,
        senderNickname: '알 수 없음',
        senderProfileUrl: null,
        receiverId: 0,
        objectId: 0,
        content: '알림 내용을 불러올 수 없습니다.',
        isRead: false,
        targetObject: TargetObject.COMMENT,
        createdAt: DateTime.now(),
      );
    }
  }

  // 안전한 int 파싱 메서드
  static int _safeParseInt(dynamic value, String fieldName) {
    print('🔍 $fieldName 파싱 시도: $value (타입: ${value.runtimeType})');
    
    if (value == null) {
      print('⚠️ $fieldName이 null, 0으로 설정');
      return 0;
    }
    
    if (value is int) {
      print('✅ $fieldName이 이미 int: $value');
      return value;
    }
    
    if (value is String) {
      try {
        final parsed = int.parse(value);
        print('✅ $fieldName 문자열을 int로 파싱 성공: $value -> $parsed');
        return parsed;
      } catch (e) {
        print('⚠️ $fieldName 문자열을 int로 파싱 실패: $value, 0으로 설정');
        return 0;
      }
    }
    
    if (value is double) {
      final parsed = value.toInt();
      print('✅ $fieldName double을 int로 변환: $value -> $parsed');
      return parsed;
    }
    
    print('⚠️ $fieldName의 예상치 못한 타입: ${value.runtimeType}, 0으로 설정');
    return 0;
  }

  static TargetObject _parseTargetObject(dynamic value) {
    print('🔍 TargetObject 파싱 시도: $value (타입: ${value.runtimeType})');
    
    if (value == null) {
      print('⚠️ TargetObject가 null, COMMENT로 설정');
      return TargetObject.COMMENT;
    }
    
    final stringValue = value.toString().toUpperCase();
    print('🔍 TargetObject 문자열: $stringValue');
    
    switch (stringValue) {
      case 'COMMENT':
        print('✅ TargetObject: COMMENT');
        return TargetObject.COMMENT;
      case 'FOLLOW':
        print('✅ TargetObject: FOLLOW');
        return TargetObject.FOLLOW;
      case 'GOAL':
        print('✅ TargetObject: GOAL');
        return TargetObject.GOAL;
      case 'EVENT':
        print('✅ TargetObject: EVENT');
        return TargetObject.EVENT;
      default:
        print('⚠️ 알 수 없는 TargetObject: $stringValue, COMMENT로 설정');
        return TargetObject.COMMENT;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'senderProfileUrl': senderProfileUrl,
      'receiverId': receiverId,
      'objectId': objectId,
      'content': content,
      'isRead': isRead,
      'targetObject': targetObject.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // copyWith 메서드 추가
  NotificationModel copyWith({
    int? id,
    int? senderId,
    String? senderNickname,
    String? senderProfileUrl,
    int? receiverId,
    int? objectId,
    String? content,
    bool? isRead,
    TargetObject? targetObject,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderNickname: senderNickname ?? this.senderNickname,
      senderProfileUrl: senderProfileUrl ?? this.senderProfileUrl,
      receiverId: receiverId ?? this.receiverId,
      objectId: objectId ?? this.objectId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      targetObject: targetObject ?? this.targetObject,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationPageResponse {
  final List<NotificationModel> contents;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final int totalCount;

  NotificationPageResponse({
    required this.contents,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.totalCount,
  });

  factory NotificationPageResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 NotificationPageResponse.fromJson 시작');
    print('🔍 입력 JSON: $json');
    
    try {
      final contents = (json['contents'] as List?)
          ?.map((item) {
            print('🔍 contents 항목 파싱: $item');
            return NotificationModel.fromJson(item);
          })
          .toList() ?? [];
      
      final pageNumber = _safeParseInt(json['pageNumber'], 'pageNumber');
      final pageSize = _safeParseInt(json['pageSize'], 'pageSize');
      final totalPages = _safeParseInt(json['totalPages'], 'totalPages');
      final totalCount = _safeParseInt(json['totalCount'], 'totalCount');
      
      print('🔍 페이지 정보: pageNumber=$pageNumber, pageSize=$pageSize, totalPages=$totalPages, totalCount=$totalCount');
      
      final response = NotificationPageResponse(
        contents: contents,
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalPages: totalPages,
        totalCount: totalCount,
      );
      
      print('✅ NotificationPageResponse 생성 성공: ${contents.length}개 알림');
      return response;
      
    } catch (e, stackTrace) {
      print('❌ NotificationPageResponse.fromJson 실패: $e');
      print('❌ 스택 트레이스: $stackTrace');
      
      // 에러 발생 시 기본값으로 생성
      return NotificationPageResponse(
        contents: [],
        pageNumber: 0,
        pageSize: 20,
        totalPages: 0,
        totalCount: 0,
      );
    }
  }

  // 안전한 int 파싱 메서드 (NotificationModel과 동일)
  static int _safeParseInt(dynamic value, String fieldName) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    if (value is double) return value.toInt();
    return 0;
  }
}

class NotificationApiResponse {
  final String returnCode;
  final String returnMessage;
  final NotificationModel? data;
  final NotificationPageResponse? dmPage;

  NotificationApiResponse({
    required this.returnCode,
    required this.returnMessage,
    this.data,
    this.dmPage,
  });

  factory NotificationApiResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 NotificationApiResponse.fromJson 시작');
    print('🔍 입력 JSON: $json');
    
    try {
      final returnCode = json['returnCode']?.toString() ?? '';
      final returnMessage = json['returnMessage']?.toString() ?? '';
      
      print('🔍 응답 정보: returnCode=$returnCode, returnMessage=$returnMessage');
      
      NotificationModel? data;
      if (json['data'] != null) {
        print('🔍 data 필드 파싱 시도');
        data = NotificationModel.fromJson(json['data']);
      }
      
      NotificationPageResponse? dmPage;
      if (json['dmPage'] != null) {
        print('🔍 dmPage 필드 파싱 시도');
        dmPage = NotificationPageResponse.fromJson(json['dmPage']);
      }
      
      final response = NotificationApiResponse(
        returnCode: returnCode,
        returnMessage: returnMessage,
        data: data,
        dmPage: dmPage,
      );
      
      print('✅ NotificationApiResponse 생성 성공');
      return response;
      
    } catch (e, stackTrace) {
      print('❌ NotificationApiResponse.fromJson 실패: $e');
      print('❌ 스택 트레이스: $stackTrace');
      
      // 에러 발생 시 기본값으로 생성
      return NotificationApiResponse(
        returnCode: 'ERROR',
        returnMessage: '알림 응답을 파싱할 수 없습니다: $e',
        data: null,
        dmPage: null,
      );
    }
  }
}