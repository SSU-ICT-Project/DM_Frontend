import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'motivation_type_screen.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();

  bool _permissionAllowed = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _jobController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 1, top: 12, bottom: 24),
                child: Text(
                  'Digital Minimalism',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF504A),
                    height: 1.21,
                  ),
                ),
              ),

              Text(
                '가입 정보',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 24),

              // 닉네임
              Text(
                '닉네임',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 6),
              _GrayInputBox(
                controller: _nicknameController,
                hintText: '사용자님을 어떻게 부를까요?',
              ),
              const SizedBox(height: 20),

              // 직업
              Text(
                '직업',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 6),
              _GrayInputBox(
                controller: _jobController,
                hintText: 'AI가 당신의 직업을 고려해 동기부여 해줍니다!',
              ),
              const SizedBox(height: 20),

              // 생년
              Text(
                '생년',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.21,
                ),
              ),
              const SizedBox(height: 6),
              _GrayInputBox(
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                hintText: 'AI가 당신의 연령을 고려해 동기부여 해줍니다!',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Color(0xFFCE0000)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '숫자 4자리 “생년”을 입력해야합니다.',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF717171),
                        height: 1.21,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),



              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: SizedBox(
            height: 46,
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF504A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // 다음 화면(동기부여 타입 선택)으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MotivationTypeScreen()),
                );
              },
              child: Text(
                '다음',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.21,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GrayInputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;

  const _GrayInputBox({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration.collapsed(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: const Color(0xFF717171),
            height: 1.21,
          ),
        ),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}


