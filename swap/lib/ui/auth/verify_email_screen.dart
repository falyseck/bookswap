import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sent = false;
  bool _checking = false;
  String? _status;

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _status = null);
    await user.sendEmailVerification();
    setState(() => _sent = true);
  }

  Future<void> _refresh() async {
    setState(() => _checking = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    setState(() {
      _checking = false;
      _status = refreshed?.emailVerified == true ? 'Email verified!' : 'Not verified yet';
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('A verification link has to be sent to your email. Please verify to continue.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _send, child: Text(_sent ? 'Resend verification email' : 'Send verification email')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _checking ? null : _refresh, child: _checking ? const CircularProgressIndicator() : const Text('I have verified')),
            const SizedBox(height: 8),
            if (_status != null) Text(_status!, textAlign: TextAlign.center),
            const Spacer(),
            TextButton(onPressed: _logout, child: const Text('Sign out')),
          ],
        ),
      ),
    );
  }
}


