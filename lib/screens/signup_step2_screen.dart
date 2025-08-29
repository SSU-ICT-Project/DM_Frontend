// lib/screens/signup_step2_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'motivation_type_screen.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../widgets/location_search_widget.dart';
import '../services/location_service.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen>
    with TickerProviderStateMixin {
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
  LocationInfo? _selectedLocation; // 출발지 주소

  // 애니메이션 컨트롤러들
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _jobController.dispose();
    _prepTimeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // 평균 외출 준비 시간을 백엔드 형식(HH:MM:SS)으로 변환
  String? _convertPrepTimeToBackendFormat(String prepTime) {
    if (prepTime.trim().isEmpty) return null;
    
    final timeText = prepTime.trim().toLowerCase();
    
    // "30", "30분", "1시간", "1시간 30분" 등의 형식 파싱
    int totalMinutes = 0;
    
    // 숫자만 입력된 경우 (예: "30" → 30분으로 처리)
    if (RegExp(r'^\d+$').hasMatch(timeText)) {
      totalMinutes = int.parse(timeText);
    } else {
      // "30분", "1시간", "1시간 30분" 등의 형식 파싱
      if (timeText.contains('시간')) {
        final hourMatch = RegExp(r'(\d+)시간').firstMatch(timeText);
        if (hourMatch != null) {
          final hours = int.parse(hourMatch.group(1)!);
          totalMinutes += hours * 60;
        }
      }
      
      if (timeText.contains('분')) {
        final minuteMatch = RegExp(r'(\d+)분').firstMatch(timeText);
        if (minuteMatch != null) {
          final minutes = int.parse(minuteMatch.group(1)!);
          totalMinutes += minutes;
        }
      }
    }
    
    if (totalMinutes == 0) return null;
    
    // HH:MM:SS 형식으로 변환
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
  }

  // 출발지 주소 선택 처리
  void _onLocationSelected(PlaceInfo place) {
    setState(() {
      _selectedLocation = place.toLocationInfo();
    });
  }

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

      // 평균 외출 준비 시간을 백엔드 형식으로 변환
      final backendPrepTime = _convertPrepTimeToBackendFormat(_prepTimeController.text);

      // Create a SignUpData object with the collected info
      final signUpData = SignUpData(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nickname: _nicknameController.text.trim(),
        name: _jobController.text.trim(),
        birthday: _selectedBirthday!.toIso8601String().split('T').first,
        gender: _selectedGender!,
        phone: '010-0000-0000', // Still a temporary value
        averagePreparationTime: backendPrepTime,
        location: _selectedLocation,
        useNotification: true, // 기본값은 알림 허용
        distractionAppList: [], // 기본값은 빈 리스트
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더 섹션
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF504A), Color(0xFFFF6B6B)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Digital Minimalism',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: const Color(0xFFFF504A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '회원가입 정보',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '디지털 미니멀리즘을 위한 첫 걸음을 시작해보세요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 폼 섹션
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // 기존 입력 필드들
                        _ModernInputField(
                          label: '이메일',
                          hintText: 'example@email.com',
                          controller: _emailController,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) => (value == null || !value.contains('@')) ? '유효한 이메일을 입력해 주세요.' : null,
                        ),
                        const SizedBox(height: 20),
                        _ModernInputField(
                          label: '비밀번호',
                          hintText: '8자 이상 입력해 주세요',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outlined,
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
                        _ModernInputField(
                          label: '비밀번호 확인',
                          hintText: '비밀번호를 다시 한 번 입력해 주세요',
                          controller: _confirmPasswordController,
                          prefixIcon: Icons.lock_outlined,
                          isObscure: _isConfirmPasswordObscure,
                          onObscureToggle: () => setState(() => _isConfirmPasswordObscure = !_isConfirmPasswordObscure),
                          validator: (value) => (value != _passwordController.text.trim()) ? '비밀번호가 일치하지 않습니다.' : null,
                        ),
                        const SizedBox(height: 20),
                        _ModernInputField(
                          label: '닉네임',
                          hintText: '사용자님을 어떻게 부를까요?',
                          controller: _nicknameController,
                          prefixIcon: Icons.person_outline,
                          validator: (value) => (value == null || value.trim().isEmpty) ? '닉네임을 입력해 주세요.' : null,
                        ),
                        const SizedBox(height: 20),
                        _ModernInputField(
                          label: '직업',
                          hintText: 'AI가 당신의 직업을 고려해 동기부여 해줍니다!',
                          controller: _jobController,
                          prefixIcon: Icons.work_outline,
                          validator: (value) => (value == null || value.trim().isEmpty) ? '직업을 입력해 주세요.' : null,
                        ),
                        const SizedBox(height: 20),

                        // 성별 선택
                        Text(
                          '성별',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ModernGenderSelection(
                          selectedGender: _selectedGender,
                          onChanged: (gender) => setState(() => _selectedGender = gender),
                        ),
                        const SizedBox(height: 20),

                        // 생년월일 선택
                        Text(
                          '생년월일',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ModernBirthdayPicker(
                          selectedBirthday: _selectedBirthday,
                          onChanged: (date) => setState(() => _selectedBirthday = date),
                        ),
                        const SizedBox(height: 20),

                        _ModernInputField(
                          label: '평균 외출 준비 시간',
                          hintText: '예: 30분, 1시간 (선택 사항)',
                          controller: _prepTimeController,
                          prefixIcon: Icons.access_time,
                          validator: null,
                        ),
                        const SizedBox(height: 20),

                        // 출발지 주소 입력
                        Text(
                          '출발지 주소',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedLocation != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: const Color(0xFFFF504A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedLocation!.placeName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            _selectedLocation!.placeAddress,
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white60),
                                      onPressed: () {
                                        setState(() {
                                          _selectedLocation = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ] else ...[
                                LocationSearchWidget(
                                  onLocationSelected: _onLocationSelected,
                                  initialLocation: null,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _callSignUpApi,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '다음',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 현대적인 입력 필드 위젯
class _ModernInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isObscure;
  final VoidCallback? onObscureToggle;
  final IconData prefixIcon;

  const _ModernInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.isObscure = false,
    this.onObscureToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isObscure,
            validator: validator,
            style: const TextStyle(color: Colors.white), // 입력 텍스트 색상
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Colors.white54, // 힌트 텍스트 색상을 더 명확하게
                fontSize: 14,
              ),
              prefixIcon: Icon(prefixIcon, color: Colors.white60),
              suffixIcon: onObscureToggle != null
                  ? IconButton(
                      icon: Icon(
                        isObscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white60,
                      ),
                      onPressed: onObscureToggle,
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF1A1A1A), // 입력 필드 배경색
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white24, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white24, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: const Color(0xFFFF504A), width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 현대적인 성별 선택 위젯
class _ModernGenderSelection extends StatelessWidget {
  final String? selectedGender;
  final ValueChanged<String> onChanged;

  const _ModernGenderSelection({
    required this.selectedGender,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModernGenderButton(
            label: '남성',
            gender: 'MALE',
            isSelected: selectedGender == 'MALE',
            onTap: onChanged,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ModernGenderButton(
            label: '여성',
            gender: 'FEMALE',
            isSelected: selectedGender == 'FEMALE',
            onTap: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ModernGenderButton extends StatelessWidget {
  final String label;
  final String gender;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _ModernGenderButton({
    required this.label,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFFF504A).withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFF504A)
                : Colors.white24,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isSelected ? const Color(0xFFFF504A) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// 현대적인 생년월일 선택 위젯
class _ModernBirthdayPicker extends StatelessWidget {
  final DateTime? selectedBirthday;
  final ValueChanged<DateTime> onChanged;

  const _ModernBirthdayPicker({
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
                  surface: Color(0xFF1A1A1A),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF0A0A0A),
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
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: selectedBirthday != null 
                  ? const Color(0xFFFF504A)
                  : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              selectedBirthday != null 
                  ? selectedBirthday!.toIso8601String().split('T').first
                  : '생년월일을 선택해 주세요',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: selectedBirthday != null ? Colors.white : Colors.white60,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white60,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}