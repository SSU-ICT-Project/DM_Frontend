import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_step2_screen.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'goals_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in your background callbacks,
  // such as Firestore, make sure you call `initializeApp` before using them.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  if (message.notification != null) {
    print('Background message contained a notification: ${message.notification?.title} / ${message.notification?.body}');
  }
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscure = true;
  static const _usageChannel = MethodChannel('app.usage/access');
  bool _usageGranted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkUsageAccess() async {
    try {
      final granted = await _usageChannel.invokeMethod<bool>('isUsageAccessGranted') ?? false;
      setState(() => _usageGranted = granted);
      if (!granted) {
        await _usageChannel.invokeMethod('openUsageAccessSettings');
      }
    } catch (_) {}
  }

  Future<void> _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    final prefs = await SharedPreferences.getInstance();

    // Request permission for notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Get FCM token
      String? currentToken = await messaging.getToken();
      print("FCM Current Token: $currentToken");

      String? savedToken = prefs.getString('fcm_token');

      if (currentToken != null && currentToken != savedToken) {
        // Save token to backend via API service
        await ApiService.saveFCMToken(currentToken);
        await prefs.setString('fcm_token', currentToken);
        print('FCM Token sent to backend and saved locally.');
      } else if (currentToken != null && savedToken == currentToken) {
        print('FCM Token is already up-to-date.');
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) async {
        print("FCM Token Refreshed: $newToken");
        await ApiService.saveFCMToken(newToken);
        await prefs.setString('fcm_token', newToken);
        print('Refreshed FCM Token sent to backend and saved locally.');
      });
    } else {
      print('User declined or has not accepted notification permission.');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification?.title} / ${message.notification?.body}');
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // 로그인 버튼에 연결할 함수 (로그인 API 호출)
  Future<void> _onSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 진행 중...')),
      );
      final errorMessage = await ApiService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (errorMessage == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 성공! 🎉')));

        // FCM 토큰 발급 및 저장 로직 호출
        await _initFCM();

        // 로그인 성공 시 홈 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GoalsScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $errorMessage 😥')),
        );
      }
    }
  }

  // 회원가입 버튼에 연결할 함수 (회원가입 2단계 화면으로 이동)
  void _onSignUp() {
    // 회원가입 2단계 화면으로 이동
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignupStep2Screen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 140),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Digital Minimalism',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 35,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.21,
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Text(
                '로그인 / 회원가입', // 텍스트 변경
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 12),

              // ID / Password 그룹 박스
              Form(
                key: _formKey,
                child: Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: TextFormField(
                          controller: _emailController,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: '이메일(ID)', // 힌트 텍스트 변경
                            hintStyle: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w100,
                              color: Colors.white,
                              height: 1.21,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이메일(ID)을 입력해 주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, color: Colors.black.withOpacity(0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscure,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: '비밀번호', // 힌트 텍스트 변경
                            hintStyle: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w100,
                              color: Colors.white,
                              height: 1.21,
                            ),
                            suffixIcon: IconButton(
                              tooltip: _isObscure ? '표시' : '숨기기',
                              icon: Icon(
                                _isObscure ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _isObscure = !_isObscure),
                            ),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) return '비밀번호를 입력해 주세요.';
                            if (text.length < 4) return '비밀번호는 8자 이상이어야 합니다.';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: 280,
                height: 40,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF504A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _onSignIn, // 로그인 함수 호출로 변경
                  child: Text(
                    '로그인', // 'Sign in' -> '로그인'으로 변경
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.21,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8), // 로그인과 회원가입 버튼 사이 간격 추가
              SizedBox(
                width: 280,
                height: 40,
                child: OutlinedButton( // 회원가입 버튼 추가
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _onSignUp, // 회원가입 함수 호출
                  child: Text(
                    '회원가입',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.21,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),
              Row(
                children: [
                  const Expanded(child: _ThinWhiteLine()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '간편 로그인',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.21,
                      ),
                    ),
                  ),
                  const Expanded(child: _ThinWhiteLine()),
                ],
              ),

              const SizedBox(height: 16),
              _GoogleLoginButton(),
              const SizedBox(height: 16),
              Text(
                '구글 캘린더 연동을 위해 구글 간편 로그인을 추천드립니다.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThinWhiteLine extends StatelessWidget {
  const _ThinWhiteLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white,
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 40,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          // TODO: 실제 구글 로그인 연동
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('구글 로그인 연동 예정')));
        },
        icon: const Icon(Icons.account_circle, size: 16, color: Colors.white),
        label: Text(
          'Google로 계속',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}