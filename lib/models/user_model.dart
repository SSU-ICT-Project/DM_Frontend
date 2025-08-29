import 'motivation.dart';
import '../services/location_service.dart';

class SignUpData {
  String email;
  String password;
  String passwordConfirmation;
  String name;
  String nickname;
  String phone;
  String birthday; // "YYYY-MM-DD" 형식
  String gender;   // "MALE" 또는 "FEMALE"
  MotivationType? motivationType;
  String? averagePreparationTime; // "HH:MM:SS" 형식
  List<String> distractionAppList; // 유해앱 목록
  LocationInfo? location; // 출발지 주소
  bool useNotification; // 알림 사용 여부

  SignUpData({
    this.email = '',
    this.password = '',
    this.passwordConfirmation = '',
    this.name = '',
    this.nickname = '',
    this.phone = '',
    this.birthday = '',
    this.gender = '',
    this.motivationType,
    this.averagePreparationTime,
    this.distractionAppList = const [],
    this.location,
    this.useNotification = true,
  });

  // 서버로 보낼 JSON 형식으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nickname': nickname,
      'job': name, // 백엔드에서는 'job' 필드로 매핑
      'birthday': birthday,
      'averagePreparationTime': averagePreparationTime,
      'distractionAppList': distractionAppList,
      'location': location?.toJson(),
      'useNotification': useNotification,
      'motivationType': motivationType?.toString().split('.').last,
      'gender': gender,
    };
  }
}

// 백엔드 API 응답을 위한 회원 상세 정보 모델
class MemberDetail {
  final int id;
  final String name;
  final String nickname;
  final String job;
  final String phone;
  final String email;
  final String password;
  final String motivationType;
  final String gender;
  final String birthday;
  final String averagePreparationTime;
  final List<String> distractionAppList;
  final LocationInfo? location;
  final bool useNotification;
  final String state;
  final String role;
  final String? profileImageUrl;
  final DateTime createdAt;

  MemberDetail({
    required this.id,
    required this.name,
    required this.nickname,
    required this.job,
    required this.phone,
    required this.email,
    required this.password,
    required this.motivationType,
    required this.gender,
    required this.birthday,
    required this.averagePreparationTime,
    required this.distractionAppList,
    this.location,
    required this.useNotification,
    required this.state,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory MemberDetail.fromJson(Map<String, dynamic> json) {
    return MemberDetail(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      nickname: json['nickname'] ?? '',
      job: json['job'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      motivationType: json['motivationType'] ?? 'HABITUAL_WATCHER',
      gender: json['gender'] ?? '',
      birthday: json['birthday'] ?? '',
      averagePreparationTime: json['averagePreparationTime'] ?? '',
      distractionAppList: List<String>.from(json['distractionAppList'] ?? []),
      location: json['location'] != null ? LocationInfo.fromJson(json['location']) : null,
      useNotification: json['useNotification'] ?? true,
      state: json['state'] ?? 'NORMAL',
      role: json['role'] ?? 'ROLE_USER',
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // 회원 정보 수정을 위한 JSON 변환 메서드 (multipart/form-data 형식에 최적화)
  Map<String, dynamic> toUpdateJson() {
    return {
      'memberForm': {
        'nickname': nickname,
        'job': job.isNotEmpty ? job : null, // null로 전송하여 백엔드에서 처리
        'email': email,
        'password': password.isNotEmpty ? password : null, // null로 전송하여 백엔드에서 처리
        'birthday': birthday.isNotEmpty ? birthday : null, // LocalDate 형식으로 전송
        'averagePreparationTime': averagePreparationTime.isNotEmpty ? averagePreparationTime : null, // LocalTime 형식으로 전송
        'distractionAppList': distractionAppList,
        'location': location != null ? {
          'placeName': location!.placeName,
          'placeAddress': location!.placeAddress,
          'latitude': location!.latitude,
          'longitude': location!.longitude,
        } : null,
        'useNotification': useNotification,
        'motivationType': motivationType,
        'gender': gender.isNotEmpty ? gender : null, // null로 전송하여 백엔드에서 처리
      },
      // imageFile은 multipart/form-data에서 별도로 처리
    };
  }

  // MotivationType으로 변환
  MotivationType get motivationTypeEnum {
    switch (motivationType) {
      case 'HABITUAL_WATCHER':
        return MotivationType.HABITUAL_WATCHER;
      case 'COMFORT_SEEKER':
        return MotivationType.COMFORT_SEEKER;
      case 'THRILL_SEEKER':
        return MotivationType.THRILL_SEEKER;
      default:
        return MotivationType.HABITUAL_WATCHER;
    }
  }

  // MotivationType을 문자열로 변환
  static String motivationTypeToString(MotivationType type) {
    switch (type) {
      case MotivationType.HABITUAL_WATCHER:
        return 'HABITUAL_WATCHER';
      case MotivationType.COMFORT_SEEKER:
        return 'COMFORT_SEEKER';
      case MotivationType.THRILL_SEEKER:
        return 'THRILL_SEEKER';
    }
  }
}

// 간단한 세션 홀더 (임시)
class UserSession {
  static String? nickname;
  static String? name;
  static MotivationType? motivationType;
  static String? prepTime; // 평균 외출 준비 시간 (예: 30분, 1시간)
}