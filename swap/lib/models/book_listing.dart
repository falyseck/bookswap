import 'package:cloud_firestore/cloud_firestore.dart';

enum BookCondition { newItem, likeNew, good, used }

BookCondition conditionFromString(String value) {
  switch (value) {
    case 'new':
      return BookCondition.newItem;
    case 'like_new':
      return BookCondition.likeNew;
    case 'good':
      return BookCondition.good;
    default:
      return BookCondition.used;
  }
}

String conditionToString(BookCondition c) {
  switch (c) {
    case BookCondition.newItem:
      return 'new';
    case BookCondition.likeNew:
      return 'like_new';
    case BookCondition.good:
      return 'good';
    case BookCondition.used:
      return 'used';
  }
}

class BookListing {
  final String id;
  final String ownerId;
  final String title;
  final String author;
  final BookCondition condition;
  final String? imageUrl;
  final bool pending; // true when part of a pending swap
  final DateTime createdAt;

  BookListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.author,
    required this.condition,
    required this.imageUrl,
    required this.pending,
    required this.createdAt,
  });

  factory BookListing.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BookListing(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: conditionFromString((data['condition'] ?? 'used') as String),
      imageUrl: data['imageUrl'] as String?,
      pending: data['pending'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'title': title,
        'author': author,
        'condition': conditionToString(condition),
        'imageUrl': imageUrl,
        'pending': pending,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  BookListing copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? author,
    BookCondition? condition,
    String? imageUrl,
    bool? pending,
    DateTime? createdAt,
  }) {
    return BookListing(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      pending: pending ?? this.pending,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


