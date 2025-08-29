import 'package:flutter/material.dart';
import 'package:frontend/screens/signup_step1_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'goals_screen.dart';
import '../models/user_model.dart';
import '../models/motivation.dart' as model;

typedef MotivationType = model.MotivationType;

class MotivationTypeScreen extends StatefulWidget {
  // ✅ final로 signUpData 필드 추가
  final SignUpData signUpData;

  // ✅ 생성자에서 signUpData를 인자로 받도록 수정
  const MotivationTypeScreen({
    required this.signUpData,
    super.key,
  });

  @override
  State<MotivationTypeScreen> createState() => _MotivationTypeScreenState();
}

class _MotivationTypeScreenState extends State<MotivationTypeScreen> {
  MotivationType? _selectedType;

  // 이 메서드를 통해 선택된 동기부여 타입을 백엔드로 전송해야 합니다.
  Future<void> _completeSignup() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('동기 부여 타입을 선택해 주세요.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회원가입 진행 중...')),
    );

    // 전달받은 signUpData에 motivationType 정보 추가
    widget.signUpData.motivationType = _selectedType;

    // ApiService.signUp 함수 호출
    final errorMessage = await ApiService.signUp(widget.signUpData);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); // 기존 스낵바 숨기기
      if (errorMessage == null) {
        // 회원가입 성공
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 🎉')),
        );
        // 로그인 화면으로 돌아가기
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignupStep1Screen()),
              (route) => false,
        );
      } else {
        // 회원가입 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: $errorMessage 😥')),
        );
      }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 1, top: 12, bottom: 12),
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

              const _WhiteDivider(thickness: 2),
              const SizedBox(height: 20),

              Text(
                '동기부여 타입',
                style: GoogleFonts.notoSansKr(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '어떤 멘트가 ${(UserSession.nickname ?? UserSession.name ?? '사용자')}님이 유튜브를 끄도록 만드나요?',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.21,
                ),
              ),

              const SizedBox(height: 24),
              _TypeTile(
                isSelected: _selectedType == MotivationType.HABITUAL_WATCHER,
                onTap: () => setState(() => _selectedType = MotivationType.HABITUAL_WATCHER),
                titleLines: const [
                  '습관적 시청형',
                  '"지금 5분만 멈추면, 내일이 달라집니다."',
                ],
              ),
              const SizedBox(height: 16),
              _TypeTile(
                isSelected: _selectedType == MotivationType.COMFORT_SEEKER,
                onTap: () => setState(() => _selectedType = MotivationType.COMFORT_SEEKER),
                titleLines: const [
                  '위로 추구형',
                  '"피곤할 땐 쉬어도 돼요. 하지만 진짜 회복은 목표에 다가설 때 옵니다."',
                ],
              ),
              const SizedBox(height: 16),
              _TypeTile(
                isSelected: _selectedType == MotivationType.THRILL_SEEKER,
                onTap: () => setState(() => _selectedType = MotivationType.THRILL_SEEKER),
                titleLines: const [
                  '자극 추구형',
                  '"쇼츠가 널 잡을까, 네가 이길까? 지금 선택해보세요."',
                ],
              ),

              const SizedBox(height: 36),
              Center(
                child: Text(
                  '언제든지 다시 설정에서 타입을 바꿀 수 있어요',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 100), // 하단 버튼과의 간격 확보
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
              onPressed: _selectedType == null ? null : _completeSignup,
              child: Text(
                '가입 완료',
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

  String _labelOf(MotivationType type) {
    switch (type) {
      case MotivationType.HABITUAL_WATCHER:
        return '습관적 시청형';
      case MotivationType.COMFORT_SEEKER:
        return '위로 추구형';
      case MotivationType.THRILL_SEEKER:
        return '자극 추구형';
    }
  }
}

class _TypeTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final List<String> titleLines;

  const _TypeTile({
    required this.isSelected,
    required this.onTap,
    required this.titleLines,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF504A) : Colors.transparent,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleLines.first,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.21,
                  ),
                ),
                if (titleLines.length > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    titleLines[1],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.21,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteDivider extends StatelessWidget {
  final double thickness;
  const _WhiteDivider({this.thickness = 1});

  @override
  Widget build(BuildContext context) {
    return Container(height: thickness, color: Colors.white);
  }
}

