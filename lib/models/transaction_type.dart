import 'package:flutter/material.dart';

enum TransactionType {
  expense(
    label: 'Expense',
    color: Colors.teal,
    descriptionHint: 'e.g. Lunch, Shopping',
  ),
  income(
    label: 'Income',
    color: Colors.teal,
    descriptionHint: 'e.g. Salary, Bonus',
  );

  const TransactionType({
    required this.label,
    required this.color,
    required this.descriptionHint,
  });

  final String label;
  final Color color;
  final String descriptionHint;
}
