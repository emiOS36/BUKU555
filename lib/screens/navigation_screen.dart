import 'dart:async';

import 'package:flutter/material.dart';

import 'package:buku555/screens/add_transaction_screen.dart';
import 'package:buku555/screens/home_screen.dart';
import 'package:buku555/screens/settings_screen.dart';
import 'package:buku555/screens/statistics_screen.dart';
import 'package:buku555/screens/transaction_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  OverlayEntry? _savedMessageEntry;
  Timer? _savedMessageTimer;

  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();

  final GlobalKey<TransactionScreenState> _transactionScreenKey =
      GlobalKey<TransactionScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeScreenKey),
    TransactionScreen(key: _transactionScreenKey),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  Future<void> _openAddTransactionScreen() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (context) => const AddTransactionScreen(),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      _showSavedMessage();
      _homeScreenKey.currentState?.reloadRecentTransactions();
      _transactionScreenKey.currentState?.reload();
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _transactionScreenKey.currentState?.reload();
    }
  }

  void _showSavedMessage() {
    _savedMessageTimer?.cancel();
    _savedMessageEntry?.remove();

    _savedMessageEntry = OverlayEntry(
      builder: (overlayContext) {
        final topInset = MediaQuery.paddingOf(overlayContext).top;

        return Positioned(
          top: topInset + kToolbarHeight + 8,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 45, 52, 54),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Transaction saved',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_savedMessageEntry!);

    _savedMessageTimer = Timer(const Duration(seconds: 3), () {
      _savedMessageEntry?.remove();
      _savedMessageEntry = null;
    });
  }

  @override
  void dispose() {
    _savedMessageTimer?.cancel();
    _savedMessageEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        foregroundColor: Colors.black54,
        backgroundColor: Colors.teal[100],
        onPressed: _openAddTransactionScreen,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined),
            selectedIcon: Icon(Icons.receipt),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
