// lib/main.dart

import 'package:flutter/material.dart';
// 우리가 만들었던 첫 번째 회원가입 화면 파일을 import 합니다.
// 파일 경로는 실제 프로젝트 구조에 맞게 조정해야 할 수 있습니다.
import 'screens/signup_step1_screen.dart';
import 'screens/goals_screen.dart';
import 'services/usage_reporter.dart';
import 'package:flutter/services.dart';

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
      home: AppLifecycleHandler(child: const GoalsScreen()),
    );
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