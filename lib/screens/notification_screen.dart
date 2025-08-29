import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 자동으로 알림 로드
    _loadNotifications();
  }

  // 알림 목록 로드
  Future<void> _loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = refresh
          ? await _notificationService.refreshNotifications()
          : await _notificationService.loadNotifications();

      setState(() {
        _notifications = notifications;
        _hasError = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = '알림을 불러오는데 실패했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 다음 페이지 로드
  Future<void> _loadNextPage() async {
    if (_notificationService.hasMoreData && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      try {
        final notifications = await _notificationService.loadNotifications(loadMore: true);
        setState(() {
          _notifications = notifications;
        });
      } catch (e) {
        print('다음 페이지 로드 실패: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 알림 읽음 처리
  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final success = await _notificationService.markAsRead(notification.id);
      if (success) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      print('알림 읽음 처리 실패: $e');
    }
  }

  // 모든 알림 읽음 처리
  Future<void> _markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      if (success) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('모든 알림을 읽음 처리했습니다'),
              ],
            ),
            backgroundColor: const Color(0xFFFF504A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('모든 알림 읽음 처리 실패: $e');
    }
  }

  // 시간 포맷팅
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text(
          '알림 목록',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white70),
              onPressed: _markAllAsRead,
              tooltip: '모두 읽음 처리',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF504A),
            ),
            SizedBox(height: 16),
            Text(
              '알림을 불러오는 중...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_hasError && _notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '알림을 불러올 수 없습니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadNotifications(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF504A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '알림이 없습니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 알림이 도착하면\n여기에 표시됩니다',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      color: const Color(0xFFFF504A),
      backgroundColor: const Color(0xFF1A1A1A),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _notifications.length + (_notificationService.hasMoreData ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return _buildLoadMoreButton();
          }
          return _buildNotificationItem(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead 
            ? const Color(0xFF1A1A1A) 
            : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead 
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFFF504A).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _markAsRead(notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 알림 내용 (제목 없이 텍스트만)
                Text(
                  notification.content,
                  style: TextStyle(
                    color: notification.isRead 
                        ? Colors.white70 
                        : Colors.white,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: notification.isRead 
                        ? FontWeight.w400 
                        : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // 하단: 시간과 읽음 상태
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(notification.createdAt),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF504A),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (!_notificationService.hasMoreData) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Color(0xFFFF504A),
              )
            : ElevatedButton.icon(
                onPressed: _loadNextPage,
                icon: const Icon(Icons.expand_more),
                label: const Text('더 보기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
      ),
    );
  }
}