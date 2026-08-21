import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/property/property_detail_screen.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  int _navRetryCount = 0;
  static const int _maxNavRetries = 10;

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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        _saveTokenToFirestore(uid, token);
      }
    });
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> saveToken(String uid) async {
    if (uid.isEmpty) return;
    final token = await getToken();
    if (token != null) await _saveTokenToFirestore(uid, token);
  }

  Future<void> _saveTokenToFirestore(String uid, String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteToken(String uid) async {
    if (uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (_) {}
  }

  void _showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final type = message.data['type']?.toString() ?? '';
    final targetId = message.data['targetId']?.toString() ?? '';
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId(type),
          _channelName(type),
          channelDescription: 'إشعارات ${_channelName(type)}',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: '$type|$targetId',
    );
  }

  String _channelId(String type) {
    switch (type) {
      case 'message':
        return 'messages_channel';
      case 'property':
        return 'properties_channel';
      case 'visit_request':
        return 'visits_channel';
      default:
        return 'default_channel';
    }
  }

  String _channelName(String type) {
    switch (type) {
      case 'message':
        return 'الرسائل';
      case 'property':
        return 'العقارات';
      case 'visit_request':
        return 'طلبات المعاينة';
      default:
        return 'الإشعارات العامة';
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload ?? '';
    final separatorIndex = payload.indexOf('|');
    if (separatorIndex == -1) {
      _navigateToTarget(payload.isEmpty ? null : payload, '');
      return;
    }
    final type = payload.substring(0, separatorIndex);
    final targetId = payload.substring(separatorIndex + 1);
    _navigateToTarget(targetId.isEmpty ? null : targetId, type);
  }

  void _handleNotificationData(RemoteMessage message) {
    _navigateToTarget(
      message.data['targetId']?.toString(),
      message.data['type']?.toString() ?? '',
    );
  }

  /// Routes a tapped notification to the correct screen.
  /// If the navigator is not ready yet (cold start), retries briefly.
  void _navigateToTarget(String? targetId, String type) {
    if (targetId == null || targetId.isEmpty) return;

    final nav = navigatorKey.currentState;
    if (nav == null) {
      if (_navRetryCount < _maxNavRetries) {
        _navRetryCount++;
        Timer(const Duration(milliseconds: 600), () => _navigateToTarget(targetId, type));
      }
      return;
    }
    _navRetryCount = 0;

    switch (type) {
      case 'message':
        nav.push(MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: targetId),
        ));
        break;
      case 'property':
      case 'visit_request':
        _openProperty(nav, targetId);
        break;
      default:
        break;
    }
  }

  Future<void> _openProperty(NavigatorState nav, String propertyId) async {
    try {
      final property = await FirestoreService().getPropertyById(propertyId);
      if (property != null) {
        nav.push(MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: property),
        ));
      }
    } catch (_) {
      // Property may have been deleted – silently ignore.
    }
  }
}
