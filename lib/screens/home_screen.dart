import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/transaction.dart' as db_model;
import 'package:buku555/screens/reusable_card.dart';
import 'package:buku555/utils/money_formatter.dart';
import 'package:buku555/widgets/circle_icon.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<db_model.Transaction> _recentTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    reloadRecentTransactions();
  }

  // Reloads up to 10 recent transactions from SQLite.
  // NavigationScreen can call this after a transaction is saved.
  Future<void> reloadRecentTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await TransactionDatabase.instance.getRecent(
        limit: 10,
      );

      if (!mounted) return;

      setState(() {
        _recentTransactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load transactions: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    // These totals are still hard-coded, as they are in your current screen.
    final int income = 1050000;
    final int expenses = 500000;
    final int totalBalance = income - expenses;
    const String changeText = '+12% from last month';

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buku555',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              'Track today. A better tomorrow.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: screenSize.height * 0.15,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 16, 133, 121),
                    Color.fromARGB(255, 0, 77, 69),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRM(totalBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        changeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                ReusableCard(
                  icon: const CircleIcon(
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                  ),
                  type: 'Income',
                  amount: income,
                ),
                const SizedBox(width: 14),
                ReusableCard(
                  icon: const CircleIcon(
                    icon: Icons.arrow_downward,
                    color: Colors.red,
                  ),
                  type: 'Expenses',
                  amount: expenses,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // This part scrolls when there are more rows than fit on screen.
            Expanded(
              child: _buildRecentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_recentTransactions.isEmpty) {
      return const Center(child: Text('No transactions yet'));
    }

    return ListView.separated(
      itemCount: _recentTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return _RecentTransactionRow(
          transaction: _recentTransactions[index],
        );
      },
    );
  }
}

class _RecentTransactionRow extends StatelessWidget {
  const _RecentTransactionRow({required this.transaction});

  final db_model.Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == db_model.TransactionType.income;
    // final color = _categoryColor(transaction.category, isIncome);
    final icon = _categoryIcon(transaction.category, isIncome);
    final sign = isIncome ? '+' : '-';

    // amountInCents is stored as cents; formatRM displays it as Ringgit.
    final amount = formatRM(transaction.amountInCents);

    return SizedBox(
      height: 72,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${_formatDate(transaction.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign $amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isIncome ? Colors.green[800] : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(date.year, date.month, date.day);

    if (transactionDay == today) return 'Today';

    if (transactionDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  IconData _categoryIcon(String category, bool isIncome) {
    switch (category.toLowerCase()) {
      case 'food & beverage':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'grocery':
        return Icons.shopping_cart;
      case 'shopping':
        return Icons.shopping_bag;
      case 'subscription':
        return Icons.subscriptions;
      case 'utilities':
        return Icons.receipt_long;
      case 'debt':
        return Icons.account_balance;
      case 'insurance':
        return Icons.shield;
      case 'salary':
        return Icons.payment;
      case 'freelance':
        return Icons.laptop;
      case 'investment':
        return Icons.trending_up;
      case 'gift':
        return Icons.card_giftcard;
      case 'bonus':
        return Icons.paid;
      default:
        return isIncome ? Icons.arrow_upward : Icons.more_horiz;
    }
  }

  // Color _categoryColor(String category, bool isIncome) {
  //   switch (category.toLowerCase()) {
  //     case 'food & beverage':
  //       return Colors.deepOrange;
  //     case 'grocery':
  //       return Colors.green;
  //     case 'shopping':
  //       return Colors.purple;
  //     case 'utilities':
  //       return Colors.pinkAccent;
  //     default:
  //       return isIncome ? Colors.green : Colors.teal;
  //   }
  // }
}
