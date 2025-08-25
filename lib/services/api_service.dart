// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.dm.letzgo.site/rest-api/v1';

  // 모든 HTTP 요청에 토큰을 자동으로 추가하는 메서드
  static Future<http.Response> _sendRequest(
      Future<http.Response> Function(Map<String, String> headers)
      requestFunction) async {
    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('accessToken');

    if (accessToken == null) {
      // 로그인 API 호출과 같이 토큰이 필요 없는 경우는 바로 요청
      // 이 부분은 현재 로직상 로그인 외에는 401을 유발할 수 있으므로 로그인/회원가입 분기 처리가 필요하다면 추가 로직이 필요합니다.
      // 현재는 토큰이 없으면 무조건 401을 반환하는 것이 안전합니다.
      return http.Response('{"message": "로그인 정보가 없습니다."}', 401);
    }

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    var response = await requestFunction(headers);

    if (response.statusCode == 401) {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken != null) {
        headers['Authorization'] = 'Bearer $newAccessToken';
        response = await requestFunction(headers);
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
      return null;
    }

    final url = Uri.parse('$baseUrl/auth/refresh-token');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final Map<String, dynamic>? data = body['data'];

        if (data != null) {
          final String? newAccessToken = data['accessToken'];
          final String? newRefreshToken = data['refreshToken'];

          if (newAccessToken != null) {
            await prefs.setString('accessToken', newAccessToken);
            if (newRefreshToken != null) {
              await prefs.setString('refreshToken', newRefreshToken);
            }
            print('토큰 갱신 성공');
            return newAccessToken;
          }
        }
      }

      print('토큰 갱신 실패: ${response.statusCode}, ${response.body}');
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      return null;
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
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ 'email': email, 'password': password }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final Map<String, dynamic>? data = responseData['data'];

        if (data == null) return '로그인 실패: 서버로부터 토큰 데이터가 누락되었습니다.';

        final String? accessToken = data['accessToken'];
        final String? refreshToken = data['refreshToken'];

        if (accessToken == null || refreshToken == null) return '로그인 실패: 서버로부터 토큰 정보가 누락되었습니다.';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);

        print('로그인 성공: 토큰 저장 완료');
        return null;
      } else {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return responseBody['message'] ?? '로그인에 실패했습니다. 이메일과 비밀번호를 확인해 주세요.';
      }
    } catch (e) {
      print('로그인 중 오류 발생: $e');
      return '네트워크 오류가 발생했습니다.';
    }
  }

  // 회원가입 API 메서드
  static Future<String?> signUp(SignUpData data) async {
    final url = Uri.parse('$baseUrl/member');
    try {
      final response = await http.post(
        url,
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode == 200) {
        print('회원가입 성공!');
        return null;
      } else {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        return responseBody['message'] ?? '회원가입에 실패했습니다. 다시 시도해 주세요.';
      }
    } catch (e) {
      print('회원가입 중 오류 발생: $e');
      return '네트워크 오류가 발생했습니다.';
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken == null) return;

    final url = Uri.parse('$baseUrl/auth/logout');
    try {
      await http.post(
        url,
        headers: { 'Authorization': 'Bearer $accessToken' },
      );
    } catch (e) {
      print('로그아웃 중 오류 발생: $e');
    } finally {
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
    }
  }

  // 월별 일정 조회
  static Future<List<EventItem>> getSchedulesByMonth(String yearMonth) async {
    final url = Uri.parse('$baseUrl/schedule/month?yearMonth=$yearMonth');
    final response = await _sendRequest((headers) => http.get(url, headers: headers));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic>? contents = body['dmPage']?['contents'];
      return contents?.map((json) => EventItem.fromJson(json)).toList() ?? [];
    } else {
      if (response.statusCode == 401) return [];
      throw Exception('월별 일정을 불러오는데 실패했습니다.');
    }
  }

  // ★★★ 최종 수정된 부분 ★★★
  // 일정 생성
  static Future<void> createSchedule(EventItem event) async {
    final url = Uri.parse('$baseUrl/schedule');
    final response = await _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(event.toJson()),
    ));

    // HTTP 상태 코드가 200 (성공)이 아니면 예외를 발생시킴
    if (response.statusCode != 200) {
      print('일정 생성 실패: ${response.body}');
      throw Exception('일정 생성에 실패했습니다.');
    }
    // 성공 시에는 아무것도 반환하지 않음.
    // 호출한 화면(calendar_screen)에서 이 함수가 성공적으로 끝나면,
    // 월별 데이터를 다시 불러와 화면을 갱신할 것임.
  }


  // 일정 수정
  static Future<void> updateSchedule(EventItem event) async {
    final url = Uri.parse('$baseUrl/schedule/${event.id}');
    final response = await _sendRequest((headers) => http.patch(
      url,
      headers: headers,
      body: jsonEncode(event.toJson()),
    ));

    if (response.statusCode != 200) {
      throw Exception('일정 수정에 실패했습니다.');
    }
  }

  // 일정 삭제
  static Future<void> deleteSchedule(String scheduleId) async {
    final url = Uri.parse('$baseUrl/schedule/$scheduleId');
    final response = await _sendRequest((headers) => http.delete(url, headers: headers));

    if (response.statusCode != 200) {
      throw Exception('일정 삭제에 실패했습니다.');
    }
  }
}