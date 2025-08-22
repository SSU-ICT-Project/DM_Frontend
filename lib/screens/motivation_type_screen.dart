import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goals_screen.dart';
import '../models/user_model.dart';
import '../models/motivation.dart' as model;

typedef MotivationType = model.MotivationType;

class MotivationTypeScreen extends StatefulWidget {
  const MotivationTypeScreen({super.key});

  @override
  State<MotivationTypeScreen> createState() => _MotivationTypeScreenState();
}

class _MotivationTypeScreenState extends State<MotivationTypeScreen> {
  MotivationType? _selectedType;

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
                isSelected: _selectedType == MotivationType.emotional,
                onTap: () => setState(() => _selectedType = MotivationType.emotional),
                titleLines: const [
                  '감성 자극형',
                  '“지금 멈추면 당신은 분명 달라질 수 있어요.”',
                ],
              ),
              const SizedBox(height: 16),
              _TypeTile(
                isSelected: _selectedType == MotivationType.futureVision,
                onTap: () => setState(() => _selectedType = MotivationType.futureVision),
                titleLines: const [
                  '미래/비전 제시형',
                  '“쇼츠를 끄는 지금, 미래의 당신이 웃고 있을 거예요.”',
                ],
              ),
              const SizedBox(height: 16),
              _TypeTile(
                isSelected: _selectedType == MotivationType.action,
                onTap: () => setState(() => _selectedType = MotivationType.action),
                titleLines: const [
                  '구체적 행동 제시형',
                  '“지금 당장 쇼츠 끄고 책상에 앉아보세요.”',
                ],
              ),
              const SizedBox(height: 16),
              _TypeTile(
                isSelected: _selectedType == MotivationType.competition,
                onTap: () => setState(() => _selectedType = MotivationType.competition),
                titleLines: const [
                  '비교/경쟁 자극형',
                  '“당신이 쇼츠 보는 동안, 누군가는 이미 한 단계 올라갔어요.”',
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
              onPressed: _selectedType == null
                  ? null
                  : () {
                      UserSession.motivationType = _selectedType;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const GoalsScreen()),
                        (route) => false,
                      );
                    },
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
      case MotivationType.emotional:
        return '감성 자극형';
      case MotivationType.futureVision:
        return '미래/비전 제시형';
      case MotivationType.action:
        return '구체적 행동 제시형';
      case MotivationType.competition:
        return '비교/경쟁 자극형';
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


