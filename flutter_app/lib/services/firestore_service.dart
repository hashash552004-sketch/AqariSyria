import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/report.dart';
import '../models/app_settings.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Property>> streamProperties({
    String? type,
    String? operationType,
  }) {
    Query query = _firestore
        .collection('properties');

    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    if (operationType != null && operationType.isNotEmpty) {
      query = query.where('operationType', isEqualTo: operationType);
    }

    return query.snapshots().map((snapshot) {
      final properties = snapshot.docs
          .map(
            (doc) => Property.fromFirestore(
              Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>),
              doc.id,
            ),
          )
          .toList();
      properties.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return properties;
    });
  }

  Stream<List<Property>> streamFeaturedProperties() {
    return _firestore
        .collection('properties')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final properties = snapshot.docs
          .map(
            (doc) => Property.fromFirestore(
              Map<String, dynamic>.from(
                doc.data() as Map<dynamic, dynamic>,
              ),
              doc.id,
            ),
          )
          .toList();
      properties.sort((a, b) {
        final aViews = a.viewsCount ?? 0;
        final bViews = b.viewsCount ?? 0;
        return bViews.compareTo(aViews);
      });
      return properties.take(10).toList();
    });
  }

  Future<void> createProperty(Property property) async {
    await _firestore.collection('properties').add({
      ...property.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isUsernameTaken(String username) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> saveUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<void> ensureDefaultAdmin(String uid, String email) async {
    const adminEmail = 'hashash552004@gmail.com';
    if (email != adminEmail) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final role = doc.data()?['role']?.toString() ?? 'user';
    if (role != 'admin') {
      await _firestore.collection('users').doc(uid).update({'role': 'admin'});
    }
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc.data()!, uid);
  }

  Future<void> toggleFavorite(String uid, String propertyId) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return;
    final current =
        (userDoc.data()?['favorites'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final isAdding = !current.contains(propertyId);
    if (isAdding) {
      current.add(propertyId);
    } else {
      current.remove(propertyId);
    }
    await _firestore.collection('users').doc(uid).update({
      'favorites': current,
    });

    if (isAdding) {
      final propDoc = await _firestore.collection('properties').doc(propertyId).get();
      if (propDoc.exists) {
        final ownerId = propDoc.data()?['ownerId']?.toString() ?? '';
        if (ownerId.isNotEmpty && ownerId != uid) {
          final userName = await getUserName(uid);
          final title = await getPropertyTitle(propertyId);
          await createNotification(
            userId: ownerId,
            type: 'property',
            title: 'إضافة للمفضلة',
            message: 'أضاف ${userName ?? 'مستخدم'} عقارك "${title ?? propertyId}" إلى المفضلة',
            targetId: propertyId,
            senderId: uid,
          );
        }
      }
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    await _firestore.collection('properties').doc(propertyId).delete();
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
  }

  Future<void> banUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'banned': true});
  }

  Future<void> unbanUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'banned': false});
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    final props = await _firestore.collection('properties').where('ownerId', isEqualTo: uid).get();
    final batch = _firestore.batch();
    for (final doc in props.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteUserProperties(String uid) async {
    final props = await _firestore.collection('properties').where('ownerId', isEqualTo: uid).get();
    final batch = _firestore.batch();
    for (final doc in props.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> updateProperty(
    String propertyId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('properties').doc(propertyId).update(data);
  }

  Stream<List<AppUser>> streamUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppUser.fromFirestore(
          Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>),
          doc.id,
        );
      }).toList();
    });
  }

  Future<List<Property>> getAllPropertiesAdmin() async {
    final snapshot = await _firestore.collection('properties').get();
    return snapshot.docs.map((doc) {
      return Property.fromFirestore(
        Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>),
        doc.id,
      );
    }).toList();
  }

  Future<void> resetAllViews() async {
    final snapshot = await _firestore.collection('properties').get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'viewsCount': 0});
    }
    await batch.commit();
  }

  Future<void> resetAllFavorites() async {
    final snapshot = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'favorites': []});
    }
    await batch.commit();
  }

  Future<void> deleteAllProperties() async {
    final snapshot = await _firestore.collection('properties').get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ---- Chat Methods ----

  Future<String> createConversation(
    String propertyId,
    String propertyTitle,
    String ownerId,
    String ownerName,
    String interestedUserId,
    String interestedUserName,
  ) async {
    final convId = '${propertyId}_$interestedUserId';
    final docRef = _firestore.collection('conversations').doc(convId);

    final existing = await docRef.get();
    if (existing.exists) return convId;

    await docRef.set({
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'interestedUserId': interestedUserId,
      'interestedUserName': interestedUserName,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': 0,
    });
    return convId;
  }

  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String senderName,
    String message,
  ) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    final convDoc = await _firestore.collection('conversations').doc(conversationId).get();
    final convData = convDoc.data();
    if (convData != null) {
      final ownerId = convData['ownerId']?.toString() ?? '';
      final interestedUserId = convData['interestedUserId']?.toString() ?? '';
      final recipientId = senderId == ownerId ? interestedUserId : ownerId;
      if (recipientId.isNotEmpty && recipientId != senderId) {
        await createNotification(
          userId: recipientId,
          type: 'message',
          title: 'رسالة جديدة',
          message: 'لديك رسالة جديدة من $senderName',
          targetId: conversationId,
          senderId: senderId,
        );
      }
    }
  }

  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromFirestore(
          Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>),
          doc.id,
        );
      }).toList();
    });
  }

  Stream<List<Conversation>> streamConversations(String userId) {
    final controller = StreamController<List<Conversation>>();

    QuerySnapshot? lastInterested;
    QuerySnapshot? lastOwner;

    void emitCombined() {
      if (lastInterested == null || lastOwner == null) return;
      final all = <Conversation>[];
      final seen = <String>{};
      for (final doc in lastInterested!.docs) {
        if (seen.add(doc.id)) {
          all.add(Conversation.fromFirestore(
            Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>),
            doc.id,
          ));
        }
      }
      for (final doc in lastOwner!.docs) {
        if (seen.add(doc.id)) {
          all.add(Conversation.fromFirestore(
            Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>),
            doc.id,
          ));
        }
      }
      all.sort((a, b) {
        final aTime = a.lastMessageTime ?? DateTime(2000);
        final bTime = b.lastMessageTime ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      controller.add(all);
    }

    final sub1 = _firestore
        .collection('conversations')
        .where('interestedUserId', isEqualTo: userId)
        .snapshots()
        .listen((s) {
      lastInterested = s;
      emitCombined();
    });

    final sub2 = _firestore
        .collection('conversations')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .listen((s) {
      lastOwner = s;
      emitCombined();
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  Future<void> markConversationRead(String conversationId, String userId) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount': 0,
    });
  }

  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _firestore
        .collection('conversations')
        .where('interestedUserId', isEqualTo: userId)
        .get();
    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      count += (data['unreadCount'] as num?)?.toInt() ?? 0;
    }
    return count;
  }

  // ---- Notification Methods ----

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? targetId,
    String? senderId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'targetId': targetId,
      'senderId': senderId,
    });
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Stream<int> streamUnreadNotificationCount(String userId) {
    return streamUserNotifications(userId).map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isRead'] != true;
      }).length;
    });
  }

  Stream<QuerySnapshot> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<String?> getUserName(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['fullName']?.toString();
  }

  Future<String?> getPropertyTitle(String propertyId) async {
    final doc = await _firestore.collection('properties').doc(propertyId).get();
    if (!doc.exists) return null;
    return doc.data()?['title']?.toString();
  }

  // ---- Report Methods ----

  Future<void> reportProperty(
    String propertyId,
    String reportedBy,
    String reason, {
    String? description,
  }) async {
    await _firestore.collection('reports').add({
      'propertyId': propertyId,
      'reportedBy': reportedBy,
      'reason': reason,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    final allUsersSnapshot = await _firestore.collection('users').get();
    final adminSnapshot = allUsersSnapshot.docs.where((doc) {
      final role = doc.data()['role']?.toString() ?? '';
      return role == 'admin' || role == 'moderator';
    });
    for (final adminDoc in adminSnapshot) {
      await createNotification(
        userId: adminDoc.id,
        type: 'system',
        title: 'بلاغ جديد',
        message: 'تم تقديم بلاغ جديد عن عقار: $reason',
        targetId: propertyId,
        senderId: reportedBy,
      );
    }
  }

  Stream<List<Report>> streamReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Report.fromFirestore(
          Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>),
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> resolveReport(String reportId) async {
    final reportDoc = await _firestore.collection('reports').doc(reportId).get();
    if (!reportDoc.exists) return;
    final reportedBy = reportDoc.data()?['reportedBy']?.toString() ?? '';
    final propertyId = reportDoc.data()?['propertyId']?.toString() ?? '';

    await _firestore.collection('reports').doc(reportId).update({
      'status': 'resolved',
    });

    if (reportedBy.isNotEmpty) {
      final title = propertyId.isNotEmpty ? await getPropertyTitle(propertyId) : null;
      await createNotification(
        userId: reportedBy,
        type: 'system',
        title: 'تم حل البلاغ',
        message: 'تم حل البلاغ الذي قدمته${title != null ? ' عن "$title"' : ''}',
        targetId: reportId,
      );
    }
  }

  // ---- Settings Methods ----

  Future<AppSettings> getSettings() async {
    final doc = await _firestore.collection('settings').doc('app').get();
    if (!doc.exists) return AppSettings();
    return AppSettings.fromFirestore(doc.data()!);
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _firestore.collection('settings').doc('app').set(settings.toFirestore());
  }

  // ---- Contact Messages ----

  Future<void> saveContactMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
    String? userId,
    Object? timestamp,
  }) async {
    await _firestore.collection('contact_messages').add({
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'userId': userId,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
