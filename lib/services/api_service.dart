// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/harmful_apps_model.dart';
import '../models/app_usage_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/self_development_time_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart'; // 알림 관련 모델 추가

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

        // 사용자 ID 저장 (이메일을 임시로 사용자 ID로 사용)
        await prefs.setString('userId', email);

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
    
    // 전송할 데이터 로깅
    final requestBody = data.toJson();
    print('🚀 회원가입 API 호출 시작');
    print('📤 전송할 데이터: ${jsonEncode(requestBody)}');
    print('🔍 averagePreparationTime 값: "${data.averagePreparationTime}"');
    print('🔍 averagePreparationTime 타입: ${data.averagePreparationTime.runtimeType}');
    
    try {
      final response = await http.post(
        url,
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode(requestBody),
      );

      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ 회원가입 성공!');
        return null;
      } else {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        print('❌ 회원가입 실패: ${responseBody['message']}');
        return responseBody['message'] ?? '회원가입에 실패했습니다. 다시 시도해 주세요.';
      }
    } catch (e) {
      print('❌ 회원가입 중 오류 발생: $e');
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
    print('📅 월별 일정 조회 시작: $yearMonth');
    
    final url = Uri.parse('$baseUrl/schedule/month?yearMonth=$yearMonth');
    print('🌐 API URL: $url');
    
    final response = await _sendRequest((headers) => http.get(url, headers: headers));

    print('📡 응답 상태 코드: ${response.statusCode}');
    print('📡 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      print('📋 파싱된 응답 데이터: $body');
      
      final List<dynamic>? contents = body['dmPage']?['contents'];
      print('📋 일정 목록 개수: ${contents?.length ?? 0}');
      
      if (contents != null && contents.isNotEmpty) {
        print('🔍 첫 번째 일정 데이터: ${contents.first}');
        print('🔍 첫 번째 일정의 scheduleId: ${contents.first['scheduleId']}');
      }
      
      final events = contents?.map((json) {
        print('🔄 EventItem.fromJson() 호출: $json');
        final event = EventItem.fromJson(json);
        print('✅ 생성된 EventItem ID: ${event.id}');
        return event;
      }).toList() ?? [];
      
      print('📅 최종 일정 목록 (${events.length}개):');
      for (int i = 0; i < events.length; i++) {
        print('   ${i + 1}. ID: ${events[i].id}, 제목: ${events[i].title}');
      }
      
      return events;
    } else {
      if (response.statusCode == 401) {
        print('❌ 인증 실패 (401)');
        return [];
      }
      print('❌ 월별 일정 조회 실패: ${response.statusCode}');
      throw Exception('월별 일정을 불러오는데 실패했습니다.');
    }
  }

  // 일정 생성
  static Future<void> createSchedule(EventItem event) async {
    print('📅 일정 생성 시작');
    print('📋 일정 정보: ${event.toJson()}');
    
    final url = Uri.parse('$baseUrl/schedule');
    print('🌐 API URL: $url');
    
    final response = await _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(event.toJson()),
    ));

    print('📡 응답 상태 코드: ${response.statusCode}');
    print('📡 응답 본문: ${response.body}');

    if (response.statusCode != 200) {
      print('❌ 일정 생성 실패: ${response.body}');
      throw Exception('일정 생성에 실패했습니다.');
    }
    
    print('✅ 일정 생성 성공');
  }

  // 일정 수정
  static Future<void> updateSchedule(EventItem event) async {
    print('📝 일정 수정 시작');
    print('📋 수정할 일정 정보: ${event.toJson()}');
    
    final url = Uri.parse('$baseUrl/schedule/${event.id}');
    print('🌐 API URL: $url');
    
    final response = await _sendRequest((headers) => http.patch(
      url,
      headers: headers,
      body: jsonEncode(event.toJson()),
    ));

    print('📡 응답 상태 코드: ${response.statusCode}');
    print('📡 응답 본문: ${response.body}');

    if (response.statusCode != 200) {
      print('❌ 일정 수정 실패: ${response.body}');
      throw Exception('일정 수정에 실패했습니다.');
    }
    
    print('✅ 일정 수정 성공');
  }

  // 일정 삭제
  static Future<void> deleteSchedule(String scheduleId) async {
    print('🗑️ 일정 삭제 시작');
    print('🆔 삭제할 일정 ID: $scheduleId');
    
    final url = Uri.parse('$baseUrl/schedule/$scheduleId');
    print('🌐 API URL: $url');
    
    final response = await _sendRequest((headers) => http.delete(url, headers: headers));

    print('📡 응답 상태 코드: ${response.statusCode}');
    print('📡 응답 본문: ${response.body}');

    if (response.statusCode != 200) {
      print('❌ 일정 삭제 실패: ${response.body}');
      throw Exception('일정 삭제에 실패했습니다.');
    }
    
    print('✅ 일정 삭제 성공');
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

  // 앱 사용량 전송 (기존 엔드포인트 - 하위 호환성 유지)
  static Future<http.Response> sendAppUsage(AppUsageModel appUsage) async {
    final url = Uri.parse('$baseUrl/app-usage');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(appUsage.toJson()),
    ));
  }

  // --- 새로운 실시간 메시지 요청 API --- //

  // 동기부여 메시지 생성
  static Future<http.Response> getMotivationMessage(String packageName) async {
    final url = Uri.parse('$baseUrl/screenTime/motivate');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode({'packageName': packageName}),
    ));
  }

  // 중독치료 메시지 생성
  static Future<http.Response> getAddictionTreatmentMessage(String packageName) async {
    final url = Uri.parse('$baseUrl/screenTime/cure');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode({'packageName': packageName}),
    ));
  }

  // --- 기존 스크린타임 치료 API (하위 호환성) --- //

  // 스크린타임 치료 메시지 생성 (새로운 백엔드 API)
  static Future<http.Response> sendScreenTimeCure(AppUsageModel appUsage) async {
    final url = Uri.parse('$baseUrl/screenTime/cure');
    return _sendRequest((headers) => http.post(
      url,
      headers: headers,
      body: jsonEncode(appUsage.toJson()),
    ));
  }

  // 스크린타임 치료 메시지 생성 (응답 파싱 포함)
  static Future<ScreenTimeCureResponse?> sendScreenTimeCureWithResponse(AppUsageModel appUsage) async {
    try {
      print('🚀 스크린타임 치료 메시지 전송 시작...');
      print('📤 전송 데이터: ${jsonEncode(appUsage.toJson())}');
      
      final response = await sendScreenTimeCure(appUsage);
      
      print('📥 응답 상태 코드: ${response.statusCode}');
      print('📥 응답 헤더: ${response.headers}');
      print('📥 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final cureResponse = ScreenTimeCureResponse.fromJson(responseData);
        
        print('✅ 응답 파싱 성공:');
        print('   - Return Code: ${cureResponse.returnCode}');
        print('   - Return Message: ${cureResponse.returnMessage}');
        print('   - Data: ${cureResponse.data}');
        if (cureResponse.dmPage != null) {
          print('   - Page Info: ${cureResponse.dmPage!.totalCount}개 항목, ${cureResponse.dmPage!.totalPages}페이지');
        }
        
        return cureResponse;
      } else {
        print('❌ 스크린타임 치료 메시지 생성 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 스크린타임 치료 메시지 생성 중 오류 발생: $e');
      return null;
    }
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

  // 회원 상세 정보 조회 API
  static Future<MemberDetail?> getMemberDetail() async {
    final url = Uri.parse('$baseUrl/member/detail');
    print('🔍 회원 정보 조회 시작: $url');
    
    try {
      final response = await _sendRequest((headers) => http.get(url, headers: headers));
      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 헤더: ${response.headers}');
      print('📡 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print('🔍 파싱된 응답 데이터: $responseData');
        
        final Map<String, dynamic>? data = responseData['data'];
        print('🔍 data 필드: $data');
        
        if (data != null) {
          final memberDetail = MemberDetail.fromJson(data);
          print('✅ MemberDetail 객체 생성 성공: ${memberDetail.nickname}');
          return memberDetail;
        } else {
          print('❌ data 필드가 null입니다.');
          return null;
        }
      } else {
        print('❌ 회원 정보 조회 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 회원 정보 조회 중 오류 발생: $e');
      print('❌ 오류 타입: ${e.runtimeType}');
      return null;
    }
  }

  // 회원 정보 수정 API (multipart/form-data 형식)
  static Future<bool> updateMemberDetail(MemberDetail memberDetail) async {
    final url = Uri.parse('$baseUrl/member');
    print('🔍 회원 정보 수정 시작: $url');
    
    try {
      // _sendRequest를 통해 인증 토큰 포함하여 multipart/form-data 요청 전송
      final response = await _sendRequest((headers) async {
        // multipart/form-data 요청 생성
        final multipartRequest = http.MultipartRequest('PUT', url);
        
        // 헤더 설정
        multipartRequest.headers.addAll(headers);
        
        // memberForm JSON 데이터를 fields로 추가
        final memberFormJson = jsonEncode(memberDetail.toUpdateJson()['memberForm']);
        multipartRequest.fields['memberForm'] = memberFormJson;
        
        // imageFile을 빈 파일로 추가 (0-byte file)
        final emptyFile = http.MultipartFile.fromBytes(
          'imageFile',
          <int>[], // 빈 바이트 배열
          filename: 'empty.txt',
          // contentType 파라미터 제거하여 MediaType 타입 에러 해결
        );
        multipartRequest.files.add(emptyFile);
        
        print('📤 전송할 데이터 구조:');
        print('   📋 memberForm: $memberFormJson');
        print('   🖼️ imageFile: 빈 파일 (0-byte)');
        
        final streamedResponse = await multipartRequest.send();
        return await http.Response.fromStream(streamedResponse);
      });
      
      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ 회원 정보 수정 성공');
        return true;
      } else {
        print('❌ 회원 정보 수정 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 회원 정보 수정 중 오류 발생: $e');
      print('❌ 오류 타입: ${e.runtimeType}');
      return false;
    }
  }

  // 현재 사용자 ID 가져오기
  static Future<int> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // SharedPreferences에 저장된 모든 키 확인
      final keys = prefs.getKeys();
      print('🔍 SharedPreferences에 저장된 모든 키: $keys');
      
      // userId 관련 모든 데이터 확인
      if (keys.contains('userId')) {
        final userIdInt = prefs.getInt('userId');
        final userIdString = prefs.getString('userId');
        final userIdBool = prefs.getBool('userId');
        final userIdDouble = prefs.getDouble('userId');
        
        print('🔍 userId 데이터 타입별 조회:');
        print('   int: $userIdInt');
        print('   String: $userIdString');
        print('   bool: $userIdBool');
        print('   double: $userIdDouble');
      }
      
      // 먼저 int로 시도
      var userId = prefs.getInt('userId');
      print('🔍 SharedPreferences에서 int로 userId 조회: $userId');
      
      // int가 null이면 String으로 시도
      if (userId == null) {
        final userIdString = prefs.getString('userId');
        print('🔍 SharedPreferences에서 String으로 userId 조회: $userIdString');
        
        if (userIdString != null && userIdString.isNotEmpty) {
          try {
            userId = int.parse(userIdString);
            print('🔍 String을 int로 변환 성공: $userIdString -> $userId');
            
            // 변환 성공 시 int로 다시 저장 (선택사항)
            // await prefs.setInt('userId', userId);
            // print('🔍 userId를 int로 다시 저장: $userId');
          } catch (e) {
            print('⚠️ String을 int로 변환 실패: $userIdString, 0으로 설정');
            userId = 0;
          }
        } else {
          print('⚠️ userId가 null이거나 빈 문자열, 0으로 설정');
          userId = 0;
        }
      }
      
      print('🔍 최종 사용자 ID: $userId');
      return userId;
    } catch (e, stackTrace) {
      print('❌ _getCurrentUserId 실패: $e');
      print('❌ 오류 스택: $stackTrace');
      print('🔍 기본값 0 반환');
      return 0;
    }
  }

  // 알림 목록 조회 API
  static Future<NotificationApiResponse?> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    print('🔍 getNotifications 시작');
    print('🔍 파라미터: page=$page, size=$size');
    
    final currentUserId = await _getCurrentUserId();
    print('🔍 현재 사용자 ID: $currentUserId');
    
    final url = Uri.parse('$baseUrl/notification').replace(
      queryParameters: {
        'notificationPage': jsonEncode({
          'page': page,
          'size': size,
        }),
        'loginUser': jsonEncode({
          'id': currentUserId,
        }),
      },
    );
    
    print('🔍 요청 URL: $url');
    print('🔍 요청 파라미터:');
    print('   notificationPage: ${jsonEncode({'page': page, 'size': size})}');
    print('   loginUser: ${jsonEncode({'id': currentUserId})}');
    
    try {
      final response = await _sendRequest((headers) => http.get(url, headers: headers));
      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 헤더: ${response.headers}');
      print('📡 응답 본문 길이: ${response.body.length}');
      print('📡 응답 본문 (처음 500자): ${response.body.length > 500 ? response.body.substring(0, 500) + '...' : response.body}');
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          print('🔍 JSON 파싱 성공');
          print('🔍 응답 데이터 키들: ${responseData.keys.toList()}');
          
          final notificationResponse = NotificationApiResponse.fromJson(responseData);
          print('✅ 알림 목록 조회 성공');
          print('✅ 응답 코드: ${notificationResponse.returnCode}');
          print('✅ 응답 메시지: ${notificationResponse.returnMessage}');
          if (notificationResponse.dmPage != null) {
            print('✅ 페이지 정보: ${notificationResponse.dmPage!.contents.length}개 알림');
          }
          return notificationResponse;
        } catch (parseError, stackTrace) {
          print('❌ JSON 파싱 실패: $parseError');
          print('❌ 파싱 에러 스택: $stackTrace');
          print('❌ 파싱 실패한 응답 본문: ${response.body}');
          return null;
        }
      } else {
        print('❌ 알림 목록 조회 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ 알림 목록 조회 중 오류 발생: $e');
      print('❌ 오류 타입: ${e.runtimeType}');
      print('❌ 오류 스택: $stackTrace');
      return null;
    }
  }

  // 알림 읽음 처리 API
  static Future<bool> markNotificationsAsRead(List<int> notificationIds) async {
    print('🔍 markNotificationsAsRead 시작');
    print('🔍 읽음 처리할 알림 ID들: $notificationIds');
    
    final currentUserId = await _getCurrentUserId();
    print('🔍 현재 사용자 ID: $currentUserId');
    
    final url = Uri.parse('$baseUrl/notification').replace(
      queryParameters: {
        'loginUser': jsonEncode({
          'id': currentUserId,
        }),
      },
    );
    
    print('🔍 요청 URL: $url');
    print('🔍 요청 파라미터:');
    print('   loginUser: ${jsonEncode({'id': currentUserId})}');
    
    final requestBody = {
      'notificationIdList': notificationIds,
    };
    print('🔍 요청 본문: ${jsonEncode(requestBody)}');
    
    try {
      final response = await _sendRequest((headers) => http.put(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      ));
      
      print('📡 응답 상태 코드: ${response.statusCode}');
      print('📡 응답 헤더: ${response.headers}');
      print('📡 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          print('✅ 알림 읽음 처리 성공');
          print('✅ 응답 데이터: $responseData');
          return true;
        } catch (parseError) {
          print('⚠️ 응답 파싱 실패했지만 상태 코드는 성공: $parseError');
          return true;
        }
      } else {
        print('❌ 알림 읽음 처리 실패: ${response.statusCode}');
        print('❌ 응답 내용: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ 알림 읽음 처리 중 오류 발생: $e');
      print('❌ 오류 타입: ${e.runtimeType}');
      print('❌ 오류 스택: $stackTrace');
      return false;
    }
  }
}