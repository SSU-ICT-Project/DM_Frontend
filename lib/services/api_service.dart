// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api.dm.letzgo.site/rest-api/v1';

  // 모든 HTTP 요청에 토큰을 자동으로 추가하는 메서드
  static Future<http.Response> _sendRequest(Future<http.Response> Function() requestFunction) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      // 토큰이 없으면 로그인되지 않은 상태
      return http.Response('{"message": "로그인 정보가 없습니다."}', 401);
    }

    // 헤더에 토큰을 추가하여 요청 보냄
    final response = await requestFunction();

    // 토큰 만료 에러 (401 Unauthorized) 감지
    if (response.statusCode == 401) {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken != null) {
        // 토큰 갱신 성공 시, 원래 요청을 새 토큰으로 다시 보냄
        final newResponse = await requestFunction();
        return newResponse;
      }
    }
    return response;
  }

  // accessToken 갱신 메서드
  static Future<String?> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) {
      print('refreshToken이 없습니다. 로그아웃 처리합니다.');
      // TODO: 앱 상태를 로그아웃 상태로 변경
      return null;
    }

    // Swagger 문서에 맞춰 GET 메소드와 정확한 엔드포인트 사용
    final url = Uri.parse('$baseUrl/auth/refresh-token');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken', // refreshToken 사용
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String newAccessToken = data['accessToken'];
        final String? newRefreshToken = data['refreshToken']; // refreshToken도 갱신되면 저장

        await prefs.setString('accessToken', newAccessToken);
        if (newRefreshToken != null) {
          await prefs.setString('refreshToken', newRefreshToken);
        }
        print('토큰 갱신 성공');
        return newAccessToken;
      } else {
        print('토큰 갱신 실패: ${response.statusCode}, ${response.body}');
        await prefs.remove('accessToken');
        await prefs.remove('refreshToken');
        // TODO: 앱 상태를 로그아웃 상태로 변경
        return null;
      }
    } catch (e) {
      print('토큰 갱신 중 오류 발생: $e');
      return null;
    }
  }

  // 로그인 API 메서드
  static Future<String?> signIn(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('HTTP 응답 상태 코드: ${response.statusCode}');
      print('HTTP 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // ✅ 서버 응답의 'data' 필드에 접근하여 실제 토큰 데이터를 가져옵니다.
        final Map<String, dynamic>? data = responseData['data'];

        if (data == null) {
          return '로그인 실패: 서버로부터 토큰 데이터가 누락되었습니다.';
        }

        final String? accessToken = data['accessToken'];
        final String? refreshToken = data['refreshToken'];

        if (accessToken == null || refreshToken == null) {
          return '로그인 실패: 서버로부터 토큰 정보가 누락되었습니다.';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);

        print('로그인 성공: 토큰 저장 완료');
        return null;
      } else {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final String errorMessage = responseBody['message'] ?? '로그인에 실패했습니다. 이메일과 비밀번호를 확인해 주세요.';
        print('로그인 실패: ${response.statusCode}, $errorMessage');
        return errorMessage;
      }
    } catch (e) {
      print('로그인 중 오류 발생: $e');
      return '네트워크 오류가 발생했습니다.';
    }
  }

  // 회원가입 API 메서드
  static Future<String?> signUp(SignUpData data) async {
    final url = Uri.parse('$baseUrl/member'); // Swagger 명세에 맞는 엔드포인트 사용

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data.toJson()), // SignUpData 객체를 JSON으로 변환하여 전송
      );

      // 백엔드 응답 코드가 200 (OK)인지 확인
      if (response.statusCode == 200) {
        print('회원가입 성공!');
        return null; // 성공 시 에러 메시지 없음
      } else {
        // 실패 시 백엔드에서 온 에러 메시지 처리
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final String errorMessage = responseBody['message'] ?? '회원가입에 실패했습니다. 다시 시도해 주세요.';
        print('회원가입 실패: ${response.statusCode}, $errorMessage');
        return errorMessage;
      }
    } catch (e) {
      print('회원가입 중 오류 발생: $e');
      return '네트워크 오류가 발생했습니다.';
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      // 로컬에 토큰이 없으므로, 그냥 로그아웃 상태로 간주
      return;
    }

    final url = Uri.parse('$baseUrl/auth/logout');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        print('서버 로그아웃 성공');
      } else {
        print('서버 로그아웃 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('로그아웃 중 오류 발생: $e');
    } finally {
      // 서버 통신 성공/실패와 관계없이 로컬 토큰 삭제
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
    }
  }

  // 이제 다른 모든 API는 이 메서드를 사용합니다.
  static Future<http.Response> getGoals() async {
    return _sendRequest(() async {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final url = Uri.parse('$baseUrl/goals');

      return http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    });
  }

// TODO: 목표 추가, 수정, 삭제 등 다른 API 메서드도 _sendRequest를 사용하도록 수정

}