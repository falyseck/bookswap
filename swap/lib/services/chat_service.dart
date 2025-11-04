import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat.dart';

class ChatService {
  ChatService(this._db);

  final FirebaseFirestore _db;

  static ChatService get instance => ChatService(FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> get _threads => _db.collection('threads');

  Stream<List<ChatThread>> streamMyThreads(String userId) {
    return _threads.where('participantIds', arrayContains: userId).orderBy('updatedAt', descending: true).snapshots().map((s) => s.docs.map(ChatThread.fromDoc).toList());
  }

  Stream<List<ChatMessage>> streamMessages(String threadId) {
    return _threads
        .doc(threadId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<String> createThreadIfNotExists(String userA, String userB) async {
    // Normalize participant ordering to make lookups deterministic
    final participants = <String>[userA, userB]..sort();

    final existing = await _threads.where('participantIds', arrayContains: userA).get();
    for (final doc in existing.docs) {
      final ids = List<String>.from(doc.data()['participantIds'] ?? const []);
      if (ids.length == 2) {
        final other = <String>[ids[0], ids[1]]..sort();
        if (participants[0] == other[0] && participants[1] == other[1]) {
          return doc.id;
        }
      }
    }

    final ref = await _threads.add({
      'participantIds': participants,
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> sendMessage({required String threadId, required String text}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not authenticated');
    final msgRef = _threads.doc(threadId).collection('messages').doc();
    final batch = _db.batch();
    batch.set(msgRef, {
      'senderId': uid,
      'text': text,
      'sentAt': FieldValue.serverTimestamp(),
    });
    batch.update(_threads.doc(threadId), {
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}


