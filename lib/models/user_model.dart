class SignUpData {
  String email;
  String password;
  String name;
  String nickname;
  String phone;
  String birthday; // "YYYY-MM-DD" 형식
  String gender;   // "MALE" 또는 "FEMALE"

  SignUpData({
    this.email = '',
    this.password = '',
    this.name = '',
    this.nickname = '',
    this.phone = '',
    this.birthday = '',
    this.gender = '',
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
    };
  }
}