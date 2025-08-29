import '../models/notification_model.dart';
import 'api_service.dart';

// 알림 상태 변경을 위한 리스너
typedef NotificationListener = void Function();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // 알림 목록 캐시
  List<NotificationModel> _cachedNotifications = [];
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMoreData = true;

  // 리스너 목록
  final List<NotificationListener> _listeners = [];

  // 리스너 추가
  void addListener(NotificationListener listener) {
    _listeners.add(listener);
  }

  // 리스너 제거
  void removeListener(NotificationListener listener) {
    _listeners.remove(listener);
  }

  // 모든 리스너에게 알림
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // 캐시된 알림 목록 가져오기
  List<NotificationModel> get cachedNotifications => List.unmodifiable(_cachedNotifications);

  // 읽지 않은 알림 개수
  int get unreadCount => _cachedNotifications.where((n) => !n.isRead).length;

  // 알림 목록 새로고침
  Future<List<NotificationModel>> refreshNotifications() async {
    print('🔍 refreshNotifications 시작');
    _currentPage = 0;
    _hasMoreData = true;
    _cachedNotifications.clear();
    
    final result = await _loadNotifications();
    _notifyListeners(); // 리스너들에게 알림
    return result;
  }

  // 알림 목록 로드 (페이지네이션)
  Future<List<NotificationModel>> loadNotifications({bool loadMore = false}) async {
    print('🔍 loadNotifications 시작: loadMore=$loadMore');
    
    if (loadMore && !_hasMoreData) {
      print('🔍 더 이상 로드할 데이터가 없음');
      return _cachedNotifications;
    }

    if (loadMore) {
      _currentPage++;
      print('🔍 다음 페이지 로드: $_currentPage');
    } else {
      _currentPage = 0;
      _cachedNotifications.clear();
      print('🔍 첫 페이지 로드');
    }

    final result = await _loadNotifications();
    if (!loadMore) {
      _notifyListeners(); // 리스너들에게 알림
    }
    return result;
  }

  // 실제 API 호출
  Future<List<NotificationModel>> _loadNotifications() async {
    print('🔍 _loadNotifications 시작');
    print('🔍 현재 페이지: $_currentPage');
    print('🔍 총 페이지: $_totalPages');
    print('🔍 더 많은 데이터: $_hasMoreData');
    
    try {
      print('🔍 ApiService.getNotifications 호출');
      final response = await ApiService.getNotifications(
        page: _currentPage,
        size: 20,
      );
      
      print('🔍 API 응답 받음: ${response != null ? '성공' : '실패'}');
      
      if (response != null && response.returnCode == 'SUCCESS') {
        print('🔍 응답 코드가 SUCCESS');
        final pageData = response.dmPage;
        
        if (pageData != null) {
          print('🔍 dmPage 데이터 존재');
          print('🔍 페이지 정보: pageNumber=${pageData.pageNumber}, totalPages=${pageData.totalPages}');
          print('🔍 알림 개수: ${pageData.contents.length}개');
          
          _totalPages = pageData.totalPages;
          _hasMoreData = _currentPage < pageData.totalPages - 1;
          
          print('🔍 업데이트된 상태: totalPages=$_totalPages, hasMoreData=$_hasMoreData');
          
          if (_currentPage == 0) {
            print('🔍 첫 페이지: 캐시 초기화');
            _cachedNotifications = pageData.contents;
          } else {
            print('🔍 추가 페이지: 캐시에 추가');
            _cachedNotifications.addAll(pageData.contents);
          }
          
          print('🔍 최종 캐시된 알림 개수: ${_cachedNotifications.length}개');
          return _cachedNotifications;
        } else {
          print('⚠️ dmPage 데이터가 null');
        }
      } else {
        print('⚠️ 응답이 null이거나 SUCCESS가 아님');
        print('⚠️ 응답: $response');
        if (response != null) {
          print('⚠️ returnCode: ${response.returnCode}');
          print('⚠️ returnMessage: ${response.returnMessage}');
        }
      }
      
      print('🔍 기본 캐시된 알림 반환: ${_cachedNotifications.length}개');
      return _cachedNotifications;
    } catch (e, stackTrace) {
      print('❌ _loadNotifications 실패: $e');
      print('❌ 오류 스택: $stackTrace');
      print('🔍 에러 발생 시 기존 캐시 반환: ${_cachedNotifications.length}개');
      return _cachedNotifications;
    }
  }

  // 특정 알림 읽음 처리
  Future<bool> markAsRead(int notificationId) async {
    print('🔍 markAsRead 시작: notificationId=$notificationId');
    try {
      final success = await ApiService.markNotificationsAsRead([notificationId]);
      if (success) {
        final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _cachedNotifications[index] = _cachedNotifications[index].copyWith(isRead: true);
          print('✅ 캐시에서 알림 읽음 상태 업데이트: index=$index');
          _notifyListeners(); // 리스너들에게 알림
        } else {
          print('⚠️ 캐시에서 알림을 찾을 수 없음: notificationId=$notificationId');
        }
        return true;
      }
      return false;
    } catch (e) {
      print('❌ 알림 읽음 처리 실패: $e');
      return false;
    }
  }

  // 여러 알림 읽음 처리
  Future<bool> markMultipleAsRead(List<int> notificationIds) async {
    print('🔍 markMultipleAsRead 시작: notificationIds=$notificationIds');
    try {
      final success = await ApiService.markNotificationsAsRead(notificationIds);
      if (success) {
        for (final id in notificationIds) {
          final index = _cachedNotifications.indexWhere((n) => n.id == id);
          if (index != -1) {
            _cachedNotifications[index] = _cachedNotifications[index].copyWith(isRead: true);
            print('✅ 캐시에서 알림 읽음 상태 업데이트: notificationId=$id, index=$index');
          }
        }
        _notifyListeners(); // 리스너들에게 알림
        return true;
      }
      return false;
    } catch (e) {
      print('❌ 여러 알림 읽음 처리 실패: $e');
      return false;
    }
  }

  // 모든 알림 읽음 처리
  Future<bool> markAllAsRead() async {
    print('🔍 markAllAsRead 시작');
    final unreadIds = _cachedNotifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();
    
    print('🔍 읽지 않은 알림 개수: ${unreadIds.length}개');
    print('🔍 읽지 않은 알림 ID들: $unreadIds');
    
    if (unreadIds.isEmpty) {
      print('🔍 읽지 않은 알림이 없음');
      return true;
    }
    
    final result = await markMultipleAsRead(unreadIds);
    if (result) {
      _notifyListeners(); // 리스너들에게 알림
    }
    return result;
  }

  // 캐시 초기화
  void clearCache() {
    print('🔍 clearCache 시작');
    _cachedNotifications.clear();
    _currentPage = 0;
    _totalPages = 0;
    _hasMoreData = true;
    _notifyListeners(); // 리스너들에게 알림
  }

  // 더 많은 데이터가 있는지 확인
  bool get hasMoreData => _hasMoreData;

  // 현재 페이지 정보
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
}
