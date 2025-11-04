import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/chat_service.dart';
import '../../models/chat.dart';
import '../threads/chat_screen.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    final chat = ChatService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<List<ChatThread>>(
        stream: chat.streamMyThreads(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final threads = snapshot.data ?? [];
          if (threads.isEmpty) return const Center(child: Text('No chats yet'));
          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = threads[index];
              return ListTile(
                title: Text('Chat ${t.id.substring(0, 6)}'),
                subtitle: Text(t.lastMessage.isEmpty ? 'No messages' : t.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(threadId: t.id))),
              );
            },
          );
        },
      ),
    );
  }
}


