import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'usage_reporter.dart';

class HarmfulAppService {
  static UsageReporter? _reporter;
  static const String _dataKeyPrefix = 'harmful_app_data_';
  static const Duration _cooldownDuration = Duration(hours: 1); // 4회 접속 후 1시간의 쿨다운

  // 서비스 시작
  static Future<void> start() async {
    // TODO: API를 통해 실제 유해앱 목록을 가져와야 합니다.
    const Set<String> harmfulApps = {
      'com.google.android.youtube',
      'com.instagram.android',
    };

    if (harmfulApps.isEmpty) return;

    _reporter = UsageReporter(
      interval: const Duration(seconds: 3),
      targets: harmfulApps,
      onTargetDetected: _onHarmfulAppDetected,
    );
    _reporter!.start();
    print('[HarmfulAppService] Service started. Monitoring: $harmfulApps');
  }

  // 서비스 중지
  static void stop() {
    _reporter?.stop();
    _reporter = null;
    print('[HarmfulAppService] Service stopped.');
  }

  // 유해앱 사용 감지 시 호출되는 콜백
  static Future<void> _onHarmfulAppDetected(String packageName) async {
    print('[HarmfulAppService] Detected: $packageName');
    final prefs = await SharedPreferences.getInstance();
    final dataKey = '$_dataKeyPrefix$packageName';

    // 1. 현재 상태 데이터 불러오기
    Map<String, dynamic> appData = {};
    final String? dataString = prefs.getString(dataKey);
    if (dataString != null) {
      appData = jsonDecode(dataString);
    }

    // 2. 날짜가 바뀌었는지 확인하여 카운트 초기화
    final String today = DateTime.now().toIso8601String().substring(0, 10);
    if (appData['lastAccessDate'] != today) {
      print('[HarmfulAppService] New day. Resetting count for $packageName');
      appData = {'count': 0, 'lastAccessDate': today};
    }

    /*
    // 3. 쿨다운 상태인지 확인
    if (appData.containsKey('cooldownUntil')) {
      final cooldownUntil = DateTime.parse(appData['cooldownUntil']);
      if (DateTime.now().isBefore(cooldownUntil)) {
        print('[HarmfulAppService] In cooldown for $packageName. Ignoring.');
        return; // 쿨다운 중이면 아무것도 하지 않음
      } else {
        // 쿨다운이 끝났으면 상태를 리셋
        print('[HarmfulAppService] Cooldown finished for $packageName. Resetting count.');
        appData = {'count': 0, 'lastAccessDate': today};
      }
    }
     */

    // 4. 카운트 증가 및 로직 처리
    int newCount = (appData['count'] as int? ?? 0) + 1;
    appData['count'] = newCount;
    appData['lastAccessDate'] = today;

    print('[HarmfulAppService] Usage count for $packageName: $newCount');

    http.Response? response;
    if (newCount <= 2) {
      print('[HarmfulAppService] Requesting motivation message...');
      response = await ApiService.getMotivationMessage(packageName);
    } else if (newCount == 3) {
      print('[HarmfulAppService] Requesting addiction treatment message...');
      response = await ApiService.getAddictionTreatmentMessage(packageName);
    } else if (newCount == 4) {
      print('[HarmfulAppService] Requesting final treatment message and starting cooldown...');
      response = await ApiService.getAddictionTreatmentMessage(packageName);
      // 4번째 알림 후 쿨다운 시작
      appData['cooldownUntil'] = DateTime.now().add(_cooldownDuration).toIso8601String();
    }

    if (response != null) {
       if (response.statusCode == 200) {
         print('[HarmfulAppService] API call successful. Backend will send a notification.');
       } else {
         print('[HarmfulAppService] API call failed with status: ${response.statusCode}');
       }
    }

    // 5. 업데이트된 상태 데이터 저장
    if (newCount >= 4) {
            print('[HarmfulAppService] Cycle complete. Resetting count to 0 for next access.');
           appData['count'] = 0;
         }
        await prefs.setString(dataKey, jsonEncode(appData));
    }


}
