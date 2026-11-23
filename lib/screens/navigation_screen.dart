import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:buku555/screens/add_transaction_screen.dart';
import 'package:buku555/screens/home_screen.dart';
import 'package:buku555/screens/settings_screen.dart';
import 'package:buku555/screens/statistics_screen.dart';
import 'package:buku555/screens/transaction_screen.dart';

class _LowerCenterDockedFabLocation extends FloatingActionButtonLocation {
  const _LowerCenterDockedFabLocation(this.offsetY);

  final double offsetY;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final centerDocked = FloatingActionButtonLocation.centerDocked.getOffset(
      geometry,
    );

    return centerDocked + Offset(0, offsetY);
  }
}

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

  final GlobalKey<StatisticsScreenState> _statisticsScreenKey =
      GlobalKey<StatisticsScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeScreenKey),
    TransactionScreen(key: _transactionScreenKey),
    StatisticsScreen(key: _statisticsScreenKey),
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

    // Run after AddTransactionScreen has closed.
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

    if (!mounted) return;

    if (saved == true) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Transaction added successfully'),
          ),
        );
      _homeScreenKey.currentState?.reloadRecentTransactions();
      _transactionScreenKey.currentState?.reload();
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _homeScreenKey.currentState?.reloadRecentTransactions();
    } else if (index == 1) {
      _transactionScreenKey.currentState?.reload();
    } else if (index == 2) {
      _statisticsScreenKey.currentState?.reload();
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(24),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: isSelected
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          for (var index = 0; index < _screens.length; index++)
            Positioned.fill(
              child: AnimatedSlide(
                offset: index == _selectedIndex
                    ? Offset.zero
                    : const Offset(0, 0.05),
                duration: const Duration(milliseconds: 1220),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: index == _selectedIndex ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: IgnorePointer(
                    ignoring: index != _selectedIndex,
                    child: ExcludeSemantics(
                      excluding: index != _selectedIndex,
                      child: TickerMode(
                        enabled: index == _selectedIndex,
                        child: _screens[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: SizedBox.square(
        dimension: 46,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          foregroundColor: Colors.black54,
          backgroundColor: Colors.teal[100],
          onPressed: _openAddTransactionScreen,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: const _LowerCenterDockedFabLocation(35),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_outlined,
                selectedIcon: Icons.receipt,
                label: 'Transactions',
              ),
              const SizedBox(width: 64),
              _buildNavItem(
                index: 2,
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'Statistics',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
