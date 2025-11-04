import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// removed unused cloud_firestore import

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
      appBar: AppBar(title: const Text('Browse Listings')),
      body: StreamBuilder<List<BookListing>>(
        stream: svc.streamAllListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No listings yet'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final l = items[index];
              final isMine = l.ownerId == uid;
              return ListTile(
                title: Text(l.title),
                subtitle: Text('${l.author} • ${_conditionLabel(l.condition)}${l.pending ? ' • Pending' : ''}'),
                trailing: isMine
                    ? const SizedBox.shrink()
                    : ElevatedButton(
                        onPressed: l.pending
                            ? null
                            : () async {
                                if (uid == null) return;
                                // Get user's available books (not pending)
                                final myBooks = await svc.streamMyListings(uid).first;
                                final available = myBooks.where((b) => !b.pending).toList();
                                
                                if (!context.mounted) return;
                                final selectedBook = await showSelectBookDialog(context, available);
                                
                                if (selectedBook == null) return;
                                
                                await svc.createSwap(
                                  listingId: l.id,
                                  offeredBookId: selectedBook.id,
                                  recipientId: l.ownerId,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Swap requested')),
                                  );
                                }
                              },
                        child: const Text('Swap'),
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


