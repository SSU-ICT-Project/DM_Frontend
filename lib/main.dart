// lib/main.dart

import 'package:flutter/material.dart';
// 우리가 만들었던 첫 번째 회원가입 화면 파일을 import 합니다.
// 파일 경로는 실제 프로젝트 구조에 맞게 조정해야 할 수 있습니다.
import 'screens/signup_step1_screen.dart';

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
      home: const SignupStep1Screen(),
    );
  }
}