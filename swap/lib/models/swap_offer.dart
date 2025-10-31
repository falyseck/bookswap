import 'package:cloud_firestore/cloud_firestore.dart';

enum SwapStatus { pending, accepted, rejected, cancelled }

SwapStatus swapStatusFromString(String value) {
  switch (value) {
    case 'accepted':
      return SwapStatus.accepted;
    case 'rejected':
      return SwapStatus.rejected;
    case 'cancelled':
      return SwapStatus.cancelled;
    default:
      return SwapStatus.pending;
  }
}

String swapStatusToString(SwapStatus s) {
  switch (s) {
    case SwapStatus.pending:
      return 'pending';
    case SwapStatus.accepted:
      return 'accepted';
    case SwapStatus.rejected:
      return 'rejected';
    case SwapStatus.cancelled:
      return 'cancelled';
  }
}

class SwapOffer {
  final String id;
  final String listingId;
  final String senderId;
  final String recipientId;
  final SwapStatus status;
  final DateTime createdAt;

  SwapOffer({
    required this.id,
    required this.listingId,
    required this.senderId,
    required this.recipientId,
    required this.status,
    required this.createdAt,
  });

  factory SwapOffer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SwapOffer(
      id: doc.id,
      listingId: data['listingId'] ?? '',
      senderId: data['senderId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      status: swapStatusFromString((data['status'] ?? 'pending') as String),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'listingId': listingId,
        'senderId': senderId,
        'recipientId': recipientId,
        'status': swapStatusToString(status),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}


