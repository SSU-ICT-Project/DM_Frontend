import 'motivation.dart';

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
  });

  // 서버로 보낼 JSON 형식으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'nickname': nickname,
      'phone': phone,
      'birthday': birthday,
      'gender': gender,
      'motivationType': motivationType?.toString().split('.').last.toUpperCase(),
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