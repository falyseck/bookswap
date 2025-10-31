import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  static StorageService get instance => StorageService(FirebaseStorage.instance);

  Future<String> uploadListingImage({required String listingId, required File file}) async {
    final ref = _storage.ref().child('listing_images').child('$listingId.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }
}


