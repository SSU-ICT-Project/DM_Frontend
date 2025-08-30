import 'package:flutter/material.dart';
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
          SnackBar(
            content: Text(
              '알림 설정을 불러오는데 실패했습니다: $e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
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
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '알림 설정이 저장되었습니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFFF6B6B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '알림 설정 저장에 실패했습니다. 다시 시도해주세요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFFFF6B6B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      print('알림 설정 저장 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '알림 설정 저장 중 오류가 발생했습니다: $e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          '알림 설정',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFFFF6B6B),
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSaving)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF6B6B),
                  strokeWidth: 2.5,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFFFF6B6B),
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '알림 설정을 불러오는 중...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _NotificationSection(
                  title: '기본 알림',
                  children: [
                    _SwitchTile(
                      title: '서비스 알림',
                      subtitle: '앱 서비스 관련 주요 소식을 받아요',
                      icon: Icons.notifications_active_outlined,
                      value: _serviceNotification,
                      onChanged: (v) => _onNotificationChanged(v, 'service'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _NotificationSection(
                  title: '세부 설정',
                  children: [
                    _SwitchTile(
                      title: '야간 푸시 알림',
                      subtitle: '야간 시간대에도 푸시 알림을 받아요',
                      icon: Icons.nightlight_outlined,
                      value: _serviceNotification ? _nightPush : false,
                      onChanged: _serviceNotification ? (v) => _onNotificationChanged(v, 'night') : null,
                      isDisabled: !_serviceNotification,
                    ),
                    const SizedBox(height: 16),
                    _SwitchTile(
                      title: '캘린더 알림',
                      subtitle: '일정 및 목표가 캘린더에 반영될 때 알려줘요',
                      icon: Icons.calendar_today_outlined,
                      value: _serviceNotification ? _calendarNotification : false,
                      onChanged: _serviceNotification ? (v) => _onNotificationChanged(v, 'calendar') : null,
                      isDisabled: !_serviceNotification,
                    ),
                  ],
                ),

              ],
            ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _NotificationSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDisabled;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDisabled 
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFFF6B6B).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDisabled 
              ? Colors.white.withOpacity(0.3)
              : const Color(0xFFFF6B6B),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDisabled ? Colors.white.withOpacity(0.3) : Colors.white60,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: isDisabled ? null : onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFFFF6B6B),
        inactiveThumbColor: Colors.white.withOpacity(0.5),
        inactiveTrackColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}


