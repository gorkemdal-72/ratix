import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/social/post_detail_screen.dart';
import '../screens/social/notifications_screen.dart';
import '../screens/admin/admin_reports_screen.dart';

// Arka planda gelen mesajları işlemek için top-level fonksiyon
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Arka plan mesajı alındı: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Handle routing based on payload
  void _handleMessage(RemoteMessage? message) {
    if (message == null) return;
    
    final data = message.data;
    final type = data['type'] as String?;
    
    if (type == 'new_report') {
       navigatorKey.currentState?.push(
         MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
       );
       return;
    }
    
    if (data.containsKey('post_id') && data['post_id'] != null && data['post_id'].toString().isNotEmpty) {
      final postId = data['post_id'];
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
      );
      return;
    }
    
    // Diğer tüm bildirimlerde bildirimler sekmesine yönlendir
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      // Background handler'ı kaydet
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // İzin iste
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Kullanıcı bildirimi izni: ${settings.authorizationStatus}');

      // Sadece Android için local notifications kurulumu
      if (Platform.isAndroid) {
        const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
        await _localNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
             navigatorKey.currentState?.push(
               MaterialPageRoute(builder: (_) => const NotificationsScreen()),
             );
          },
        );

        // Android 8.0+ için yüksek öncelikli kanal
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'Yüksek Öncelikli Bildirimler', // title
          description: 'Bu kanal uygulama içi önemli bildirimler için kullanılır.', // description
          importance: Importance.max,
        );

        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Ön plandayken bildirim gelirse dinle
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Ön planda mesaj alındı: ${message.messageId}');
        
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null && !kIsWeb) {
          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'Yüksek Öncelikli Bildirimler',
                channelDescription: 'Bu kanal uygulama içi önemli bildirimler için kullanılır.',
                icon: '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      // Arka plandayken bildirime tıklama
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // Kapalıyken bildirime tıklama
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          // Gecikmeli veriyoruz ki UI çizilsin
          Future.delayed(const Duration(milliseconds: 500), () {
            _handleMessage(message);
          });
        }
      });

      // Token'ı al ve dinle
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }

      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToSupabase(newToken);
      });

      _initialized = true;
    } catch (e) {
      debugPrint('PushNotificationService başlatılamadı: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update({'fcm_token': token})
            .eq('id', user.id);
        debugPrint('FCM Token başarıyla kaydedildi: $token');
      }
    } catch (e) {
      debugPrint('FCM Token Supabase\'e kaydedilemedi: $e');
    }
  }

  // Çıkış yaparken token'ı sil
  Future<void> deleteToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update({'fcm_token': null})
            .eq('id', user.id);
      }
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('Token silinirken hata oluştu: $e');
    }
  }
}
