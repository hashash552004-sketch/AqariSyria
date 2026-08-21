import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String propertyId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Review({
    this.id = '',
    this.propertyId = '',
    this.userId = '',
    this.userName = '',
    this.rating = 5,
    this.comment = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Review.fromFirestore(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      propertyId: data['propertyId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'مستخدم',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      comment: data['comment']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
