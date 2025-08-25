// lib/screens/signup_step2_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'motivation_type_screen.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  // New state variables for gender and birthday
  String? _selectedGender;
  DateTime? _selectedBirthday;

  Future<void> _callSignUpApi() async {
    // The previous logic to directly call the signup API is now split.
    // This button will now navigate to the next screen, passing the collected data.
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성별을 선택해 주세요.')),
        );
        return;
      }
      if (_selectedBirthday == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('생년월일을 선택해 주세요.')),
        );
        return;
      }

      // Create a SignUpData object with the collected info
      final signUpData = SignUpData(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nickname: _nicknameController.text.trim(),
        job: _jobController.text.trim(),
        birthday: _selectedBirthday!.toIso8601String().split('T').first,
        gender: _selectedGender!,
        phone: '010-0000-0000', // Still a temporary value
      );

      // Navigate to the MotivationTypeScreen, passing the data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MotivationTypeScreen(signUpData: signUpData),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _jobController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
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
                  '회원가입 정보',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.21,
                  ),
                ),
                const SizedBox(height: 24),

                // Existing input fields
                _GrayLabeledInput(
                  label: '이메일',
                  hintText: '이메일(ID)를 입력해 주세요.',
                  controller: _emailController,
                  validator: (value) => (value == null || !value.contains('@')) ? '유효한 이메일을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                _GrayLabeledInput(
                  label: '비밀번호',
                  hintText: '비밀번호를 입력해 주세요.',
                  controller: _passwordController,
                  isObscure: _isPasswordObscure,
                  onObscureToggle: () => setState(() => _isPasswordObscure = !_isPasswordObscure),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return '비밀번호를 입력해 주세요.';
                    if (text.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _GrayLabeledInput(
                  label: '비밀번호 확인',
                  hintText: '비밀번호를 다시 한 번 입력해 주세요.',
                  controller: _confirmPasswordController,
                  isObscure: _isConfirmPasswordObscure,
                  onObscureToggle: () => setState(() => _isConfirmPasswordObscure = !_isConfirmPasswordObscure),
                  validator: (value) => (value != _passwordController.text.trim()) ? '비밀번호가 일치하지 않습니다.' : null,
                ),
                const SizedBox(height: 20),
                _GrayLabeledInput(
                  label: '닉네임',
                  hintText: '사용자님을 어떻게 부를까요?',
                  controller: _nicknameController,
                  validator: (value) => (value == null || value.trim().isEmpty) ? '닉네임을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),
                _GrayLabeledInput(
                  label: '직업',
                  hintText: 'AI가 당신의 직업을 고려해 동기부여 해줍니다!',
                  controller: _jobController,
                  validator: (value) => (value == null || value.trim().isEmpty) ? '직업을 입력해 주세요.' : null,
                ),
                const SizedBox(height: 20),

                // New fields for Gender and Birthday
                Text(
                  '성별',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, height: 1.21),
                ),
                const SizedBox(height: 6),
                _GenderSelectionWidget(
                  selectedGender: _selectedGender,
                  onChanged: (gender) => setState(() => _selectedGender = gender),
                ),
                const SizedBox(height: 20),
                Text(
                  '생년월일',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, height: 1.21),
                ),
                const SizedBox(height: 6),
                _BirthdayPicker(
                  selectedBirthday: _selectedBirthday,
                  onChanged: (date) => setState(() => _selectedBirthday = date),
                ),
                const SizedBox(height: 20),

                _GrayLabeledInput(
                  label: '평균 외출 준비 시간',
                  hintText: '예: 30분, 1시간 (선택 사항)',
                  controller: _prepTimeController,
                  validator: null,
                ),
                const SizedBox(height: 32),
              ],
            ),
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
              onPressed: _callSignUpApi,
              child: Text(
                '다음', // Text changed to "Next"
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

// Reusable widgets
class _GrayLabeledInput extends StatelessWidget {
  // ... (original code)
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isObscure;
  final VoidCallback? onObscureToggle;

  const _GrayLabeledInput({
    required this.label,
    required this.hintText,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.isObscure = false,
    this.onObscureToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.21,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isObscure,
            validator: validator,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF717171),
                height: 1.21,
              ),
              suffixIcon: onObscureToggle != null
                  ? IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF717171),
                ),
                onPressed: onObscureToggle,
              )
                  : null,
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

// New widgets for Gender and Birthday
class _GenderSelectionWidget extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onChanged;

  const _GenderSelectionWidget({
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GenderButton(
          label: '남성',
          gender: 'MALE',
          isSelected: selectedGender == 'MALE',
          onTap: onChanged,
        ),
        const SizedBox(width: 12),
        _GenderButton(
          label: '여성',
          gender: 'FEMALE',
          isSelected: selectedGender == 'FEMALE',
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _GenderButton extends StatelessWidget {
  final String label;
  final String gender;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _GenderButton({
    required this.label,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: isSelected ? const Color(0xFFFF504A) : Colors.white,
          backgroundColor: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          side: BorderSide(
            color: isSelected ? const Color(0xFFFF504A) : Colors.white,
            width: isSelected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => onTap(gender),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BirthdayPicker extends StatelessWidget {
  final DateTime? selectedBirthday;
  final ValueChanged<DateTime> onChanged;

  const _BirthdayPicker({
    required this.selectedBirthday,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedBirthday ?? now,
          firstDate: DateTime(1900),
          lastDate: now,
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFFFF504A),
                  onPrimary: Colors.white,
                  surface: Colors.grey,
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: Colors.black,
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        child: Text(
          selectedBirthday != null ? selectedBirthday!.toIso8601String().split('T').first : '생년월일을 선택해 주세요.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: selectedBirthday != null ? Colors.black : const Color(0xFF717171),
          ),
        ),
      ),
    );
  }
}