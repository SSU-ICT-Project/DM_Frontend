// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart'; // 방금 만든 데이터 모델 import

class ApiService {
  // TODO: 실제 서버 주소로 변경해야 합니다.
  static const String baseUrl = 'http://api.dm.letzgo.site/rest-api/v1';

  // 회원가입 요청 메서드
  static Future<bool> signUp(SignUpData signUpData) async {
    final url = Uri.parse('$baseUrl/member');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(signUpData.toJson()), // 데이터 모델을 JSON으로 변환
      );

      if (response.statusCode == 200) {
        // 성공적으로 응답을 받았을 때
        print('회원가입 성공');
        return true;
      } else {
        // 서버에서 에러 응답이 왔을 때
        print('회원가입 실패: ${response.statusCode}');
        print('응답 내용: ${response.body}');
        return false;
      }
    } catch (e) {
      // 네트워크 오류 등 예외 발생 시
      print('회원가입 중 오류 발생: $e');
      return false;
    }
  }
}