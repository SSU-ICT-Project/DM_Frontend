import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_usage_model.dart';
import 'api_service.dart';
import 'usage_reporter.dart';
import 'dart:convert'; // jsonDecode, jsonEncode 추가

class AppUsageService {
  static const String _lastSyncKey = 'lastAppUsageSync';
  static const String _userIdKey = 'userId';
  
  // 앱 사용량을 수집하고 백엔드로 전송
  static Future<void> collectAndSendUsage({
    required DateTime date,
    Set<String>? specificApps,
  }) async {
    try {
      // 앱 사용량 데이터 수집
      final appUsage = await _collectAppUsage(date, specificApps);
      
      if (appUsage != null) {
        // 백엔드로 전송 (새로운 screenTime/cure 엔드포인트 사용)
        final cureResponse = await ApiService.sendScreenTimeCureWithResponse(appUsage);
        
        if (cureResponse != null && cureResponse.isSuccess) {
          print('스크린타임 치료 메시지 생성 성공: ${date.toIso8601String()}');
          print('응답 메시지: ${cureResponse.returnMessage}');
          print('치료 데이터: ${cureResponse.data}');
          await _updateLastSyncTime(date);
          await _saveLastSentData(appUsage); // 성공 시 데이터 저장
        } else {
          print('스크린타임 치료 메시지 생성 실패');
          
          // 실패 시 기존 엔드포인트로 재시도 (하위 호환성)
          print('기존 엔드포인트로 재시도 중...');
          final fallbackResponse = await ApiService.sendAppUsage(appUsage);
          if (fallbackResponse.statusCode == 200) {
            print('기존 엔드포인트로 전송 성공');
            await _updateLastSyncTime(date);
            await _saveLastSentData(appUsage); // 성공 시 데이터 저장
          } else {
            print('기존 엔드포인트 전송도 실패: ${fallbackResponse.statusCode}');
          }
        }
      }
    } catch (e) {
      print('앱 사용량 수집 및 전송 중 오류 발생: $e');
    }
  }

  // 앱 사용량 데이터 수집
  static Future<AppUsageModel?> _collectAppUsage(
    DateTime date,
    Set<String>? specificApps,
  ) async {
    try {
      print('🔍 앱 사용량 수집 시작: ${date.toIso8601String()}');
      
      // 사용자 ID 가져오기 (SharedPreferences에서)
      final prefs = await SharedPreferences.getInstance();
      String userId = prefs.getString(_userIdKey) ?? '';
      
      // 사용자 ID가 없으면 기본값 사용 (테스트용)
      if (userId.isEmpty) {
        userId = 'default_user';
        print('⚠️ 사용자 ID가 설정되지 않음, 기본값 사용: $userId');
      }
      
      print('👤 사용자 ID: $userId');
      
      // 앱 사용량 요약 가져오기
      final begin = DateTime(date.year, date.month, date.day);
      final end = begin.add(const Duration(days: 1));
      print('📅 수집 기간: ${begin.toIso8601String()} ~ ${end.toIso8601String()}');
      
      if (specificApps != null) {
        print('🎯 특정 앱만 수집: ${specificApps.join(', ')}');
      }
      
      final usageSummary = await UsageReporter.fetchUsageSummary(
        begin: begin,
        end: end,
        packages: specificApps,
      );
      
      print('📊 수집된 앱 개수: ${usageSummary.length}');
      
      if (usageSummary.isEmpty) {
        print('⚠️ 수집된 앱 사용량이 없습니다');
        return null;
      }
      
      // 앱 사용량 데이터 변환
      final List<AppUsageData> appUsages = [];
      int totalScreenTime = 0;
      
      print('🔄 앱 사용량 데이터 변환 중...');
      for (final entry in usageSummary.entries) {
        final packageName = entry.key;
        final usageTimeMs = entry.value;
        final usageTimeMinutes = (usageTimeMs / (1000 * 60)).round(); // 밀리초를 분으로 변환
        
        print('📱 $packageName: ${usageTimeMs}ms (${usageTimeMinutes}분)');
        
        if (usageTimeMinutes > 0) {
          appUsages.add(AppUsageData(
            packageName: packageName,
            appName: _getAppName(packageName), // 앱 이름은 나중에 구현
            usageTimeMinutes: usageTimeMinutes,
            lastUsed: end,
          ));
          
          totalScreenTime += usageTimeMinutes;
        }
      }
      
      // 사용 시간 순으로 정렬
      appUsages.sort((a, b) => b.usageTimeMinutes.compareTo(a.usageTimeMinutes));
      
      print('📈 총 스크린타임: ${totalScreenTime}분');
      print('✅ 앱 사용량 수집 완료');
      
      return AppUsageModel(
        userId: userId,
        date: date,
        appUsages: appUsages,
        totalScreenTime: totalScreenTime,
      );
    } catch (e) {
      print('❌ 앱 사용량 수집 중 오류 발생: $e');
      return null;
    }
  }

  // 앱 이름 가져오기 (간단한 구현)
  static String _getAppName(String packageName) {
    // 실제로는 설치된 앱 목록에서 앱 이름을 가져와야 함
    // 현재는 패키지명을 그대로 반환
    return packageName;
  }

  // 마지막 동기화 시간 업데이트
  static Future<void> _updateLastSyncTime(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, date.toIso8601String());
  }

  // 마지막 동기화 시간 가져오기
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastSyncKey);
    if (lastSyncStr != null) {
      try {
        return DateTime.parse(lastSyncStr);
      } catch (e) {
        print('마지막 동기화 시간 파싱 오류: $e');
      }
    }
    return null;
  }

  // 동기화가 필요한지 확인
  static Future<bool> needsSync(DateTime date) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    // 마지막 동기화 날짜와 현재 날짜가 다르면 동기화 필요
    return !_isSameDay(lastSync, date);
  }

  // 같은 날짜인지 확인
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // 정기적인 앱 사용량 동기화 (백그라운드에서 실행)
  static Future<void> schedulePeriodicSync() async {
    // 매일 자정에 동기화
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    if (await needsSync(now)) {
      await collectAndSendUsage(date: now);
    }
  }

  // 특정 앱들의 사용량만 동기화
  static Future<void> syncSpecificApps(Set<String> packageNames) async {
    final now = DateTime.now();
    await collectAndSendUsage(date: now, specificApps: packageNames);
  }

  // 사용자 ID 설정
  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    print('사용자 ID 설정 완료: $userId');
  }

  // 사용자 ID 가져오기
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // 마지막으로 전송된 앱 사용량 데이터 가져오기
  static Future<AppUsageModel?> getLastSentData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDataStr = prefs.getString('lastSentAppUsageData');
    
    if (lastDataStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(lastDataStr);
        return AppUsageModel.fromJson(data);
      } catch (e) {
        print('마지막 전송 데이터 파싱 오류: $e');
      }
    }
    return null;
  }

  // 전송된 데이터 저장
  static Future<void> _saveLastSentData(AppUsageModel data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSentAppUsageData', jsonEncode(data.toJson()));
  }
}
