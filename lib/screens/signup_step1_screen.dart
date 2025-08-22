import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_step2_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
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

  Future<void> _requestNotificationPermissionIfNeeded() async {
    // Android 13+ POST_NOTIFICATIONS / iOS notification permission
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: 다음 단계 네비게이션 또는 상태 저장 로직 연결
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효성 검사가 완료되었습니다. 다음 단계로 진행합니다.')),
      );
    }
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
                '로그인',
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
                            hintText: 'ID',
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
                            hintText: 'Password',
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
                            if (text.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
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
                  onPressed: () async {
                    await _checkUsageAccess();
                    await _requestNotificationPermissionIfNeeded();
                    // 구글 로그인 성공 콜백에서 이 로직을 호출한다고 가정
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupStep2Screen()),
                    );
                  },
                  child: Text(
                    'Sign in',
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
        icon: const FaIcon(FontAwesomeIcons.google, size: 16, color: Colors.white),
        label: Text(
          'Google로 계속',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}


