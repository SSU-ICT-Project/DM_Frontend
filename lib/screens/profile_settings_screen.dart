// lib/screens/profile_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../models/user_model.dart';
import '../models/motivation.dart';
import '../services/api_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController(); // <-- 컨트롤러 추가

  MotivationType _motivationType = MotivationType.emotional;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final userInfo = await ApiService.getMemberInfo();
    if (userInfo != null && mounted) {
      setState(() {
        _nicknameController.text = userInfo.nickname;
        _jobController.text = userInfo.job;
        if (userInfo.birthday != null) {
          _birthYearController.text = userInfo.birthday!.split('-').first;
        }
        _prepTimeController.text = userInfo.prepTime ?? ''; // <-- 데이터 로드
        _motivationType = userInfo.motivationType;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserData() async {
    final updatedInfo = MemberForm(
      nickname: _nicknameController.text.trim(),
      job: _jobController.text.trim(),
      birthday: '${_birthYearController.text.trim()}-01-01',
      motivationType: _motivationType,
      prepTime: _prepTimeController.text.trim(), // <-- 데이터 저장
    );

    final success = await ApiService.updateMember(updatedInfo);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다.')));
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _jobController.dispose();
    _birthYearController.dispose();
    _prepTimeController.dispose(); // <-- dispose 추가
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('개인설정', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFFF504A))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LabeledField(label: '닉네임', controller: _nicknameController, hint: '닉네임을 입력하세요'),
            const SizedBox(height: 16),
            _LabeledField(label: '직업', controller: _jobController, hint: '직업을 입력하세요'),
            const SizedBox(height: 16),
            _LabeledField(label: '생년', controller: _birthYearController, hint: 'YYYY'),
            const SizedBox(height: 16),
            // <-- UI에 필드 추가
            _LabeledField(label: '평균 외출 준비 시간', controller: _prepTimeController, hint: '예: 30분, 1시간'),
            const SizedBox(height: 24),
            Text('동기부여 타입', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            _MotivationTypeChooser(
              value: _motivationType,
              onChanged: (v) => setState(() => _motivationType = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF504A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveUserData,
                child: Text('저장', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _SettingsBottomNav(),
    );
  }
}

// ... (_LabeledField, _SettingsBottomNav, _MotivationTypeChooser 위젯은 변경 없음)
class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            decoration: InputDecoration.collapsed(hintText: hint, hintStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: const Color(0xFF717171))),
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black),
          ),
        ),
      ],
    );
  }
}

class _SettingsBottomNav extends StatelessWidget {
  const _SettingsBottomNav();

  @override
  Widget build(BuildContext context) {
    return AppBottomNav(
      currentIndex: 2,
      onTap: (i) {
        if (i == 2) return; // already on settings section
        if (i == 0) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }
}

class _MotivationTypeChooser extends StatelessWidget {
  final MotivationType value;
  final ValueChanged<MotivationType> onChanged;
  const _MotivationTypeChooser({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in MotivationType.values)
          RadioListTile<MotivationType>(
            value: t,
            groupValue: value,
            onChanged: (v) => v != null ? onChanged(v) : null,
            title: Text(
              motivationTypeLabel(t),
              style: GoogleFonts.inter(color: Colors.white),
            ),
            activeColor: const Color(0xFFFF504A),
          ),
      ],
    );
  }
}