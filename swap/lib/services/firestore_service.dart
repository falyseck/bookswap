import 'dart:async';

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
    // Avoid composite index requirement by not ordering here
    return _listings.where('ownerId', isEqualTo: userId).snapshots().map((s) => s.docs.map(BookListing.fromDoc).toList());
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

  // Combined stream of all offers where user is either sender or recipient
  Stream<List<SwapOffer>> streamAllMyOffers(String userId) {
    // Combine both streams and merge the results
    final sentStream = streamMyOffers(userId);
    final receivedStream = streamIncomingOffers(userId);
    
    final controller = StreamController<List<SwapOffer>>();
    final allOffers = <String, SwapOffer>{};
    
    void update() {
      final sorted = allOffers.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(sorted);
    }
    
    sentStream.listen((sent) {
      for (final offer in sent) {
        allOffers[offer.id] = offer;
      }
      update();
    });
    
    receivedStream.listen((received) {
      for (final offer in received) {
        allOffers[offer.id] = offer;
      }
      update();
    });
    
    return controller.stream;
  }

  Future<String> createSwap({
    required String listingId,
    required String offeredBookId,
    required String recipientId,
  }) async {
    final senderId = FirebaseAuth.instance.currentUser?.uid;
    if (senderId == null) throw StateError('Not authenticated');
    final batch = _db.batch();

    final swapRef = _swaps.doc();
    batch.set(swapRef, {
      'listingId': listingId,
      'offeredBookId': offeredBookId,
      'senderId': senderId,
      'recipientId': recipientId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Mark both books as pending
    final listingRef = _listings.doc(listingId);
    batch.update(listingRef, {'pending': true});
    final offeredRef = _listings.doc(offeredBookId);
    batch.update(offeredRef, {'pending': true});

    await batch.commit();
    return swapRef.id;
  }

  Future<BookListing?> getListing(String id) async {
    final doc = await _listings.doc(id).get();
    if (!doc.exists) return null;
    return BookListing.fromDoc(doc);
  }

  Future<void> updateSwapStatus(String swapId, SwapStatus status) async {
    await _swaps.doc(swapId).update({'status': swapStatusToString(status)});
  }

  Future<void> setListingPending(String listingId, bool pending) async {
    await _listings.doc(listingId).update({'pending': pending});
  }

  // Update swap status and handle book pending status atomically
  Future<void> updateSwapStatusWithBooks(String swapId, SwapStatus status, String listingId, String offeredBookId) async {
    final batch = _db.batch();
    
    // Update swap status
    batch.update(_swaps.doc(swapId), {'status': swapStatusToString(status)});
    
    // If rejected or cancelled, free both books
    if (status == SwapStatus.rejected || status == SwapStatus.cancelled) {
      batch.update(_listings.doc(listingId), {'pending': false});
      batch.update(_listings.doc(offeredBookId), {'pending': false});
    }
    // If accepted, books remain pending (committed to swap)
    
    await batch.commit();
  }
}


