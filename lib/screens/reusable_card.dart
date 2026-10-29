import 'package:flutter/material.dart';
import 'package:buku555/utils/money_formatter.dart';

class ReusableCard extends StatelessWidget {
  final Widget icon;
  final String type;
  final int amount;

  const ReusableCard({
    super.key,
    required this.icon,
    required this.type,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    return Container(
      height: screenSize.height * 0.09,
      width: screenSize.width * 0.45,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Row(
        crossAxisAlignment: .center,
        children: [
          icon,
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                type,
                style: TextStyle(fontSize: 15, fontWeight: .w500),
              ),
              SizedBox(height: 1),
              Text(
                formatRM(amount),
                style: TextStyle(fontSize: 15, fontWeight: .bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
