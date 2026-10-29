import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String description;
  final String category;
  final DateTime date;
  final int amount;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.description,
    required this.category,
    required this.date,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = amount >= 0;
    final String sign = isIncome ? '+' : '-';

    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: .start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color,
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                description,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: .bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '$category • $date',
                style: TextStyle(fontSize: 18, fontWeight: .w500),
              ),
            ],
          ),
          Text(
            '$sign'
            'RM ${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: .w600,
              color: isIncome ? Colors.green[800] : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
