import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/slide_page_route.dart';
import 'goals_screen.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  final List<PermissionStatus> _permissionStatuses = [];
  final List<String> _permissionNames = [
    '알림',
    '위치',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 기존 권한 상태 리스트 초기화
      _permissionStatuses.clear();
      
      // 필요한 권한들의 현재 상태 확인 (카메라, 마이크, 저장소 제거)
      final permissions = [
        Permission.notification,
        Permission.location,
      ];

      print('권한 상태 확인 시작...');
      
      for (int i = 0; i < permissions.length; i++) {
        final permission = permissions[i];
        final status = await permission.status;
        _permissionStatuses.add(status);
        
        print('${_permissionNames[i]} 권한 상태: $status');
      }

      print('전체 권한 상태: $_permissionStatuses');
      print('모든 권한 허용됨: $_allPermissionsGranted');

      // 모든 권한이 이미 허용된 경우 메인 화면으로 바로 이동
      if (_allPermissionsGranted) {
        print('모든 권한이 허용되어 메인 화면으로 이동합니다.');
        // 권한 상태 저장
        await _savePermissionStatus();
        // 약간의 지연을 두어 로딩 상태를 보여줌
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _proceedToApp();
        }
      } else {
        print('일부 권한이 거부되었습니다. 사용자가 권한을 허용해야 합니다.');
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
        default:
          return;
      }

      print('${_permissionNames[index]} 권한 요청 시작...');
      
      final status = await permission.request();
      setState(() {
        _permissionStatuses[index] = status;
      });

      print('${_permissionNames[index]} 권한 요청 결과: $status');

      // 권한이 거부된 경우 설정으로 이동 안내
      if (status.isDenied || status.isPermanentlyDenied) {
        print('${_permissionNames[index]} 권한이 거부되었습니다. 다이얼로그를 표시합니다.');
        if (mounted) {
          _showPermissionDeniedDialog(index);
        }
      }

      // 모든 권한이 허용된 경우 상태 저장 및 메인 화면으로 이동
      if (_allPermissionsGranted) {
        print('모든 권한이 허용되어 메인 화면으로 이동합니다.');
        await _savePermissionStatus();
        if (mounted) {
          _proceedToApp();
        }
      } else {
        print('아직 일부 권한이 거부되었습니다. 현재 권한 상태: $_permissionStatuses');
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$permissionName 권한 필요',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '$permissionName 권한이 거부되었습니다. 앱의 정상적인 작동을 위해 설정에서 권한을 허용해주세요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white60,
            ),
            child: Text(
              '취소',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFFFF6B6B).withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              '설정으로 이동',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _allPermissionsGranted {
    if (_permissionStatuses.isEmpty) {
      print('권한 상태 리스트가 비어있습니다.');
      return false;
    }
    
    final allGranted = _permissionStatuses.every((status) => 
        status.isGranted || status.isLimited);
    
    print('권한 상태 체크: $_permissionStatuses');
    print('모든 권한 허용 여부: $allGranted');
    
    return allGranted;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // 헤더 섹션 (로그인 화면과 비슷한 스타일)
              Column(
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
                            colors: [Color(0xFFFF6B6B), Color(0xFFFF6B6B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Digital Minimalism',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '권한 설정',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '앱의 정상적인 작동을 위해\n필요한 권한을 허용해주세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 앱 사용량 접근 권한 안내
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info,
                            color: Color(0xFFFF6B6B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '앱 사용량 접근 권한',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '앱 사용량(스크린타임) 데이터 수집을 위해 시스템 설정에서 "사용 통계 액세스" 권한을 허용해야 합니다. 앱 시작 후 설정에서 수동으로 허용해주세요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // 시스템 설정으로 이동
                          openAppSettings();
                        },
                        icon: const Icon(Icons.settings, color: Color(0xFFFF6B6B)),
                        label: Text(
                          '권한 설정으로 이동',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFFF6B6B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6B6B),
                          side: BorderSide(color: const Color(0xFFFF6B6B).withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 권한 목록
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFFF6B6B),
                          strokeWidth: 2.5,
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
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: _getStatusIcon(status),
                              title: Text(
                                permissionName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _getStatusText(status),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: (status.isDenied || status.isPermanentlyDenied)
                                  ? ElevatedButton(
                                      onPressed: () => _requestPermission(index),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFF6B6B),
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: const Color(0xFFFF6B6B).withOpacity(0.3),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        '권한 요청',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
                height: 56,
                child: ElevatedButton(
                  onPressed: _allPermissionsGranted ? _proceedToApp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _allPermissionsGranted 
                        ? const Color(0xFFFF6B6B) 
                        : Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    elevation: _allPermissionsGranted ? 4 : 0,
                    shadowColor: _allPermissionsGranted 
                        ? const Color(0xFFFF6B6B).withOpacity(0.3) 
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _allPermissionsGranted ? '앱 시작하기' : '필요한 권한을 허용해주세요',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white60,
                ),
                child: Text(
                  '나중에 설정하기',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
