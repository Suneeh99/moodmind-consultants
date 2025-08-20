// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore chat service for 1:1 user <-> consultant messaging.
///
/// Firestore structure:
///   chats/{chatId}
///     - userId                (String)  // end-user
///     - consultantId          (String)
///     - participants          (List<String>) [userId, consultantId]
///     - lastMessage           (String)
///     - lastMessageTime       (Timestamp)
///     - lastSenderId          (String)
///     - unreadCountForUser        (int)
///     - unreadCountForConsultant  (int)
///     - lastMessageSeenBy     (List<String>)
///     - createdAt             (Timestamp)
///     - updatedAt             (Timestamp)
///
///   chats/{chatId}/messages/{messageId}
///     - chatId          (String)
///     - senderId        (String)
///     - text            (String)
///     - createdAt       (Timestamp)
///     - seenBy          (List<String>)
///     - delivered       (bool)
///
/// Notes:
/// - You may need to create composite indexes the first time Firestore
///   prompts for them (e.g., where + orderBy queries).
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  // ---------------------------------------------------------------------------
  // Chat creation / retrieval
  // ---------------------------------------------------------------------------

  /// Ensures a single chat exists between the given user and consultant.
  /// Returns the chatId.
  Future<String> ensureChat({
    required String userId,
    required String consultantId,
  }) async {
    final existing = await _chats
        .where('userId', isEqualTo: userId)
        .where('consultantId', isEqualTo: consultantId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final ref = await _chats.add({
      'userId': userId,
      'consultantId': consultantId,
      'participants': [userId, consultantId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': null,
      'unreadCountForUser': 0,
      'unreadCountForConsultant': 0,
      'lastMessageSeenBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  /// Optionally fetch a chat doc once.
  Future<DocumentSnapshot<Map<String, dynamic>>> getChat(String chatId) {
    return _chats.doc(chatId).get();
  }

  // ---------------------------------------------------------------------------
  // Streams (lists & messages)
  // ---------------------------------------------------------------------------

  /// Streams chats for a specific end-user, ordered by recent activity.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserChats(String userId) {
    return _chats
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Streams chats for a specific consultant, ordered by recent activity.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamConsultantChats(
    String consultantId,
  ) {
    return _chats
        .where('consultantId', isEqualTo: consultantId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Streams messages within a chat (oldest -> newest).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String chatId) {
    return _messages(
      chatId,
    ).orderBy('createdAt', descending: false).snapshots();
  }

  // ---------------------------------------------------------------------------
  // Sending messages
  // ---------------------------------------------------------------------------

  /// Sends a message and updates the chat envelope atomically.
  ///
  /// The other party’s unread counter is incremented. The sender is recorded
  /// in `lastMessageSeenBy` (acts like a "double check" for sender).
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final chatRef = _chats.doc(chatId);
    final msgRef = _messages(chatId).doc();

    await _db.runTransaction((txn) async {
      // Load chat envelope for IDs & counters
      final chatSnap = await txn.get(chatRef);
      if (!chatSnap.exists) {
        throw StateError('Chat $chatId does not exist');
      }
      final envelope = chatSnap.data() as Map<String, dynamic>;

      final userId = envelope['userId'] as String? ?? '';
      final consultantId = envelope['consultantId'] as String? ?? '';
      final isSenderUser = senderId == userId;

      // 1) Create message
      txn.set(msgRef, {
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'seenBy': [senderId], // sender has seen their own message
        'delivered': true,
      });

      // 2) Update chat envelope
      txn.update(chatRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageSeenBy': [senderId],
        // increment the other party’s unread
        if (isSenderUser)
          'unreadCountForConsultant': FieldValue.increment(1)
        else
          'unreadCountForUser': FieldValue.increment(1),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Seen / unread
  // ---------------------------------------------------------------------------

  /// Marks chat as seen for the end-user:
  /// - sets unreadCountForUser to 0
  /// - adds userId to lastMessageSeenBy
  /// - marks recent messages as seenBy userId (best-effort)
  Future<void> markChatSeenForUser({
    required String chatId,
    required String userId,
  }) async {
    final chatRef = _chats.doc(chatId);

    await chatRef.update({
      'unreadCountForUser': 0,
      'lastMessageSeenBy': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Best-effort: mark last N messages as seen
    final recent = await _messages(
      chatId,
    ).orderBy('createdAt', descending: true).limit(50).get();

    final batch = _db.batch();
    for (final d in recent.docs) {
      final seenBy = List<String>.from(d.data()['seenBy'] ?? const <String>[]);
      if (!seenBy.contains(userId)) {
        batch.update(d.reference, {
          'seenBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
    await batch.commit();
  }

  /// Marks chat as seen for the consultant:
  /// - sets unreadCountForConsultant to 0
  /// - adds consultantId to lastMessageSeenBy
  /// - marks recent messages as seenBy consultantId (best-effort)
  Future<void> markChatSeenForConsultant({
    required String chatId,
    required String consultantId,
  }) async {
    final chatRef = _chats.doc(chatId);

    await chatRef.update({
      'unreadCountForConsultant': 0,
      'lastMessageSeenBy': FieldValue.arrayUnion([consultantId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final recent = await _messages(
      chatId,
    ).orderBy('createdAt', descending: true).limit(50).get();

    final batch = _db.batch();
    for (final d in recent.docs) {
      final seenBy = List<String>.from(d.data()['seenBy'] ?? const <String>[]);
      if (!seenBy.contains(consultantId)) {
        batch.update(d.reference, {
          'seenBy': FieldValue.arrayUnion([consultantId]),
        });
      }
    }
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // Convenience helpers
  // ---------------------------------------------------------------------------

  /// User starts a chat (if needed) and sends the first message.
  Future<String> startChatAndSendFromUser({
    required String userId,
    required String consultantId,
    required String text,
  }) async {
    final chatId = await ensureChat(userId: userId, consultantId: consultantId);
    await sendMessage(chatId: chatId, senderId: userId, text: text);
    return chatId;
  }

  /// Consultant starts a chat (if needed) and sends the first message.
  Future<String> startChatAndSendFromConsultant({
    required String userId,
    required String consultantId,
    required String text,
  }) async {
    final chatId = await ensureChat(userId: userId, consultantId: consultantId);
    await sendMessage(chatId: chatId, senderId: consultantId, text: text);
    return chatId;
  }
}
