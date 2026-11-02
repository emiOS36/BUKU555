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
      // Show this message on the page underneath the closed form.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved')),
      );

      // Reload in case the Transactions tab is currently selected.
      _homeScreenKey.currentState?.reloadRecentTransactions();
      _transactionScreenKey.currentState?.reload();
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Index 1 is the Transactions tab.
    if (index == 1) {
      _transactionScreenKey.currentState?.reload();
    }
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
