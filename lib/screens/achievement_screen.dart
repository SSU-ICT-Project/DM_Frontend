import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../utils/slide_page_route.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 데모용 고정 수치
    final int totalGoals = 12;
    final int completedGoals = 7;
    final double completionRate = totalGoals == 0 ? 0 : completedGoals / totalGoals;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('나의 목표 달성도', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFFF504A))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatCard(
              title: '총 목표 수',
              value: '$totalGoals',
              icon: Icons.flag_outlined,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: '달성한 목표',
              value: '$completedGoals',
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 24),
            Text('달성률', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionRate,
                minHeight: 12,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF504A)),
              ),
            ),
            const SizedBox(height: 8),
            Text('${(completionRate * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(color: Colors.white70)),
            const Spacer(),
            Center(
              child: Text(
                '세부 지표는 추후 분석 데이터와 연동됩니다',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          ),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


