// lib/main.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/permission_request_screen.dart';
import 'screens/goals_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DM Frontend',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const PermissionCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PermissionCheckScreen extends StatefulWidget {
  const PermissionCheckScreen({super.key});

  @override
  State<PermissionCheckScreen> createState() => _PermissionCheckScreenState();
}

class _PermissionCheckScreenState extends State<PermissionCheckScreen> {
  bool _isLoading = true;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // 먼저 저장된 권한 상태 확인
      final prefs = await SharedPreferences.getInstance();
      final savedPermissionsGranted = prefs.getBool('permissions_granted') ?? false;
      
      if (savedPermissionsGranted) {
        // 저장된 상태가 있으면 바로 메인 화면으로 이동 (권한 재확인 없이)
        setState(() {
          _permissionsGranted = true;
          _isLoading = false;
        });
      } else {
        // 저장된 상태가 없으면 권한 상태 확인
        final permissions = [
          Permission.notification,
          Permission.location,
          Permission.camera,
          Permission.microphone,
          Permission.storage,
        ];

        bool allGranted = true;
        for (final permission in permissions) {
          final status = await permission.status;
          if (!status.isGranted && !status.isLimited) {
            allGranted = false;
            break;
          }
        }

        // 모든 권한이 이미 허용된 경우 상태 저장
        if (allGranted) {
          await prefs.setBool('permissions_granted', true);
          await prefs.setString('permissions_granted_date', DateTime.now().toIso8601String());
        }

        setState(() {
          _permissionsGranted = allGranted;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('권한 확인 중 오류: $e');
      setState(() {
        _permissionsGranted = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF504A),
          ),
        ),
      );
    }

    // 권한이 이미 허용된 경우 메인 화면으로, 그렇지 않으면 권한 요청 화면으로
    return _permissionsGranted ? const GoalsScreen() : const PermissionRequestScreen();
  }
}