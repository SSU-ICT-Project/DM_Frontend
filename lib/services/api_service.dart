// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/harmful_apps_model.dart';
import '../models/app_usage_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/self_development_time_model.dart';
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
      final fcmToken = prefs.getString('fcm_token');
      if (fcmToken != null) {
        await ApiService.deleteFCMToken(fcmToken);
        await prefs.remove('fcm_token');
      }
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
    final fcmToken = prefs.getString('fcm_token'); // FCM 토큰 가져오기

    if (fcmToken != null) {
      await ApiService.deleteFCMToken(fcmToken); // 백엔드에서 FCM 토큰 삭제
      await prefs.remove('fcm_token'); // 로컬에서 FCM 토큰 삭제
    }

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

  // 일정 생성
  static Future<void> createSchedule(EventItem event) async {
    final url = Uri.parse('$baseUrl/schedule');
    final response = await _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(event.toJson()),
    ));

    if (response.statusCode != 200) {
      print('일정 생성 실패: ${response.body}');
      throw Exception('일정 생성에 실패했습니다.');
    }
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

  // 메인 목표 API
  static Future<http.Response> getMainGoals({int page = 0, int size = 10}) async {
    final url = Uri.parse('$baseUrl/mainGoal?page=$page&size=$size');
    return _sendRequest((headers) => http.get(url, headers: headers));
  }

  static Future<http.Response> createMainGoal(Map<String, dynamic> goalData) async {
    final url = Uri.parse('$baseUrl/mainGoal');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(goalData),
    ));
  }

  static Future<http.Response> updateMainGoal(String mainGoalId, Map<String, dynamic> goalData) async {
    final url = Uri.parse('$baseUrl/mainGoal/$mainGoalId');
    return _sendRequest((headers) => http.put(
      url,
      headers: headers,
      body: jsonEncode(goalData),
    ));
  }

  static Future<http.Response> deleteMainGoal(String mainGoalId) async {
    final url = Uri.parse('$baseUrl/mainGoal/$mainGoalId');
    return _sendRequest((headers) => http.delete(url, headers: headers));
  }

  //하위 목표 API
  static Future<http.Response> createSubGoal(Map<String, dynamic> subGoalData) async {
    final url = Uri.parse('$baseUrl/subGoal');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(subGoalData),
    ));
  }

  static Future<http.Response> updateSubGoal(String subGoalId, Map<String, dynamic> subGoalData) async {
    final url = Uri.parse('$baseUrl/subGoal/$subGoalId');
    return _sendRequest((headers) => http.put(
      url,
      headers: headers,
      body: jsonEncode(subGoalData),
    ));
  }

  static Future<http.Response> deleteSubGoal(String subGoalId) async {
    final url = Uri.parse('$baseUrl/subGoal/$subGoalId');
    return _sendRequest((headers) => http.delete(url, headers: headers));
  }

  // 유해앱 및 앱 사용량 API
  static Future<http.Response> sendHarmfulApps(HarmfulAppsModel harmfulApps) async {
    final url = Uri.parse('$baseUrl/harmful-apps');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(harmfulApps.toJson()),
    ));
  }

  static Future<http.Response> getHarmfulApps() async {
    final url = Uri.parse('$baseUrl/harmful-apps');
    return _sendRequest((headers) => http.get(url, headers: headers));
  }

  static Future<http.Response> sendAppUsage(AppUsageModel appUsage) async {
    final url = Uri.parse('$baseUrl/app-usage');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(appUsage.toJson()),
    ));
  }

  static Future<http.Response> getAppUsage(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final url = Uri.parse('$baseUrl/app-usage?date=$dateStr');
    return _sendRequest((headers) => http.get(url, headers: headers));
  }

  static Future<http.Response> getAppUsageRange(DateTime startDate, DateTime endDate) async {
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];
    final url = Uri.parse('$baseUrl/app-usage/range?startDate=$startStr&endDate=$endStr');
    return _sendRequest((headers) => http.get(url, headers: headers));
  }

  // 자기개발시간 API
  static Future<http.Response> sendSelfDevelopmentTime(SelfDevelopmentTimeModel schedule) async {
    final url = Uri.parse('$baseUrl/self-development-time');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(schedule.toJson()),
    ));
  }

  static Future<http.Response> getSelfDevelopmentTime() async {
    final url = Uri.parse('$baseUrl/self-development-time');
    return _sendRequest((headers) => http.get(url, headers: headers));
  }

  // FCM Token 저장 API
  static Future<void> saveFCMToken(String token) async {
    final url = Uri.parse('$baseUrl/fcm');
    try {
      final response = await _sendRequest((headers) => http.post(
        url,
        headers: headers,
        body: jsonEncode({'fcmToken': token}), // 백엔드에서 'fcmToken' 필드를 기대할 것으로 예상
      ));

      if (response.statusCode == 200) {
        print('FCM Token successfully saved to backend.');
      } else {
        print('Failed to save FCM Token: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error saving FCM Token: $e');
    }
  }

  // FCM Token 삭제 API
  static Future<void> deleteFCMToken(String token) async {
    final url = Uri.parse('$baseUrl/fcm');
    try {
      final response = await _sendRequest((headers) => http.delete(
        url,
        headers: headers,
        body: jsonEncode({'fcmToken': token}), // 삭제 시에도 토큰을 본문에 포함하여 전송
      ));

      if (response.statusCode == 200) {
        print('FCM Token successfully deleted from backend.');
      } else {
        print('Failed to delete FCM Token: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error deleting FCM Token: $e');
    }
  }
}
