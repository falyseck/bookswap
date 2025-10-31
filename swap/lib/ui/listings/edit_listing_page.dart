import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/book_listing.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class EditListingPage extends StatefulWidget {
  const EditListingPage({super.key, this.listing});

  final BookListing? listing;

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  BookCondition _condition = BookCondition.used;
  File? _imageFile;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final l = widget.listing;
    if (l != null) {
      _titleController.text = l.title;
      _authorController.text = l.author;
      _condition = l.condition;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (x != null) setState(() => _imageFile = File(x.path));
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final svc = FirestoreService.instance;
      if (widget.listing == null) {
        final newId = await svc.createListing(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          condition: _condition,
          imageUrl: null,
        );
        if (_imageFile != null) {
          final imageUrl = await StorageService.instance.uploadListingImage(listingId: newId, file: _imageFile!);
          await svc.updateListing(newId, {'imageUrl': imageUrl});
        }
      } else {
        String? imageUrl = widget.listing!.imageUrl;
        if (_imageFile != null) {
          imageUrl = await StorageService.instance.uploadListingImage(listingId: widget.listing!.id, file: _imageFile!);
        }
        await svc.updateListing(widget.listing!.id, {
          'title': _titleController.text.trim(),
          'author': _authorController.text.trim(),
          'condition': conditionToString(_condition),
          'imageUrl': imageUrl,
        });
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.listing == null ? 'New Listing' : 'Edit Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _authorController, decoration: const InputDecoration(labelText: 'Author')),
            const SizedBox(height: 12),
            DropdownButtonFormField<BookCondition>(
              value: _condition,
              items: const [
                DropdownMenuItem(value: BookCondition.newItem, child: Text('New')),
                DropdownMenuItem(value: BookCondition.likeNew, child: Text('Like New')),
                DropdownMenuItem(value: BookCondition.good, child: Text('Good')),
                DropdownMenuItem(value: BookCondition.used, child: Text('Used')),
              ],
              onChanged: (v) => setState(() => _condition = v ?? BookCondition.used),
              decoration: const InputDecoration(labelText: 'Condition'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Pick cover image')),
                const SizedBox(width: 12),
                if (_imageFile != null) const Text('Image selected') else if (widget.listing?.imageUrl != null) const Text('Existing image')
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Save')),
          ],
        ),
      ),
    );
  }
}


