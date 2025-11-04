import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/book_listing.dart';
import '../../services/firestore_service.dart';
import '../../models/swap_offer.dart';
import '../../services/chat_service.dart';
import '../listings/edit_listing_page.dart';
import '../threads/chat_screen.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final svc = FirestoreService.instance;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Listings'),
          bottom: const TabBar(tabs: [Tab(text: 'Listings'), Tab(text: 'My Offers')]),
        ),
        body: uid == null
            ? const Center(child: Text('Not signed in'))
            : TabBarView(
                children: [
                  // Listings
                  StreamBuilder<List<BookListing>>(
                    stream: svc.streamMyListings(uid),
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
                          return ListTile(
                            title: Text(l.title),
                            subtitle: Text('${l.author} • ${_conditionLabel(l.condition)}${l.pending ? ' • Pending' : ''}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditListingPage(listing: l)));
                                } else if (value == 'delete') {
                                  await svc.deleteListing(l.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  // My Offers - Shows all offers (sent and received)
                  StreamBuilder<List<SwapOffer>>(
                    stream: svc.streamAllMyOffers(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final offers = snapshot.data ?? [];
                      if (offers.isEmpty) return const Center(child: Text('No offers yet'));
                      return ListView.separated(
                        itemCount: offers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final o = offers[index];
                          final isRecipient = o.recipientId == uid;
                          final isSender = o.senderId == uid;
                          return FutureBuilder<Map<String, BookListing?>>(
                            future: Future.wait([
                              svc.getListing(o.listingId),
                              svc.getListing(o.offeredBookId),
                            ]).then((list) => {
                              'wantedBook': list[0],
                              'offeredBook': list[1],
                            }),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const ListTile(
                                  title: Text('Loading...'),
                                  leading: CircularProgressIndicator(),
                                );
                              }
                              final wantedBook = snapshot.data?['wantedBook'];
                              final offeredBook = snapshot.data?['offeredBook'];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  title: Text(isRecipient
                                      ? '${offeredBook?.title ?? 'Unknown'} → ${wantedBook?.title ?? 'Unknown'}'
                                      : '${offeredBook?.title ?? 'Unknown'} → ${wantedBook?.title ?? 'Unknown'}'),
                                  subtitle: Text(isRecipient
                                      ? 'They want your "${wantedBook?.title ?? 'Unknown'}" and offer "${offeredBook?.title ?? 'Unknown'}"'
                                      : 'You want "${wantedBook?.title ?? 'Unknown'}" and offer "${offeredBook?.title ?? 'Unknown'}"'),
                                  isThreeLine: true,
                                  trailing: o.status == SwapStatus.pending
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline),
                                              tooltip: 'Chat',
                                              onPressed: () async {
                                                final threadId = await ChatService.instance.createThreadIfNotExists(o.senderId, o.recipientId);
                                                if (context.mounted) {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(builder: (_) => ChatScreen(threadId: threadId)),
                                                  );
                                                }
                                              },
                                            ),
                                            if (isRecipient) ...[
                                              TextButton(
                                                onPressed: () async {
                                                  await svc.updateSwapStatusWithBooks(o.id, SwapStatus.rejected, o.listingId, o.offeredBookId);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Swap rejected. Books are now available.')),
                                                    );
                                                  }
                                                },
                                                child: const Text('Reject'),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  await svc.updateSwapStatusWithBooks(o.id, SwapStatus.accepted, o.listingId, o.offeredBookId);
                                                  // Books remain pending after acceptance (committed to swap)
                                                  // Create chat thread
                                                  await ChatService.instance.createThreadIfNotExists(o.senderId, o.recipientId);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Swap accepted! Chat available.')),
                                                    );
                                                  }
                                                },
                                                child: const Text('Accept'),
                                              ),
                                            ] else if (isSender) ...[
                                              TextButton(
                                                onPressed: () async {
                                                  await svc.updateSwapStatusWithBooks(o.id, SwapStatus.cancelled, o.listingId, o.offeredBookId);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Swap cancelled. Books are now available.')),
                                                    );
                                                  }
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                            ],
                                          ],
                                        )
                                      : Text(_statusLabel(o.status)),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditListingPage())),
          child: const Icon(Icons.add),
        ),
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

String _statusLabel(SwapStatus s) {
  switch (s) {
    case SwapStatus.pending:
      return 'Pending';
    case SwapStatus.accepted:
      return 'Accepted';
    case SwapStatus.rejected:
      return 'Rejected';
    case SwapStatus.cancelled:
      return 'Cancelled';
  }
}


