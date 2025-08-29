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

// 간단한 세션 홀더 (임시)
class UserSession {
  static String? nickname;
  static String? name;
  static MotivationType? motivationType;
  static String? prepTime; // 평균 외출 준비 시간 (예: 30분, 1시간)
}