import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationData);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationData(initialMessage);

    _messaging.onTokenRefresh.listen((token) {
      final uid = _getCurrentUid();
      if (uid != null) _saveTokenToFirestore(uid, token);
    });
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> saveToken(String uid) async {
    final token = await getToken();
    if (token != null) _saveTokenToFirestore(uid, token);
  }

  Future<void> _saveTokenToFirestore(String uid, String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteToken(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }

  String? _getCurrentUid() {
    try {
      final user = FirebaseFirestore.instance.collection('_currentUser');
      return null; // placeholder – set externally after auth
    } catch (_) {
      return null;
    }
  }

  void _showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final type = message.data['type'] ?? 'general';
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          '${type}_channel',
          _channelName(type),
          channelDescription: 'إشعارات ${_channelName(type)}',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['targetId'],
    );
  }

  String _channelName(String type) {
    switch (type) {
      case 'message': return 'الرسائل';
      case 'property': return 'العقارات';
      case 'visit_request': return 'طلبات المعاينة';
      default: return 'الإشعارات';
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    _navigateToTarget(response.payload);
  }

  void _handleNotificationData(RemoteMessage message) {
    _navigateToTarget(message.data['targetId']);
  }

  void _navigateToTarget(String? targetId) {
    if (targetId == null || targetId.isEmpty) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamed('/property/$targetId');
  }
}
