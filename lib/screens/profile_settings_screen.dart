import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../utils/slide_page_route.dart';
import '../models/user_model.dart';
import '../models/motivation.dart';
import '../services/api_service.dart';
import '../widgets/location_search_widget.dart';
import '../services/location_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _birthYearController = TextEditingController();
  final TextEditingController _birthMonthController = TextEditingController();
  final TextEditingController _birthDayController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();

  MemberDetail? _memberDetail;
  bool _isLoading = true;
  bool _isSaving = false;
  PlaceInfo? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadMemberDetail();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _jobController.dispose();
    _birthYearController.dispose();
    _birthMonthController.dispose();
    _birthDayController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  // 회원 상세 정보 로드
  Future<void> _loadMemberDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 회원 정보 로드 시작');
      final memberDetail = await ApiService.getMemberDetail();
      print('🔍 API 응답 결과: $memberDetail');
      
      if (memberDetail != null) {
        print('✅ 회원 정보 로드 성공');
        setState(() {
          _memberDetail = memberDetail;
          _nicknameController.text = memberDetail.nickname;
          _jobController.text = memberDetail.job;
          
          // 생년월일 파싱
          print('🔍 생년월일 파싱 시작: "${memberDetail.birthday}"');
          final birthdayParts = memberDetail.birthday.split('-');
          print('🔍 생년월일 파싱 결과: $birthdayParts');
          
          if (birthdayParts.length >= 3) {
            _birthYearController.text = birthdayParts[0];
            _birthMonthController.text = birthdayParts[1];
            _birthDayController.text = birthdayParts[2];
            print('✅ 생년월일 설정 완료: ${birthdayParts[0]}-${birthdayParts[1]}-${birthdayParts[2]}');
          } else {
            print('⚠️ 생년월일 형식이 올바르지 않음: ${memberDetail.birthday}');
          }
          
          // 평균 외출 준비 시간 디버그 로그
          print('🔍 백엔드에서 받은 averagePreparationTime: "${memberDetail.averagePreparationTime}"');
          print('🔍 averagePreparationTime 타입: ${memberDetail.averagePreparationTime.runtimeType}');
          print('🔍 averagePreparationTime 길이: ${memberDetail.averagePreparationTime.length}');
          
          // 평균 외출 준비 시간이 null이거나 빈 값일 때 기본값 설정
          String prepTime = memberDetail.averagePreparationTime;
          if (prepTime.isEmpty || prepTime == 'null') {
            prepTime = '00:30:00'; // 기본값: 30분
            print('⚠️ averagePreparationTime이 비어있어 기본값 "00:30:00" 설정');
          }
          
          final formattedTime = _formatPreparationTime(prepTime);
          _prepTimeController.text = formattedTime;
          print('✅ 평균 외출 준비 시간 설정 완료: "$formattedTime" (원본: "$prepTime")');
          
          // 위치 정보 설정
          print('🔍 위치 정보 확인: ${memberDetail.location}');
          if (memberDetail.location != null) {
            _selectedLocation = PlaceInfo(
              id: 'saved_location',
              name: memberDetail.location!.placeName,
              address: memberDetail.location!.placeAddress,
              latitude: double.tryParse(memberDetail.location!.latitude),
              longitude: double.tryParse(memberDetail.location!.longitude),
            );
            print('✅ 위치 정보 설정 완료: ${_selectedLocation!.name}');
          } else {
            print('⚠️ 저장된 위치 정보가 없음');
          }
        });
      } else {
        print('❌ 회원 정보가 null입니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 정보를 불러올 수 없습니다.')),
        );
      }
    } catch (e, stackTrace) {
      print('❌ 회원 정보 로드 중 오류 발생: $e');
      print('❌ 스택 트레이스: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원 정보를 불러오는데 실패했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🔄 회원 정보 로드 완료');
    }
  }

  // 준비 시간을 사용자 친화적인 형식으로 변환
  String _formatPreparationTime(String timeString) {
    print('🔄 _formatPreparationTime 호출됨: "$timeString"');
    
    if (timeString.isEmpty || timeString == 'null') {
      print('⚠️ timeString이 비어있거나 null임');
      return '30분'; // 기본값 반환
    }
    
    try {
      final parts = timeString.split(':');
      print('🔍 시간 파싱 결과: $parts (길이: ${parts.length})');
      
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        print('🔍 파싱된 시간: ${hours}시간 ${minutes}분');
        
        if (hours > 0 && minutes > 0) {
          return '${hours}시간 ${minutes}분';
        } else if (hours > 0) {
          return '${hours}시간';
        } else if (minutes > 0) {
          return '${minutes}분';
        }
      }
    } catch (e) {
      print('❌ 시간 파싱 오류: $e');
    }
    
    print('⚠️ 기본값 반환: "30분"');
    return '30분'; // 파싱 실패 시 기본값
  }

  // 준비 시간을 HH:MM:SS 형식으로 변환
  String _parsePreparationTime(String userInput) {
    print('🔄 _parsePreparationTime 호출됨: "$userInput"');
    
    if (userInput.isEmpty) {
      print('⚠️ userInput이 비어있음, 기본값 "00:30:00" 반환');
      return '00:30:00'; // 기본값: 30분
    }
    
    try {
      // "30분", "1시간", "1시간 30분" 등의 형식 파싱
      int hours = 0;
      int minutes = 0;
      
      if (userInput.contains('시간')) {
        final hourPart = userInput.split('시간')[0];
        hours = int.tryParse(hourPart.trim()) ?? 0;
        print('🔍 파싱된 시간: ${hours}시간');
        
        if (userInput.contains('분')) {
          final minutePart = userInput.split('시간')[1].split('분')[0];
          minutes = int.tryParse(minutePart.trim()) ?? 0;
          print('🔍 파싱된 분: ${minutes}분');
        }
      } else if (userInput.contains('분')) {
        final minutePart = userInput.split('분')[0];
        minutes = int.tryParse(minutePart.trim()) ?? 0;
        print('🔍 파싱된 분: ${minutes}분');
      }
      
      // 최소값 보장
      if (hours == 0 && minutes == 0) {
        minutes = 30; // 기본값: 30분
        print('⚠️ 시간과 분이 모두 0이어서 기본값 30분 설정');
      }
      
      final result = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
      print('✅ 변환 결과: "$result"');
      return result;
    } catch (e) {
      print('❌ 시간 파싱 오류: $e, 기본값 "00:30:00" 반환');
      return '00:30:00'; // 파싱 실패 시 기본값
    }
  }

  // 위치 선택 처리
  void _onLocationSelected(PlaceInfo place) {
    print('📍 위치 선택됨: ${place.name} (${place.address})');
    setState(() {
      _selectedLocation = place;
    });
  }

  // 저장 버튼 클릭 처리
  Future<void> _saveProfile() async {
    if (_memberDetail == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 생년월일 조합
      final birthday = '${_birthYearController.text.trim()}-${_birthMonthController.text.trim()}-${_birthDayController.text.trim()}';
      print('🔍 조합된 생년월일: "$birthday"');
      
      // 위치 정보 변환 (한 번만 호출)
      LocationInfo? locationInfo;
      if (_selectedLocation != null) {
        locationInfo = _selectedLocation!.toLocationInfo();
        print('🔍 변환된 위치 정보: ${locationInfo.toJson()}');
      }
      
      // 수정된 정보로 MemberDetail 객체 업데이트 (백엔드 코드에 맞춤)
      final updatedMember = MemberDetail(
        id: _memberDetail!.id,
        name: _memberDetail!.name.isNotEmpty ? _memberDetail!.name : '', // 빈 문자열 허용
        nickname: _nicknameController.text.trim(),
        job: _jobController.text.trim(),
        phone: _memberDetail!.phone.isNotEmpty ? _memberDetail!.phone : '', // 빈 문자열 허용
        email: _memberDetail!.email,
        password: _memberDetail!.password.isNotEmpty ? _memberDetail!.password : '', // 빈 문자열 허용
        motivationType: UserSession.motivationType != null 
            ? MemberDetail.motivationTypeToString(UserSession.motivationType!)
            : _memberDetail!.motivationType,
        gender: _memberDetail!.gender.isNotEmpty ? _memberDetail!.gender : '', // 빈 문자열 허용
        birthday: birthday,
        averagePreparationTime: _parsePreparationTime(_prepTimeController.text.trim()),
        distractionAppList: _memberDetail!.distractionAppList,
        location: locationInfo,
        useNotification: _memberDetail!.useNotification,
        state: _memberDetail!.state.isNotEmpty ? _memberDetail!.state : '', // 빈 문자열 허용
        role: _memberDetail!.role.isNotEmpty ? _memberDetail!.role : '', // 빈 문자열 허용
        profileImageUrl: _memberDetail!.profileImageUrl,
        createdAt: _memberDetail!.createdAt,
      );

      print('🔍 업데이트할 회원 정보:');
      print('   📝 닉네임: ${updatedMember.nickname}');
      print('   💼 직업: ${updatedMember.job}');
      print('   📅 생년월일: ${updatedMember.birthday}');
      print('   ⏰ 평균 외출 준비 시간: ${updatedMember.averagePreparationTime}');
      print('   🗺️ 위치: ${locationInfo?.toJson()}');
      print('   🎯 동기부여 타입: ${updatedMember.motivationType}');
      print('   🔔 알림 사용: ${updatedMember.useNotification}');

      final requestJson = updatedMember.toUpdateJson();
      print('🔍 전송할 JSON 구조:');
      print('   📋 Request Body: $requestJson');
      print('   🔍 새로운 백엔드 API: JSON 형식으로 전송');

      final success = await ApiService.updateMemberDetail(updatedMember);
      
      if (success) {
        setState(() {
          _memberDetail = updatedMember;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 성공적으로 저장되었습니다.')),
        );
        
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 저장에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('프로필 저장 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 저장 중 오류가 발생했습니다.')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF504A),
              ),
            )
          : _memberDetail == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '회원 정보를 불러올 수 없습니다.',
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMemberDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF504A),
                        ),
                        child: Text(
                          '다시 시도',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledField(
                        label: '닉네임',
                        controller: _nicknameController,
                        hint: '닉네임을 입력하세요',
                      ),
                      const SizedBox(height: 16),
                      _LabeledField(
                        label: '직업',
                        controller: _jobController,
                        hint: '직업을 입력하세요',
                      ),
                      const SizedBox(height: 16),
                      
                      // 생년월일 입력 (수정 가능)
                      Text('생년월일', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledField(
                              label: '',
                              controller: _birthYearController,
                              hint: 'YYYY',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LabeledField(
                              label: '',
                              controller: _birthMonthController,
                              hint: 'MM',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LabeledField(
                              label: '',
                              controller: _birthDayController,
                              hint: 'DD',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _LabeledField(
                        label: '평균 외출 준비 시간',
                        controller: _prepTimeController,
                        hint: '예: 30분, 1시간',
                      ),
                      const SizedBox(height: 24),
                      
                      // 출발지 설정
                      Text('출발지', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 8),
                      LocationSearchWidget(
                        onLocationSelected: _onLocationSelected,
                        initialLocation: _selectedLocation != null 
                            ? '${_selectedLocation!.name} (${_selectedLocation!.address})'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        '동기부여 타입',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      _MotivationTypeChooser(
                        value: UserSession.motivationType ?? _memberDetail!.motivationTypeEnum,
                        onChanged: (v) {
                          setState(() {
                            UserSession.motivationType = v;
                          });
                        },
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
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  '저장',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: const _SettingsBottomNav(),
    );
  }
}

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
        if (label.isNotEmpty) ...[
          Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w300, color: const Color(0xFF717171)),
            ),
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


