import 'dart:convert';
import 'dart:math';

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
import 'services/harmful_app_service.dart';

// --- Global Keys & Services --- //

// 앱의 어느 곳에서든 Navigator 상태에 접근하기 위한 GlobalKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 로컬 알림 플러그인 인스턴스
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// --- FCM 설정 --- //

// 공통 로그 출력 함수
void _logFcmMessage(String event, RemoteMessage message) {
  if (kDebugMode) {
    print('--- FCM $event ---');
    print('Message ID: ${message.messageId}');
    if (message.data.isNotEmpty) {
      print('  Data Payload: ${message.data}');
    }
    print('-------------------');
  }
}

// data 페이로드로부터 내용을 파싱하는 함수
String _parseNotificationBody(Map<String, dynamic> data) {
  final dynamic bodyData = data['body'];
  String notificationBody = '내용 없음';

  if (bodyData is String) {
    try {
      final bodyJson = jsonDecode(bodyData);
      if (bodyJson is Map<String, dynamic>) {
        notificationBody = bodyJson['content'] as String? ?? bodyData;
      }
    } catch (e) {
      notificationBody = bodyData;
    }
  } else if (bodyData is Map) {
    notificationBody = bodyData['content'] as String? ?? '내용 없음';
  }
  return notificationBody;
}

// 백그라운드 알림 표시 함수 (상단 배너)
void _showHeadsUpNotification(Map<String, dynamic> data) {
  final String title = data['title'] as String? ?? '새로운 알림';
  final String body = _parseNotificationBody(data);

  final int notificationId = Random().nextInt(2147483647);

  flutterLocalNotificationsPlugin.show(
    notificationId,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: 'launch_background',
        importance: Importance.max, // 헤드업 알림을 위해 중요도 최대로 설정
        priority: Priority.high,   // 헤드업 알림을 위해 우선순위 최대로 설정
      ),
    ),
  );
}

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _logFcmMessage('Background Message', message);
  await setupFlutterNotifications();
  _showHeadsUpNotification(message.data);
}

// 알림 채널
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

// 로컬 알림 플러그인 초기화 (중복 방지)
bool _isFlutterLocalNotificationsInitialized = false;
Future<void> setupFlutterNotifications() async {
  if (_isFlutterLocalNotificationsInitialized) return;
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  _isFlutterLocalNotificationsInitialized = true;
}

// FCM 전체 설정
Future<void> setupFCM() async {
  await setupFlutterNotifications();

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Foreground 메시지 리스너 (인앱 팝업 처리)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _logFcmMessage('Foreground Message', message);

    final BuildContext? context = navigatorKey.currentContext;
    if (context != null) {
      final String title = message.data['title'] ?? '새로운 알림';
      final String body = _parseNotificationBody(message.data);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              child: const Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  });

  // 알림 클릭 시 이벤트 처리
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _logFcmMessage('Notification Clicked', message);
  });

  // 앱 시작 시 토큰 처리
  final settings = await messaging.getNotificationSettings();
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
}

// --- 앱 시작점 --- //

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await setupFCM();

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('accessToken') != null) {
    await HarmfulAppService.start();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // NavigatorKey 설정
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
