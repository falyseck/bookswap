import 'package:flutter/material.dart';

import 'tabs/browse_listings_page.dart';
import 'tabs/my_listings_page.dart';
import 'tabs/chats_page.dart';
import 'tabs/settings_page.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _index = 0;

  final _pages = const [
    BrowseListingsPage(),
    MyListingsPage(),
    ChatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1F),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, 
                color: _index == 0 ? const Color(0xFFFFD700) : Colors.grey),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_books_outlined,
                color: _index == 1 ? const Color(0xFFFFD700) : Colors.grey),
              label: 'My Listings',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline,
                color: _index == 2 ? const Color(0xFFFFD700) : Colors.grey),
              label: 'Chats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline,
                color: _index == 3 ? const Color(0xFFFFD700) : Colors.grey),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}


