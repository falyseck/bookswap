import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book_listing.dart';
import '../models/swap_offer.dart';

class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  static FirestoreService get instance => FirestoreService(FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>> get _listings => _db.collection('listings');
  CollectionReference<Map<String, dynamic>> get _swaps => _db.collection('swaps');

  // Listings
  Stream<List<BookListing>> streamAllListings() {
    return _listings.orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(BookListing.fromDoc).toList());
  }

  Stream<List<BookListing>> streamMyListings(String userId) {
    return _listings.where('ownerId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(BookListing.fromDoc).toList());
  }

  Future<String> createListing({
    required String title,
    required String author,
    required BookCondition condition,
    String? imageUrl,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not authenticated');
    final ref = await _listings.add({
      'ownerId': uid,
      'title': title,
      'author': author,
      'condition': conditionToString(condition),
      'imageUrl': imageUrl,
      'pending': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _listings.doc(id).update(data);
  }

  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
  }

  // Swaps
  Stream<List<SwapOffer>> streamMyOffers(String userId) {
    return _swaps.where('senderId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(SwapOffer.fromDoc).toList());
  }

  Stream<List<SwapOffer>> streamIncomingOffers(String userId) {
    return _swaps.where('recipientId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map(SwapOffer.fromDoc).toList());
  }

  Future<String> createSwap({
    required String listingId,
    required String recipientId,
  }) async {
    final senderId = FirebaseAuth.instance.currentUser?.uid;
    if (senderId == null) throw StateError('Not authenticated');
    final batch = _db.batch();

    final swapRef = _swaps.doc();
    batch.set(swapRef, {
      'listingId': listingId,
      'senderId': senderId,
      'recipientId': recipientId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final listingRef = _listings.doc(listingId);
    batch.update(listingRef, {'pending': true});

    await batch.commit();
    return swapRef.id;
  }

  Future<void> updateSwapStatus(String swapId, SwapStatus status) async {
    await _swaps.doc(swapId).update({'status': swapStatusToString(status)});
  }
}


