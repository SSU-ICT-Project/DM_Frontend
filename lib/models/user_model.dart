// lib/models/user_model.dart

import 'motivation.dart';

class SignUpData {
  String email;
  String password;
  String passwordConfirmation;
  String job; // 'name' 필드를 'job'으로 변경
  String nickname;
  String phone;
  String birthday; // "YYYY-MM-DD" 형식
  String gender;   // "MALE" 또는 "FEMALE"
  MotivationType? motivationType;

  SignUpData({
    this.email = '',
    this.password = '',
    this.passwordConfirmation = '',
    this.job = '', // 'name' 필드를 'job'으로 변경
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
      'job': job, // 'name' 키를 'job'으로 변경
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

class DetailMemberDto {
  final String nickname;
  final String job;
  final String? birthday;
  final MotivationType motivationType;
  final String? prepTime;

  DetailMemberDto({
    required this.nickname,
    required this.job,
    this.birthday,
    required this.motivationType,
    this.prepTime,
  });

  factory DetailMemberDto.fromJson(Map<String, dynamic> json) {
    return DetailMemberDto(
      // ✅ null 값일 경우 빈 문자열 ''을 기본값으로 사용하도록 수정
      nickname: json['nickname'] ?? '',
      job: json['job'] ?? '',
      birthday: json['birthday'],
      motivationType: motivationTypeFromString(json['motivationType']),
      prepTime: json['prepTime'],
    );
  }
}

class MemberForm {
  final String nickname;
  final String job;
  final String? birthday;
  final MotivationType motivationType;
  final String? prepTime;

  MemberForm({
    required this.nickname,
    required this.job,
    this.birthday,
    required this.motivationType,
    this.prepTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'job': job,
      'birthday': birthday,
      'motivationType': motivationType.toString().split('.').last.toUpperCase(),
      'prepTime': prepTime,
    };
  }
}