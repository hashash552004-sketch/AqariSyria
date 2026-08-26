import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalChatService {
  static const _conversationsKey = 'local_conversations';
  static const _msgsPrefix = 'local_msgs_';

  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_conversationsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list
        .where((c) => c['ownerId'] == userId || c['interestedUserId'] == userId)
        .toList()
      ..sort((a, b) {
        final ta = DateTime.tryParse(a['lastMessageTime'] ?? '') ?? DateTime(0);
        final tb = DateTime.tryParse(b['lastMessageTime'] ?? '') ?? DateTime(0);
        return tb.compareTo(ta);
      });
  }

  Future<String> createConversation({
    required String propertyId,
    required String propertyTitle,
    required String ownerId,
    required String ownerName,
    required String interestedUserId,
    required String interestedUserName,
  }) async {
    final convId = '${propertyId}_$interestedUserId';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_conversationsKey);
    final list = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    if (list.any((c) => c['id'] == convId)) return convId;

    list.add({
      'id': convId,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'interestedUserId': interestedUserId,
      'interestedUserName': interestedUserName,
      'lastMessage': '',
      'lastMessageTime': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_conversationsKey, jsonEncode(list));
    return convId;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final key = '$_msgsPrefix$conversationId';
    final raw = prefs.getString(key);
    final msgs = raw != null
        ? (jsonDecode(raw) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    msgs.add({
      'id': '${DateTime.now().millisecondsSinceEpoch}_${msgs.length}',
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'type': 'text',
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': true,
    });
    await prefs.setString(key, jsonEncode(msgs));

    final rawC = prefs.getString(_conversationsKey);
    if (rawC != null) {
      final list = (jsonDecode(rawC) as List).cast<Map<String, dynamic>>();
      for (final c in list) {
        if (c['id'] == conversationId) {
          c['lastMessage'] = message;
          c['lastMessageTime'] = DateTime.now().toIso8601String();
          break;
        }
      }
      await prefs.setString(_conversationsKey, jsonEncode(list));
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId, {
    int limit = 200,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_msgsPrefix$conversationId');
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    list.sort((a, b) {
      final ta = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(0);
      final tb = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(0);
      return ta.compareTo(tb);
    });
    if (list.length > limit) return list.sublist(list.length - limit);
    return list;
  }

  Future<void> deleteConversation(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_msgsPrefix$conversationId');
    final raw = prefs.getString(_conversationsKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      list.removeWhere((c) => c['id'] == conversationId);
      await prefs.setString(_conversationsKey, jsonEncode(list));
    }
  }
}
