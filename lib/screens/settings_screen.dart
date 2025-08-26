import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'signup_step1_screen.dart';
import 'harmful_apps_screen.dart';
import 'app_usage_sync_screen.dart';
import 'self_development_time_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../utils/slide_page_route.dart';
import 'calendar_screen.dart';
import 'goals_screen.dart';
import 'notification_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: Text(
          '설정',
          style: GoogleFonts.inter(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF504A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SettingsTile(
            icon: Icons.person_outline,
            title: '개인설정',
            onTap: () => Navigator.of(context).push(SlidePageRoute(page: const ProfileSettingsScreen())),
          ),
          _Divider(),
          _SettingsTile(
            icon: Icons.notifications_active_outlined,
            title: '알림 목록',
            onTap: () => Navigator.of(context).push(SlidePageRoute(page: const NotificationScreen())),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: '알림 설정',
            onTap: () => Navigator.of(context).push(SlidePageRoute(page: const NotificationSettingsScreen())),
          ),
          _SettingsTile(
            icon: Icons.block,
            title: '유해앱 설정',
            onTap: () => Navigator.of(context).push(SlidePageRoute(page: const HarmfulAppsScreen())),
          ),
          _SettingsTile(
            icon: Icons.analytics,
            title: '앱 사용량 동기화',
            onTap: () => Navigator.of(context).push(SlidePageRoute(page: const AppUsageSyncScreen())),
          ),
          _SettingsTile(
            icon: Icons.schedule,
            title: '자기개발시간 설정',
            onTap: () => Navigator.of(context).push(SlidePageRoute(page: const SelfDevelopmentTimeScreen())),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF504A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('로그아웃', style: TextStyle(color: Colors.white)),
                      content: const Text('정말 로그아웃하시겠어요?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('로그아웃'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SignupStep1Screen()),
                      (route) => false,
                    );
                  }
                },
                child: Text(
                  '로그아웃',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const GoalsScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
              (route) => false,
            );
          }
          if (i == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const CalendarScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 16));
  }
}


