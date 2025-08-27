// lib/services/location_service.dart

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  static String get _googleApiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  
  static final Dio _dio = Dio();

  /// 현재 위치 가져오기
  static Future<Position?> getCurrentLocation() async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // 현재 위치 가져오기
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('현재 위치 가져오기 실패: $e');
      return null;
    }
  }

  /// Google Places API를 사용한 장소 검색
  static Future<List<PlaceInfo>> searchPlaces(String query) async {
    try {
      print('🔍 Google Places API로 장소 검색 시작: $query');
      
      if (_googleApiKey.isEmpty) {
        print('❌ Google Places API 키가 설정되지 않았습니다.');
        return [];
      }
      
      print('🔑 사용 중인 API 키: ${_googleApiKey.substring(0, 10)}...');
      
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/textsearch/json',
        queryParameters: {
          'query': query,
          'key': _googleApiKey,
          'language': 'ko',
          'region': 'kr',
        },
      );

      print('📥 Google API 응답 상태: ${response.statusCode}');
      print('📥 Google API 응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        
        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          final places = results.map((result) => PlaceInfo.fromGoogleJson(result)).toList();
          print('✅ 검색 결과 ${places.length}개 발견');
          return places;
        } else {
          print('❌ Google API 오류: ${data['status']} - ${data['error_message'] ?? '알 수 없는 오류'}');
          
          // API 키 문제인지 확인
          if (data['status'] == 'REQUEST_DENIED') {
            print('🚫 API 키가 거부되었습니다. API 키를 확인해주세요.');
          } else if (data['status'] == 'OVER_QUERY_LIMIT') {
            print('🚫 API 할당량이 초과되었습니다.');
          } else if (data['status'] == 'INVALID_REQUEST') {
            print('🚫 잘못된 요청입니다.');
          }
        }
      } else {
        print('❌ HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Google 장소 검색 실패: $e');
    }
    return [];
  }

  /// Google Places API 테스트
  static Future<bool> testGooglePlacesAPI() async {
    try {
      print('🧪 Google Places API 테스트 시작...');
      
      if (_googleApiKey.isEmpty) {
        print('❌ Google Places API 키가 설정되지 않았습니다.');
        return false;
      }
      
      final results = await searchPlaces('강남역');
      print('🧪 테스트 결과: ${results.length}개 장소 발견');
      return results.isNotEmpty;
    } catch (e) {
      print('🧪 API 테스트 실패: $e');
      return false;
    }
  }

  /// 좌표를 주소로 변환 (역지오코딩)
  static Future<String?> getAddressFromCoordinates(
    double latitude, 
    double longitude
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.administrativeArea} ${place.subLocality} ${place.thoroughfare}';
      }
    } catch (e) {
      print('좌표를 주소로 변환 실패: $e');
    }
    return null;
  }

  /// 주소를 좌표로 변환 (지오코딩)
  static Future<LocationCoordinates?> getCoordinatesFromAddress(
    String address
  ) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return LocationCoordinates(
          latitude: location.latitude,
          longitude: location.longitude,
        );
      }
    } catch (e) {
      print('주소를 좌표로 변환 실패: $e');
    }
    return null;
  }
}

/// 장소 정보를 담는 클래스
class PlaceInfo {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? category;

  PlaceInfo({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.category,
  });

  /// Google Places API 응답에서 PlaceInfo 생성
  factory PlaceInfo.fromGoogleJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};
    
    return PlaceInfo(
      id: json['place_id'],
      name: json['name'],
      address: json['formatted_address'],
      latitude: location['lat']?.toDouble(),
      longitude: location['lng']?.toDouble(),
      phoneNumber: json['formatted_phone_number'],
      category: json['types']?.first,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'category': category,
    };
  }

  @override
  String toString() {
    return 'PlaceInfo(id: $id, name: $name, address: $address)';
  }
}

/// 좌표 정보를 담는 클래스
class LocationCoordinates {
  final double latitude;
  final double longitude;

  LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
