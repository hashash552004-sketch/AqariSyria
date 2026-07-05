import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? targetId;
  final String? senderId;

  AppNotification({
    this.id = '',
    this.userId = '',
    this.type = 'system',
    this.title = '',
    this.message = '',
    this.isRead = false,
    DateTime? createdAt,
    this.targetId,
    this.senderId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return AppNotification(
      id: id,
      userId: data['userId']?.toString() ?? '',
      type: data['type']?.toString() ?? 'system',
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetId: data['targetId']?.toString(),
      senderId: data['senderId']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'targetId': targetId,
      'senderId': senderId,
    };
  }
}
