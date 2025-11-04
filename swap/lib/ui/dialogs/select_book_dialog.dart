import 'package:flutter/material.dart';

import '../../models/book_listing.dart';

Future<BookListing?> showSelectBookDialog(BuildContext context, List<BookListing> availableBooks) async {
  return await showDialog<BookListing?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Select a book to offer'),
      content: availableBooks.isEmpty
          ? const Text('You need to list at least one book before you can swap.')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableBooks.length,
                itemBuilder: (context, index) {
                  final book = availableBooks[index];
                  return ListTile(
                    title: Text(book.title),
                    subtitle: Text('${book.author} • ${_conditionLabel(book.condition)}'),
                    onTap: () => Navigator.of(context).pop(book),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
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

