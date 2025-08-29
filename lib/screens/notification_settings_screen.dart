import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../utils/slide_page_route.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _serviceNotification = true;
  bool _nightPush = false;
  bool _calendarNotification = true;
  bool _isLoading = false;
  bool _isSaving = false;
  MemberDetail? _memberDetail;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  // 알림 설정 로드
  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final memberDetail = await ApiService.getMemberDetail();
      if (memberDetail != null) {
        setState(() {
          _memberDetail = memberDetail;
          _serviceNotification = memberDetail.useNotification;
          // 백엔드에서 추가 알림 설정을 받아올 수 있도록 확장 가능
        });
      }
    } catch (e) {
      print('알림 설정 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 설정을 불러오는데 실패했습니다: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 알림 설정 저장
  Future<void> _saveNotificationSettings() async {
    if (_memberDetail == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 수정된 정보로 MemberDetail 객체 업데이트
      final updatedMember = MemberDetail(
        id: _memberDetail!.id,
        name: _memberDetail!.name,
        nickname: _memberDetail!.nickname,
        job: _memberDetail!.job,
        phone: _memberDetail!.phone,
        email: _memberDetail!.email,
        password: _memberDetail!.password,
        motivationType: _memberDetail!.motivationType,
        gender: _memberDetail!.gender,
        birthday: _memberDetail!.birthday,
        averagePreparationTime: _memberDetail!.averagePreparationTime,
        distractionAppList: _memberDetail!.distractionAppList,
        location: _memberDetail!.location,
        useNotification: _serviceNotification, // 알림 설정 업데이트
        state: _memberDetail!.state,
        role: _memberDetail!.role,
        profileImageUrl: _memberDetail!.profileImageUrl,
        createdAt: _memberDetail!.createdAt,
      );

      final success = await ApiService.updateMemberDetail(updatedMember);
      
      if (success) {
        setState(() {
          _memberDetail = updatedMember;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 설정이 저장되었습니다.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 설정 저장에 실패했습니다. 다시 시도해주세요.')),
          );
        }
      }
    } catch (e) {
      print('알림 설정 저장 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 설정 저장 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 알림 설정 변경 처리
  void _onNotificationChanged(bool value, String settingType) {
    setState(() {
      switch (settingType) {
        case 'service':
          _serviceNotification = value;
          if (!value) {
            _nightPush = false;
            _calendarNotification = false;
          }
          break;
        case 'night':
          _nightPush = value;
          break;
        case 'calendar':
          _calendarNotification = value;
          break;
      }
    });
    
    // 설정 변경 시 자동 저장
    _saveNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('알림 설정', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFFF504A))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF504A),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF504A),
              ),
            )
          : ListView(
              children: [
                _SwitchTile(
                  title: '서비스 알림',
                  subtitle: '앱 서비스 관련 주요 소식을 받아요',
                  value: _serviceNotification,
                  onChanged: (v) => _onNotificationChanged(v, 'service'),
                ),
                const _Divider(),
                _SwitchTile(
                  title: '야간 푸시 알림',
                  subtitle: '야간 시간대에도 푸시 알림을 받아요',
                  value: _serviceNotification ? _nightPush : false,
                  onChanged: _serviceNotification ? (v) => _onNotificationChanged(v, 'night') : null,
                ),
                const _Divider(),
                _SwitchTile(
                  title: '캘린더 알림',
                  subtitle: '일정 및 목표가 캘린더에 반영될 때 알려줘요',
                  value: _serviceNotification ? _calendarNotification : false,
                  onChanged: _serviceNotification ? (v) => _onNotificationChanged(v, 'calendar') : null,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '설정 변경 시 자동으로 저장됩니다.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
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

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
      activeColor: const Color(0xFFFF504A),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 16));
  }
}


