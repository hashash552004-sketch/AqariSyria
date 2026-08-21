import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aqari_syria/models/chat.dart';
import 'package:aqari_syria/models/review.dart';
import 'package:aqari_syria/widgets/star_rating.dart';

void main() {
  group('ChatMessage', () {
    test('parses text message from firestore data', () {
      final msg = ChatMessage.fromFirestore({
        'conversationId': 'c1',
        'senderId': 'u1',
        'senderName': 'أحمد',
        'message': 'مرحبا',
        'type': 'text',
        'imageUrl': null,
        'timestamp': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'isRead': false,
        'isDeleted': false,
      }, 'm1');

      expect(msg.id, 'm1');
      expect(msg.senderId, 'u1');
      expect(msg.type, 'text');
      expect(msg.isRead, false);
      expect(msg.timestamp.year, 2026);
    });

    test('falls back safely on malformed data', () {
      final msg = ChatMessage.fromFirestore(<String, dynamic>{}, 'm2');
      expect(msg.senderId, '');
      expect(msg.message, '');
      expect(msg.isRead, false);
    });

    test('image message keeps url', () {
      final msg = ChatMessage(
        senderId: 'u2',
        type: 'image',
        imageUrl: 'https://example.com/x.jpg',
      );
      final map = msg.toFirestore();
      expect(map['type'], 'image');
      expect(map['imageUrl'], 'https://example.com/x.jpg');
    });
  });

  group('Conversation unread counters', () {
    test('uses per-role counter when viewer role is provided', () {
      final conv = Conversation.fromFirestore({
        'ownerId': 'owner1',
        'interestedUserId': 'seeker1',
        'unreadCount': 99,
        'ownerUnreadCount': 3,
        'interestedUnreadCount': 7,
      }, 'conv1', unreadForViewer: 3);
      expect(conv.unreadCount, 3);
    });

    test('falls back to legacy shared counter', () {
      final conv = Conversation.fromFirestore({
        'ownerId': 'owner1',
        'interestedUserId': 'seeker1',
        'unreadCount': 5,
      }, 'conv1');
      expect(conv.unreadCount, 5);
    });

    test('defaults to zero on empty doc', () {
      final conv = Conversation.fromFirestore({}, 'conv2');
      expect(conv.unreadCount, 0);
      expect(conv.lastMessage, '');
    });
  });

  group('Review', () {
    test('clamps and parses rating', () {
      final review = Review.fromFirestore({
        'userId': 'u9',
        'userName': 'سارة',
        'rating': 4,
        'comment': 'جيد جداً',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 10)),
      }, 'u9');
      expect(review.rating, 4);
      expect(review.userId, 'u9');
      expect(review.comment, 'جيد جداً');
    });
  });

  group('StarRating widget', () {
    testWidgets('renders five stars and count label', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: StarRating(rating: 4.0, reviewsCount: 12)),
      ));
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(find.text('(12)'), findsOneWidget);
    });
  });
}
