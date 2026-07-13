import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/report.dart';
import '../models/app_settings.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getPropertiesPaginated({
    DocumentSnapshot? lastDoc,
    int limitCount = 10,
    String? type,
    String? operationType,
  }) async {
    var query = _firestore
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .limit(limitCount);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.get();
    final lastVisible = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    final properties = <Property>[];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] != 'approved') continue;
      if (type != null && data['type'] != type) continue;
      if (operationType != null && data['operationType'] != operationType) continue;
      properties.add(Property.fromFirestore(Map<String, dynamic>.from(data), doc.id));
    }

    return {
      'properties': properties,
      'lastDoc': lastVisible,
      'hasMore': snapshot.docs.length == limitCount,
    };
  }

  Stream<List<Property>> streamProperties({
    String? type,
    String? operationType,
    bool adminView = false,
  }) {
    return _firestore
        .collection('properties')
        .snapshots()
        .asyncMap((snapshot) async {
      final bannedSnapshot = await _firestore
          .collection('users')
          .where('banned', isEqualTo: true)
          .get();
      final bannedIds = bannedSnapshot.docs.map((doc) => doc.id).toSet();

      var properties = snapshot.docs
          .map(
            (doc) => Property.fromFirestore(
              Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>),
              doc.id,
            ),
          )
          .toList();

      if (!adminView) {
        properties = properties
            .where((p) => !bannedIds.contains(p.ownerId))
            .where((p) => p.status == 'approved')
            .toList();
      }

      if (type != null && type.isNotEmpty) {
        properties = properties.where((p) => p.type == type).toList();
      }
      if (operationType != null && operationType.isNotEmpty) {
        properties = properties.where((p) => p.operationType == operationType).toList();
      }

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
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['isFeatured'] == true;
          })
          .map(
            (doc) => Property.fromFirestore(
              Map<String, dynamic>.from(
                doc.data() as Map<dynamic, dynamic>,
              ),
              doc.id,
            ),
          )
          .toList();
    });
  }

  Future<void> createProperty(Property property) async {
    final docRef = await _firestore.collection('properties').add({
      ...property.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _notifyAdminsNewProperty(property, docRef.id);
  }

  Future<void> _notifyAdminsNewProperty(Property property, String propertyId) async {
    try {
      final allUsersSnapshot = await _firestore.collection('users').get();
      final admins = allUsersSnapshot.docs.where((doc) {
        final role = doc.data()['role']?.toString() ?? '';
        return role == 'admin';
      });
      for (final adminDoc in admins) {
        await createNotification(
          userId: adminDoc.id,
          type: 'property',
          title: 'عقار جديد بحاجة للموافقة',
          message: 'تم إضافة عقار جديد: ${property.title} - بحاجة للموافقة',
          targetId: propertyId,
          senderId: property.ownerId,
        );
      }
    } catch (_) {}
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

  Future<DocumentSnapshot> getUserDoc(String uid) async {
    return _firestore.collection('users').doc(uid).get();
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
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('users').doc(uid));

    final props = await _firestore.collection('properties').where('ownerId', isEqualTo: uid).get();
    for (final doc in props.docs) {
      batch.delete(doc.reference);
    }

    final convs = await _firestore.collection('conversations')
      .where('ownerId', isEqualTo: uid).get();
    final convs2 = await _firestore.collection('conversations')
      .where('interestedUserId', isEqualTo: uid).get();
    final allConvIds = {...convs.docs.map((d) => d.id), ...convs2.docs.map((d) => d.id)};
    for (final convId in allConvIds) {
      final msgs = await _firestore.collection('conversations').doc(convId).collection('messages').get();
      for (final msg in msgs.docs) {
        batch.delete(msg.reference);
      }
      batch.delete(_firestore.collection('conversations').doc(convId));
    }

    final reports = await _firestore.collection('reports').where('reportedBy', isEqualTo: uid).get();
    for (final doc in reports.docs) {
      batch.delete(doc.reference);
    }

    final notifications = await _firestore.collection('notifications').where('userId', isEqualTo: uid).get();
    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    final users = await _firestore.collection('users').get();
    for (final doc in users.docs) {
      final favs = (doc.data()['favorites'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
      final propsOwned = props.docs.map((d) => d.id).toList();
      final toRemove = favs.where((f) => propsOwned.contains(f)).toList();
      if (toRemove.isNotEmpty) {
        final updated = favs.where((f) => !toRemove.contains(f)).toList();
        batch.update(doc.reference, {'favorites': updated});
      }
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
        final data = doc.data();
        return AppUser.fromFirestore(Map<String, dynamic>.from(data), doc.id);
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

  Future<void> createDirectConversation(
    String convId,
    String user1Id,
    String user1Name,
    String user2Id,
    String user2Name,
  ) async {
    await _firestore.collection('conversations').doc(convId).set({
      'propertyId': '',
      'propertyTitle': 'محادثة مباشرة',
      'ownerId': user1Id,
      'ownerName': user1Name,
      'interestedUserId': user2Id,
      'interestedUserName': user2Name,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': 0,
    });
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
    final controller = StreamController<List<Conversation>>.broadcast();

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
        final aTime = a.lastMessageTime;
        final bTime = b.lastMessageTime;
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

  Stream<int> streamUnreadConversationCount(String userId) {
    if (userId.isEmpty) return Stream.value(0);
    final controller = StreamController<int>.broadcast();
    int lastInterested = 0;
    int lastOwner = 0;

    void emit() {
      controller.add(lastInterested + lastOwner);
    }

    final sub1 = _firestore
        .collection('conversations')
        .where('interestedUserId', isEqualTo: userId)
        .snapshots()
        .listen((s) {
      lastInterested = 0;
      for (final doc in s.docs) {
        final data = doc.data() as Map<String, dynamic>;
        lastInterested += (data['unreadCount'] as num?)?.toInt() ?? 0;
      }
      emit();
    });

    final sub2 = _firestore
        .collection('conversations')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .listen((s) {
      lastOwner = 0;
      for (final doc in s.docs) {
        final data = doc.data() as Map<String, dynamic>;
        lastOwner += (data['unreadCount'] as num?)?.toInt() ?? 0;
      }
      emit();
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
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

    _notifyAdminsReport(propertyId, reportedBy, reason);
  }

  Future<void> _notifyAdminsReport(String propertyId, String reportedBy, String reason) async {
    try {
      final propDoc = await _firestore.collection('properties').doc(propertyId).get();
      final propData = propDoc.data();
      final propTitle = propData?['title']?.toString() ?? 'غير معروف';
      final propOwner = propData?['ownerName']?.toString() ?? 'غير معروف';
      final propPrice = (propData?['price'] as num?)?.toDouble() ?? 0;
      final propType = propData?['type']?.toString() ?? '';
      final reporterDoc = await _firestore.collection('users').doc(reportedBy).get();
      final reporterName = reporterDoc.data()?['fullName']?.toString() ?? 'مستخدم';

      final allUsersSnapshot = await _firestore.collection('users').get();
      final adminSnapshot = allUsersSnapshot.docs.where((doc) {
        final role = doc.data()['role']?.toString() ?? '';
        return role == 'admin' || role == 'moderator';
      });
      for (final adminDoc in adminSnapshot) {
        await createNotification(
          userId: adminDoc.id,
          type: 'system',
          title: 'بلاغ جديد عن عقار',
          message: 'تم الإبلاغ عن "$propTitle" ($propType) بقيمة $propPrice ل.س - المالك: $propOwner - المبلغ: $reporterName - السبب: $reason',
          targetId: propertyId,
          senderId: reportedBy,
        );
      }
    } catch (_) {}
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

  Future<DocumentSnapshot?> getConversationDoc(String convId) async {
    try {
      return await _firestore.collection('conversations').doc(convId).get();
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAdminId() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      final allUsers = await _firestore.collection('users').limit(1).get();
      return allUsers.docs.isNotEmpty ? allUsers.docs.first.id : null;
    } catch (_) {
      return null;
    }
  }

  Stream<DocumentSnapshot> streamUserFavorites(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<void> notifyAdminsNewProperty(Property property) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      for (final adminDoc in snapshot.docs) {
        await createNotification(
          userId: adminDoc.id,
          type: 'property',
          title: 'عقار جديد بحاجة للموافقة',
          message: 'تم إضافة عقار جديد: ${property.title} - بحاجة للموافقة',
          targetId: property.id,
          senderId: property.ownerId,
        );
      }
    } catch (_) {}
  }

  Stream<QuerySnapshot> streamUserProperties(String uid) {
    return _firestore
        .collection('properties')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> requestVisit({
    required String propertyId,
    required String propertyTitle,
    required String ownerId,
    required String requesterId,
    required String requesterName,
    required String requesterPhone,
    required DateTime preferredDate,
    required String message,
  }) async {
    await _firestore.collection('visit_requests').add({
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'ownerId': ownerId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'preferredDate': Timestamp.fromDate(preferredDate),
      'message': message,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await createNotification(
      userId: ownerId,
      type: 'visit_request',
      title: 'طلب معاينة جديد',
      message: 'لديك طلب معاينة من $requesterName',
      targetId: propertyId,
      senderId: requesterId,
    );
  }

  Stream<List<Map<String, dynamic>>> streamVisitRequests(String userId) {
    return _firestore
        .collection('visit_requests')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<Property?> getPropertyById(String propertyId) async {
    try {
      final doc = await _firestore.collection('properties').doc(propertyId).get();
      if (!doc.exists) return null;
      return Property.fromFirestore(Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>), doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
