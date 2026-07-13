import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String message;
  final String type;       // 'text', 'image', 'system'
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;

  ChatMessage({
    this.id = '',
    this.conversationId = '',
    this.senderId = '',
    this.senderName = '',
    this.message = '',
    this.type = 'text',
    this.imageUrl,
    DateTime? timestamp,
    this.isRead = false,
    this.isDeleted = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      conversationId: data['conversationId']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      type: data['type']?.toString() ?? 'text',
      imageUrl: data['imageUrl']?.toString(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': type,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
  }
}

class Conversation {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String ownerId;
  final String ownerName;
  final String interestedUserId;
  final String interestedUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  Conversation({
    this.id = '',
    this.propertyId = '',
    this.propertyTitle = '',
    this.ownerId = '',
    this.ownerName = '',
    this.interestedUserId = '',
    this.interestedUserName = '',
    this.lastMessage = '',
    DateTime? lastMessageTime,
    this.unreadCount = 0,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  factory Conversation.fromFirestore(Map<String, dynamic> data, String id) {
    return Conversation(
      id: id,
      propertyId: data['propertyId']?.toString() ?? '',
      propertyTitle: data['propertyTitle']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      interestedUserId: data['interestedUserId']?.toString() ?? '',
      interestedUserName: data['interestedUserName']?.toString() ?? '',
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'interestedUserId': interestedUserId,
      'interestedUserName': interestedUserName,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
    };
  }
}

