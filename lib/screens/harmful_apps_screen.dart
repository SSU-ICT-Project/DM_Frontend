import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/usage_reporter.dart';
import '../services/api_service.dart';
import '../models/harmful_apps_model.dart';
import '../utils/slide_page_route.dart';
import 'package:google_fonts/google_fonts.dart';

class HarmfulAppsScreen extends StatefulWidget {
  const HarmfulAppsScreen({super.key});

  @override
  State<HarmfulAppsScreen> createState() => _HarmfulAppsScreenState();
}

class _HarmfulAppsScreenState extends State<HarmfulAppsScreen> {
  List<Map<String, String>> _installedApps = [];
  Set<String> _selectedHarmfulApps = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 설치된 앱 목록 가져오기
      final apps = await UsageReporter.getInstalledApps();
      
      // 저장된 유해앱 목록 불러오기
      final prefs = await SharedPreferences.getInstance();
      final savedHarmfulApps = prefs.getStringList('harmfulApps') ?? [];
      
      setState(() {
        _installedApps = apps;
        _selectedHarmfulApps = savedHarmfulApps.toSet();
        _isLoading = false;
      });

      // 백엔드에서 유해앱 목록 동기화
      await _loadFromBackend();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('앱 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _saveHarmfulApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('harmfulApps', _selectedHarmfulApps.toList());
      
      // 백엔드로 유해앱 목록 전송
      await _sendToBackend();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('유해앱 설정이 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _sendToBackend() async {
    try {
      // 선택된 유해앱들을 앱 이름으로 변환
      List<String> appNames = [];
      for (String packageName in _selectedHarmfulApps) {
        final app = _installedApps.firstWhere(
          (app) => app['packageName'] == packageName,
          orElse: () => {'appName': packageName},
        );
        appNames.add(app['appName'] ?? packageName);
      }

      final harmfulApps = HarmfulAppsModel(
        distractionAppList: appNames,
      );

      final response = await ApiService.sendHarmfulApps(harmfulApps);
      
      if (response.statusCode == 200) {
        print('백엔드로 유해앱 목록 전송 성공');
      } else {
        print('백엔드로 유해앱 목록 전송 실패: ${response.statusCode}');
        print('응답 내용: ${response.body}');
      }
    } catch (e) {
      print('백엔드 전송 중 오류 발생: $e');
    }
  }

  Future<void> _loadFromBackend() async {
    try {
      final response = await ApiService.getHarmfulApps();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final harmfulApps = HarmfulAppsModel.fromJson(data);
        
        // 백엔드에서 받은 앱 이름들을 패키지명으로 변환
        Set<String> backendPackageNames = {};
        for (String appName in harmfulApps.distractionAppList) {
          final app = _installedApps.firstWhere(
            (app) => app['appName'] == appName,
            orElse: () => {'packageName': ''},
          );
          if (app['packageName']?.isNotEmpty == true) {
            backendPackageNames.add(app['packageName']!);
          }
        }
        
        setState(() {
          _selectedHarmfulApps = backendPackageNames;
        });
        
        // 로컬에도 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('harmfulApps', _selectedHarmfulApps.toList());
        
        print('백엔드에서 유해앱 목록 로드 성공');
      } else {
        print('백엔드에서 유해앱 목록 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('백엔드 로드 중 오류 발생: $e');
    }
  }

  void _toggleAppSelection(String packageName) {
    setState(() {
      if (_selectedHarmfulApps.contains(packageName)) {
        _selectedHarmfulApps.remove(packageName);
      } else {
        _selectedHarmfulApps.add(packageName);
      }
    });
    _saveHarmfulApps();
  }

  List<Map<String, String>> get _filteredApps {
    if (_searchQuery.isEmpty) {
      return _installedApps;
    }
    return _installedApps.where((app) {
      final appName = app['appName']?.toLowerCase() ?? '';
      final packageName = app['packageName']?.toLowerCase() ?? '';
      return appName.contains(_searchQuery.toLowerCase()) ||
             packageName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '유해앱 설정',
          style: GoogleFonts.inter(
            fontSize: 25,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFFF504A),
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _sendToBackend,
            icon: const Icon(Icons.sync, color: Colors.white),
            tooltip: '백엔드로 동기화',
          ),
          TextButton(
            onPressed: _selectedHarmfulApps.isEmpty ? null : () {
              setState(() {
                _selectedHarmfulApps.clear();
              });
              _saveHarmfulApps();
            },
            child: Text(
              '전체 해제',
              style: TextStyle(
                color: _selectedHarmfulApps.isEmpty ? Colors.grey : const Color(0xFFFF504A),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '앱 이름으로 검색...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[900],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // 설명 텍스트
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 8),
            child: Text(
              '선택한 앱을 실행할 때 알림을 받을 수 있습니다. 유해하다고 생각되는 앱들을 선택해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.4,
              ),
            ),
          ),
          
          // 선택된 앱 개수 표시
          if (_selectedHarmfulApps.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFF504A).withOpacity(0.1),
              child: Text(
                '선택된 유해앱: ${_selectedHarmfulApps.length}개',
                style: const TextStyle(
                  color: Color(0xFFFF504A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          // 앱 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF504A)))
                : _filteredApps.isEmpty
                    ? const Center(
                        child: Text(
                          '설치된 앱이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          final packageName = app['packageName'] ?? '';
                          final appName = app['appName'] ?? '';
                          final isSelected = _selectedHarmfulApps.contains(packageName);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            color: Colors.grey[900],
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFF504A).withOpacity(0.2) : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.apps,
                                  color: isSelected ? const Color(0xFFFF504A) : Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                appName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? const Color(0xFFFF504A) : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                packageName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              trailing: Switch(
                                value: isSelected,
                                onChanged: (value) => _toggleAppSelection(packageName),
                                activeColor: const Color(0xFFFF504A),
                              ),
                              onTap: () => _toggleAppSelection(packageName),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
