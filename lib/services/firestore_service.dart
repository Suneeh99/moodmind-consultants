import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> myChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> chatMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> markChatSeenForConsultant({
    required String chatId,
    required String consultantId,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    // Get all messages not seen by consultant
    final unseenMessages = await messagesRef
        .where('isConsultant', isEqualTo: false)
        .where(
          'seenBy',
          whereNotIn: [
            [consultantId],
          ],
        )
        .get();

    // Update each message to mark as seen by consultant
    final batch = _db.batch();
    for (final doc in unseenMessages.docs) {
      batch.update(doc.reference, {
        'seenBy': FieldValue.arrayUnion([consultantId]),
      });
    }

    // Also update the chat's consultant seen timestamp
    batch.update(chatRef, {'consultantSeen': FieldValue.serverTimestamp()});

    await batch.commit();
  }

  Future<void> markChatSeenForPatient({
    required String chatId,
    required String patientId,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    // Get all messages not seen by patient
    final unseenMessages = await messagesRef
        .where('isConsultant', isEqualTo: true)
        .where(
          'seenBy',
          whereNotIn: [
            [patientId],
          ],
        )
        .get();

    // Update each message to mark as seen by patient
    final batch = _db.batch();
    for (final doc in unseenMessages.docs) {
      batch.update(doc.reference, {
        'seenBy': FieldValue.arrayUnion([patientId]),
      });
    }

    // Also update the chat's patient seen timestamp
    batch.update(chatRef, {'patientSeen': FieldValue.serverTimestamp()});

    await batch.commit();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    required bool isConsultant,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();
    final now = FieldValue.serverTimestamp();

    // Create the message data
    final messageData = {
      'senderId': senderId,
      'text': text,
      'createdAt': now,
      'isConsultant': isConsultant,
      'seenBy': FieldValue.arrayUnion([senderId]),
    };

    // Update the chat document
    final chatUpdate = {
      'lastMessage': text,
      'lastMessageTime': now,
      'updatedAt': now,
      if (isConsultant) 'consultantSeen': now,
      if (!isConsultant) 'patientSeen': now,
    };

    // Run both operations in a batch to ensure consistency
    final batch = _db.batch();
    batch.set(msgRef, messageData);
    batch.set(chatRef, chatUpdate, SetOptions(merge: true));

    await batch.commit();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> userDoc(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> moodsForPatient(
    String patientId,
  ) {
    return _db
        .collection('patients')
        .doc(patientId)
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
