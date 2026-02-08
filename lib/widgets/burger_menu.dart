import 'package:flutter/material.dart';

class BurgerMenu extends StatelessWidget {
  final List<Widget> menuItems;
  const BurgerMenu({super.key, required this.menuItems});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => IconButton(
        icon: Icon(
          Icons.menu,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: () {
          Scaffold.of(context).openEndDrawer();
        },
      ),
    );
  }
}

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {},
            ),
            ListTile(
              title: const Text('Bookings'),
              onTap: () {},
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('AirShero F'),
        actions: [
          BurgerMenu(menuItems: [
            ListTile(title: const Text('Home')),
            ListTile(title: const Text('Bookings')),
          ]),
        ],
      ),
      body: const Center(
        child: Text('Home content here'),
      ),
    );
  }
}