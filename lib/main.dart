import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/goals_screen.dart';
import 'screens/permission_request_screen.dart';
import 'services/api_service.dart';

// --- FCM 설정 --- //

// 공통 로그 출력 함수
void _logFcmMessage(String event, RemoteMessage message) {
  if (kDebugMode) {
    print('--- FCM $event ---');
    print('Message ID: ${message.messageId}');
    if (message.notification != null) {
      print('  Original Title: ${message.notification!.title}');
      print('  Original Body: ${message.notification!.body}');
    }
    if (message.data.isNotEmpty) {
      print('  Data: ${message.data}');
    }
    print('-------------------');
  }
}

// 공통 알림 표시 함수
void _showNotification(RemoteNotification notification) {
  // body가 JSON 형태일 경우, content 필드를 추출
  String notificationBody;
  try {
    final bodyJson = jsonDecode(notification.body!);
    notificationBody = bodyJson['content'] ?? notification.body!;
  } catch (e) {
    notificationBody = notification.body!;
  }

  flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification.title,
    notificationBody, // 가공된 body 사용
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: 'launch_background', // TODO: 알림 아이콘 확인 필요
      ),
    ),
  );
}

// 백그라운드 메시지 핸들러는 최상위 레벨에 정의되어야 합니다.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _logFcmMessage('Background Message', message);

  // 백그라운드에서도 로컬 알림을 표시하기 위해 플러그인 초기화
  await setupFlutterNotifications();
  if (message.notification != null) {
    _showNotification(message.notification!); // 공통 함수 호출
  }
}

// Foreground 알림을 위한 로컬 알림 플러그인 인스턴스 생성
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Foreground 알림을 위한 채널 생성
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

// 로컬 알림 플러그인 초기화 함수 (중복 실행 방지)
bool _isFlutterLocalNotificationsInitialized = false;
Future<void> setupFlutterNotifications() async {
  if (_isFlutterLocalNotificationsInitialized) return;

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  _isFlutterLocalNotificationsInitialized = true;
}

// FCM 관련 모든 설정을 처리하는 함수
Future<void> setupFCM() async {
  // 1. 로컬 알림 플러그인 설정
  await setupFlutterNotifications();

  // 2. 알림 권한 요청
  final messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('알림 권한 상태: ${settings.authorizationStatus}');

  // 3. FCM 토큰 가져오기 및 서버 전송
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    final fcmToken = await messaging.getToken();
    print("FCM Token: $fcmToken");

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (fcmToken != null && accessToken != null) {
      try {
        await ApiService.saveFCMToken(fcmToken);
      } catch (e) {
        print('FCM 토큰 서버 저장 실패: $e');
      }
    }

    messaging.onTokenRefresh.listen((newToken) async {
      if (accessToken != null) {
        print('FCM 토큰 갱신: $newToken');
        await ApiService.saveFCMToken(newToken);
      }
    });
  }

  // 4. Foreground 메시지 리스너 설정
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _logFcmMessage('Foreground Message', message);
    if (message.notification != null) {
      _showNotification(message.notification!); // 공통 함수 호출
    }
  });

  // 5. 알림 클릭 시 이벤트 처리
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _logFcmMessage('Notification Clicked', message);
  });
}

// --- 앱 시작점 --- //

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await setupFCM();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Minimalism',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF504A),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A1A),
          background: const Color(0xFF0A0A0A),
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF504A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF504A), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
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
      final prefs = await SharedPreferences.getInstance();
      final savedPermissionsGranted = prefs.getBool('permissions_granted') ?? false;

      if (savedPermissionsGranted) {
        setState(() {
          _permissionsGranted = true;
          _isLoading = false;
        });
      } else {
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

    return _permissionsGranted ? const GoalsScreen() : const PermissionRequestScreen();
  }
}
