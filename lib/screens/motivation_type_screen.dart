import 'package:flutter/material.dart';
import 'package:frontend/screens/signup_step1_screen.dart';
import '../services/api_service.dart';
import 'goals_screen.dart';
import '../models/user_model.dart';
import '../models/motivation.dart' as model;

typedef MotivationType = model.MotivationType;

class MotivationTypeScreen extends StatefulWidget {
  final SignUpData signUpData;

  const MotivationTypeScreen({
    required this.signUpData,
    super.key,
  });

  @override
  State<MotivationTypeScreen> createState() => _MotivationTypeScreenState();
}

class _MotivationTypeScreenState extends State<MotivationTypeScreen> {
  MotivationType? _selectedType;

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

    widget.signUpData.motivationType = _selectedType;

    final errorMessage = await ApiService.signUp(widget.signUpData);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 🎉')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignupStep1Screen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: $errorMessage 😥')),
        );
      }
    }
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
              const SizedBox(height: 60),
              
              // 타이틀 섹션
              Column(
                children: [
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

              const SizedBox(height: 60),

              // 동기부여 타입 선택 섹션
              Column(
                children: [
                  Text(
                    '동기부여 타입',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '어떤 멘트가 ${(UserSession.nickname ?? UserSession.name ?? '사용자')}님이 유튜브를 끄도록 만드나요?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // 동기부여 타입 선택지들
                  _TypeTile(
                    isSelected: _selectedType == MotivationType.HABITUAL_WATCHER,
                    onTap: () => setState(() => _selectedType = MotivationType.HABITUAL_WATCHER),
                    titleLines: const [
                      '습관적 시청형',
                      '"지금 5분만 멈추면, 내일이 달라집니다."',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _TypeTile(
                    isSelected: _selectedType == MotivationType.COMFORT_SEEKER,
                    onTap: () => setState(() => _selectedType = MotivationType.COMFORT_SEEKER),
                    titleLines: const [
                      '위로 추구형',
                      '"피곤할 땐 쉬어도 돼요. 하지만 진짜 회복은 목표에 다가설 때 옵니다."',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _TypeTile(
                    isSelected: _selectedType == MotivationType.THRILL_SEEKER,
                    onTap: () => setState(() => _selectedType = MotivationType.THRILL_SEEKER),
                    titleLines: const [
                      '자극 추구형',
                      '"쇼츠가 널 잡을까, 네가 이길까? 지금 선택해보세요."',
                    ],
                  ),

                  const SizedBox(height: 40),
                  
                  // 안내 텍스트
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      '언제든지 다시 설정에서 타입을 바꿀 수 있어요',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF504A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFFF504A).withOpacity(0.3),
              ),
              onPressed: _selectedType == null ? null : _completeSignup,
              child: const Text(
                '가입 완료',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF504A) : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF504A) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF504A) : Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleLines.first,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (titleLines.length > 1) ...[
                        const SizedBox(height: 8),
                        Text(
                          titleLines[1],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected ? Colors.white : Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

