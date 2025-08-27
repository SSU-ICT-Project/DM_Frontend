

import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationSearchWidget extends StatefulWidget {
  final Function(PlaceInfo) onLocationSelected;
  final String? initialLocation;

  const LocationSearchWidget({
    Key? key,
    required this.onLocationSelected,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualInputController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<PlaceInfo> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _searchController.text = widget.initialLocation!;
      _manualInputController.text = widget.initialLocation!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualInputController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 장소 검색 실행
  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      print('🔍 장소 검색 시작: $query');
      final results = await LocationService.searchPlaces(query);
      print('📥 검색 결과: ${results.length}개');

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('❌ 장소 검색 오류: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('장소 검색 중 오류가 발생했습니다: $e')),
      );
    }
  }

  /// 장소 선택 처리
  void _selectLocation(PlaceInfo place) {
    print('📍 장소 선택됨: ${place.name} (${place.address})');
    widget.onLocationSelected(place);
    _searchController.text = '${place.name} (${place.address})';
    setState(() {
      _showResults = false;
    });
    _searchFocusNode.unfocus();
  }

  /// 현재 위치 사용
  Future<void> _useCurrentLocation() async {
    setState(() {
      _isSearching = true;
    });

    try {
      print('📍 현재 위치 가져오기 시작');
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        print('📍 현재 위치 좌표: ${position.latitude}, ${position.longitude}');
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (address != null) {
          print('📍 현재 위치 주소: $address');
          final currentLocationPlace = PlaceInfo(
            id: 'current_location',
            name: '현재 위치',
            address: address,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          _selectLocation(currentLocationPlace);
        } else {
          print('❌ 주소 변환 실패');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('현재 위치의 주소를 가져올 수 없습니다.')),
          );
        }
      } else {
        print('❌ 현재 위치 가져오기 실패');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 위치를 가져올 수 없습니다.')),
        );
      }
    } catch (e) {
      print('❌ 현재 위치 사용 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 위치 사용 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// 수동 입력으로 장소 선택
  void _selectManualLocation() {
    final manualText = _manualInputController.text.trim();
    if (manualText.isNotEmpty) {
      final manualPlace = PlaceInfo(
        id: 'manual_input',
        name: manualText,
        address: '수동 입력',
        latitude: null,
        longitude: null,
      );
      _selectLocation(manualPlace);
    }
  }

  /// 수동 입력 토글
  void _toggleManualInput() {
    setState(() {
      _showManualInput = !_showManualInput;
      if (_showManualInput) {
        _showResults = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 검색 바
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '장소를 검색하세요 (예: 강남역, 홍대입구)',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () => _searchPlaces(_searchController.text),
                          ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _searchPlaces(value);
                    } else {
                      setState(() {
                        _searchResults = [];
                        _showResults = false;
                      });
                    }
                  },
                  onSubmitted: _searchPlaces,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 버튼들 (현재 위치, 수동 입력)
        Row(
          children: [
            // 현재 위치 버튼
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSearching ? null : _useCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('현재 위치'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.grey),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 수동 입력 버튼
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleManualInput,
                icon: Icon(_showManualInput ? Icons.close : Icons.edit, size: 18),
                label: Text(_showManualInput ? '닫기' : '수동 입력'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.grey),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 수동 입력 필드
        if (_showManualInput)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualInputController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '위치를 직접 입력하세요',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _selectManualLocation,
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        
        // 검색 결과 목록
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[800]!,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(
                      place.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      place.address,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectLocation(place),
                    tileColor: Colors.transparent,
                    hoverColor: Colors.grey[800],
                    selectedTileColor: Colors.grey[800],
                  ),
                );
              },
            ),
          ),
        
        // 검색 결과가 없을 때
        if (_showResults && _searchResults.isEmpty && !_isSearching)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: const Center(
              child: Text(
                '검색 결과가 없습니다.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
