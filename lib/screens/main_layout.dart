import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import 'home/home_screen.dart';
import 'social/social_feed_screen.dart';
import 'social/notifications_screen.dart';
import 'social/social_profile_screen.dart';
import 'diary/diary_screen.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  late Widget _currentScreen;

  @override
  void initState() {
    super.initState();
    _currentScreen = _buildScreen(0);
    _fetchUnreadCount();
    _ensureProfile();
    _requestNotificationPermission();
    PushNotificationService().init();
  }

  /// Giriş sonrası kullanıcı profilinin users tablosunda var olduğundan emin ol
  Future<void> _ensureProfile() async {
    try {
      await context.read<AuthService>().ensureUserProfile();
    } catch (_) {}
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  Widget _buildScreen(int index) {
    final currentUserId = context.read<AuthService>().currentUser?.id;
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SocialFeedScreen();
      case 2:
        return const DiaryScreen();
      case 3:
        return const NotificationsScreen();
      case 4:
        return SocialProfileScreen(userId: currentUserId ?? '');
      default:
        return const HomeScreen();
    }
  }

  void _fetchUnreadCount() async {
    final count = await context.read<NotificationService>().getUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _currentScreen = _buildScreen(index);
          });
          if (index == 3) {
            // Bildirimler sekmesine geçilirse sayacı sıfırla
            setState(() => _unreadCount = 0);
          } else {
            _fetchUnreadCount(); // Diğer sekmelerdeyken güncel sayıyı çek
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Listelerim',
          ),
          const NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Keşfet',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Günlük',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text(_unreadCount.toString()),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Bildirimler',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
