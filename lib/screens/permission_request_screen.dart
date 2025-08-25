import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/slide_page_route.dart';
import 'goals_screen.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _isLoading = false;
  final List<PermissionStatus> _permissionStatuses = [];
  final List<String> _permissionNames = [
    '알림',
    '위치',
    '카메라',
    '마이크',
    '저장소',
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 필요한 권한들의 현재 상태 확인
      final permissions = [
        Permission.notification,
        Permission.location,
        Permission.camera,
        Permission.microphone,
        Permission.storage,
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        _permissionStatuses.add(status);
      }

      // 모든 권한이 이미 허용된 경우 메인 화면으로 바로 이동
      if (_allPermissionsGranted) {
        // 권한 상태 저장
        await _savePermissionStatus();
        // 약간의 지연을 두어 로딩 상태를 보여줌
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _proceedToApp();
        }
      }
    } catch (e) {
      print('권한 상태 확인 중 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePermissionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_granted', true);
      await prefs.setString('permissions_granted_date', DateTime.now().toIso8601String());
      print('권한 상태가 저장되었습니다');
    } catch (e) {
      print('권한 상태 저장 중 오류: $e');
    }
  }

  Future<void> _requestPermission(int index) async {
    if (index >= _permissionStatuses.length) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Permission permission;
      switch (index) {
        case 0:
          permission = Permission.notification;
          break;
        case 1:
          permission = Permission.location;
          break;
        case 2:
          permission = Permission.camera;
          break;
        case 3:
          permission = Permission.microphone;
          break;
        case 4:
          permission = Permission.storage;
          break;
        default:
          return;
      }

      final status = await permission.request();
      setState(() {
        _permissionStatuses[index] = status;
      });

      // 권한이 거부된 경우 설정으로 이동 안내
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDeniedDialog(index);
        }
      }

      // 모든 권한이 허용된 경우 상태 저장 및 메인 화면으로 이동
      if (_allPermissionsGranted) {
        await _savePermissionStatus();
        if (mounted) {
          _proceedToApp();
        }
      }
    } catch (e) {
      print('권한 요청 중 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPermissionDeniedDialog(int index) {
    final permissionName = _permissionNames[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          '$permissionName 권한 필요',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          '$permissionName 권한이 거부되었습니다. 앱의 정상적인 작동을 위해 설정에서 권한을 허용해주세요.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  bool get _allPermissionsGranted {
    return _permissionStatuses.every((status) => 
        status.isGranted || status.isLimited);
  }

  void _proceedToApp() {
    Navigator.of(context).pushReplacement(
      SlidePageRoute(page: const GoalsScreen()),
    );
  }

  Color _getStatusColor(PermissionStatus status) {
    if (status.isGranted || status.isLimited) return Colors.green;
    if (status.isDenied) return Colors.orange;
    if (status.isPermanentlyDenied) return Colors.red;
    return Colors.grey;
  }

  Icon _getStatusIcon(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (status.isDenied) {
      return const Icon(Icons.warning, color: Colors.orange);
    }
    if (status.isPermanentlyDenied) {
      return const Icon(Icons.error, color: Colors.red);
    }
    return const Icon(Icons.help, color: Colors.grey);
  }

  String _getStatusText(PermissionStatus status) {
    if (status.isGranted) return '허용됨';
    if (status.isLimited) return '제한적 허용';
    if (status.isDenied) return '거부됨';
    if (status.isPermanentlyDenied) return '영구 거부';
    return '확인 중';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // 앱 로고 및 제목
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF504A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.phone_android,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'DM Frontend',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                '앱의 정상적인 작동을 위해\n필요한 권한을 허용해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 앱 사용량 접근 권한 안내
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF504A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF504A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Color(0xFFFF504A), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '앱 사용량 접근 권한',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF504A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '앱 사용량(스크린타임) 데이터 수집을 위해 시스템 설정에서 "사용 통계 액세스" 권한을 허용해야 합니다. 앱 시작 후 설정에서 수동으로 허용해주세요.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[300],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // 시스템 설정으로 이동
                          openAppSettings();
                        },
                        icon: const Icon(Icons.settings, color: Color(0xFFFF504A)),
                        label: const Text(
                          '권한 설정으로 이동',
                          style: TextStyle(color: Color(0xFFFF504A)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF504A)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 권한 목록
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF504A),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _permissionNames.length,
                        itemBuilder: (context, index) {
                          if (index >= _permissionStatuses.length) {
                            return const SizedBox.shrink();
                          }
                          
                          final status = _permissionStatuses[index];
                          final permissionName = _permissionNames[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.grey[900],
                            child: ListTile(
                              leading: _getStatusIcon(status),
                              title: Text(
                                permissionName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: (status.isDenied || status.isPermanentlyDenied)
                                  ? ElevatedButton(
                                      onPressed: () => _requestPermission(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF504A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text('권한 요청'),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
              
              const SizedBox(height: 24),
              
              // 진행 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allPermissionsGranted ? _proceedToApp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allPermissionsGranted 
                        ? const Color(0xFFFF504A) 
                        : Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _allPermissionsGranted ? '앱 시작하기' : '필요한 권한을 허용해주세요',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 건너뛰기 버튼 (선택사항)
              TextButton(
                onPressed: _proceedToApp,
                child: Text(
                  '나중에 설정하기',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
