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

class _SignupStep1ScreenState extends State<SignupStep1Screen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isObscure = true;
  static const _usageChannel = MethodChannel('app.usage/access');
  bool _usageGranted = false;
  
  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              
              // 로고 및 타이틀 섹션
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF504A), Color(0xFFFF6B6B)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF504A).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Digital Minimalism',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        background: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFFFF504A), Color(0xFFFF6B6B)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '디지털 미니멀리즘으로 더 나은 삶을',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // 로그인/회원가입 폼 섹션
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        '로그인 / 회원가입',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 폼
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: '이메일',
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: 'example@email.com',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '이메일을 입력해 주세요.';
                                }
                                if (!value.contains('@')) {
                                  return '유효한 이메일 형식을 입력해 주세요.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscure,
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                //hintText: '8자 이상 입력해 주세요',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.white60,
                                  ),
                                  onPressed: () => setState(() => _isObscure = !_isObscure),
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return '비밀번호를 입력해 주세요.';
                                //if (text.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 버튼들
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _onSignIn,
                              child: const Text(
                                '로그인',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _onSignUp,
                              child: const Text(
                                '회원가입',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 구분선
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '간편 로그인',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 구글 로그인 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('구글 로그인 연동 예정')),
                            );
                          },
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text(
                            'Google로 계속하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        '구글 캘린더 연동을 위해 구글 간편 로그인을 추천드립니다.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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