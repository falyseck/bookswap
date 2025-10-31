import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/book_listing.dart';
import '../../services/firestore_service.dart';
import '../../models/swap_offer.dart';
import '../listings/edit_listing_page.dart';

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
                  // My Offers
                  StreamBuilder<List<SwapOffer>>(
                    stream: svc.streamMyOffers(uid),
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
                          return ListTile(
                            title: Text('Offer for listing ${o.listingId}'),
                            subtitle: Text('Status: ${_statusLabel(o.status)}'),
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


