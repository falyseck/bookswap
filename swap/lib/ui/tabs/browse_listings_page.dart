import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/book_listing.dart';
import '../../services/firestore_service.dart';
import '../dialogs/select_book_dialog.dart';

class BrowseListingsPage extends StatelessWidget {
  const BrowseListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final svc = FirestoreService.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1F),
        title: const Text(
          'Browse Listings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<BookListing>>(
        stream: svc.streamAllListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No listings yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final l = items[index];
              final isMine = l.ownerId == uid;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: const Color(0xFF1A1F35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[800],
                        ),
                        child: const Icon(Icons.book, color: Colors.white54, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.author,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2F45),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _conditionLabel(l.condition),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                if (l.swapped) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Swapped',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ] else if (l.pending) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!isMine) ...[
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(120, 36),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: (l.pending || l.swapped)
                                    ? null
                                    : () async {
                                        if (uid == null) return;
                                        final myBooks =
                                            await svc.streamMyListings(uid).first;
                                        final available = myBooks
                                            .where((b) => !b.pending)
                                            .toList();

                                        if (!context.mounted) return;
                                        final selectedBook =
                                            await showSelectBookDialog(
                                                context, available);

                                        if (selectedBook == null) return;

                                        await svc.createSwap(
                                          listingId: l.id,
                                          offeredBookId: selectedBook.id,
                                          recipientId: l.ownerId,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('Swap requested')),
                                          );
                                        }
                                      },
                                child: const Text(
                                  'Swap',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _conditionLabel(BookCondition c) {
  switch (c) {
    case BookCondition.newItem:
      return 'New';
    case BookCondition.likeNew:
      return 'Like New';
    case BookCondition.good:
      return 'Good';
    case BookCondition.used:
      return 'Used';
  }
}
