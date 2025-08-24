// lib/main.dart

import 'package:flutter/material.dart';
// 우리가 만들었던 첫 번째 회원가입 화면 파일을 import 합니다.
// 파일 경로는 실제 프로젝트 구조에 맞게 조정해야 할 수 있습니다.
import 'screens/signup_step1_screen.dart';
import 'screens/goals_screen.dart';
import 'services/usage_reporter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';  // 로그인 상태를 확인하기 위해 추가합니다.

// 모든 Flutter 앱의 시작점!
void main() {
  // MyApp 위젯을 화면에 표시하면서 앱을 시작합니다.
  runApp(const MyApp());
}

// 우리 앱의 최상위 루트 위젯입니다.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp은 앱의 기본 구조와 디자인(머티리얼 디자인)을 제공합니다.
    return MaterialApp(
      title: 'Digital Detox App', // 앱의 제목
      theme: ThemeData(
        // 앱의 전반적인 테마를 설정할 수 있습니다. (예: 색상, 폰트 등)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // 앱이 처음 시작될 때 보여줄 화면을 지정합니다.
      home: const InitialScreenDecider(), // InitialScreenDecider로 변경
    );
  }
}

// 앱 시작 시 로그인 상태를 확인하고 화면을 분기하는 위젯
class InitialScreenDecider extends StatefulWidget {
  const InitialScreenDecider({super.key});

  @override
  State<InitialScreenDecider> createState() => _InitialScreenDeciderState();
}

class _InitialScreenDeciderState extends State<InitialScreenDecider> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // SharedPreferences에서 로그인 토큰이 있는지 확인하는 비동기 함수
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken'); // 'accessToken' 키에 저장된 값 확인

    setState(() {
      _isLoggedIn = accessToken != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중일 때 로딩 인디케이터를 보여줍니다.
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF504A)),
        ),
      );
    }

    // 로그인 상태에 따라 다른 화면을 반환합니다.
    if (_isLoggedIn) {
      // 로그인 되어 있으면 목표 화면으로 이동
      return const AppLifecycleHandler(child: GoalsScreen());
    } else {
      // 로그인 안 되어 있으면 회원가입/로그인 화면으로 이동
      return const AppLifecycleHandler(child: SignupStep1Screen());
    }
  }
}


class AppLifecycleHandler extends StatefulWidget {
  final Widget child;
  const AppLifecycleHandler({required this.child, super.key});

  @override
  State<AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<AppLifecycleHandler> with WidgetsBindingObserver {
  UsageReporter? _reporter;
  static const _usageCh = MethodChannel('app.usage/access');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initReporter();
  }

  Future<void> _initReporter() async {
    try {
      final granted = await _usageCh.invokeMethod<bool>('isUsageAccessGranted') ?? false;
      if (!granted) return;
      _reporter = UsageReporter(
        interval: const Duration(seconds: 5),
        targets: {
          'com.google.android.youtube', // YouTube
          'com.instagram.android',      // Instagram
          'com.zhiliaoapp.musically',   // TikTok (참고)
        },
        onTargetDetected: (pkg) {
          // TODO: 백엔드로 전송 (현재는 로그 대체)
          // Api.post('/usage/detected', { 'package': pkg, 'at': DateTime.now().toIso8601String() })
          debugPrint('Detected foreground target: $pkg');
        },
      );
      await _reporter!.start();

      // 일일 집계 샘플: 자정 기준 전일 사용량 전송
      final now = DateTime.now();
      final begin = DateTime(now.year, now.month, now.day);
      final end = now;
      final summary = await UsageReporter.fetchUsageSummary(
        begin: begin,
        end: end,
        packages: {
          'com.google.android.youtube',
          'com.instagram.android',
          'com.zhiliaoapp.musically',
        },
      );
      debugPrint('Usage summary(ms): $summary');
      // TODO: 백엔드로 summary 전송
      // Api.post('/usage/summary', {
      //   'begin': begin.toIso8601String(),
      //   'end': end.toIso8601String(),
      //   'data': summary,
      // })
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _reporter?.stop();
    } else if (state == AppLifecycleState.resumed) {
      _initReporter();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reporter?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}