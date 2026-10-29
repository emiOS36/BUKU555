import 'package:buku555/screens/reusable_card.dart';
import 'package:buku555/utils/money_formatter.dart';
import 'package:buku555/widgets/circle_icon.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final int income = 1050000; //hard coded
    final int expenses = 500000; //hard coded
    final int totalBalance = income - expenses;
    final String changeText = '+12% from last month'; //hardcoded

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          mainAxisAlignment: .start,
          crossAxisAlignment: .start,
          children: [
            Text('Buku555', style: TextStyle(fontSize: 25, fontWeight: .bold)),
            SizedBox(height: 2),
            Text(
              'Track today. A better tomorrow.',
              style: TextStyle(fontSize: 16, fontWeight: .w500),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Container(
              width: double.infinity,
              height: screenSize.height * 0.15,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topLeft,
                  end: .bottomRight,
                  colors: [
                    const Color.fromARGB(255, 16, 133, 121),
                    const Color.fromARGB(255, 0, 77, 69),
                  ],
                ),
                borderRadius: .circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.9),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: .w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRM(totalBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: .bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.white, size: 14),
                      SizedBox(width: 2),
                      Text(
                        changeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: .w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: .start,
              children: [
                ReusableCard(
                  icon: CircleIcon(
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                  ),
                  type: 'Income',
                  amount: income,
                ),
                SizedBox(width: 14),
                ReusableCard(
                  icon: CircleIcon(
                    icon: Icons.arrow_downward,
                    color: Colors.red,
                  ),
                  type: 'Expenses',
                  amount: expenses,
                ),
              ],
            ),
            SizedBox(height: 13),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 15, fontWeight: .w600),
              ),
            ),
            // ListView.builder(itemCount: _transaction.length, itemBuilder: (context, index) {})
          ],
        ),
      ),
    );
  }
}
