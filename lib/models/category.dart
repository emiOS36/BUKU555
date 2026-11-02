import 'package:buku555/models/transaction_type.dart';
import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<Category> expenseCategories = [
  Category(name: 'Food & beverage', icon: Icons.restaurant, color: Colors.grey),
  Category(name: 'Transport', icon: Icons.directions_car, color: Colors.grey),
  Category(name: 'Grocery', icon: Icons.shopping_cart, color: Colors.grey),
  Category(name: 'Shopping', icon: Icons.shopping_bag, color: Colors.grey),
  Category(name: 'Subscription', icon: Icons.subscriptions, color: Colors.grey),
  Category(name: 'Utilities', icon: Icons.receipt_long, color: Colors.grey),
  Category(name: 'Debt', icon: Icons.account_balance, color: Colors.grey),
  Category(name: 'Insurance', icon: Icons.shield, color: Colors.grey),
  Category(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
];

const List<Category> incomeCategories = [
  Category(name: 'Salary', icon: Icons.payment, color: Colors.grey),
  Category(name: 'Freelance', icon: Icons.laptop, color: Colors.grey),
  Category(name: 'Investment', icon: Icons.trending_up, color: Colors.grey),
  Category(name: 'Gift', icon: Icons.card_giftcard, color: Colors.grey),
  Category(name: 'Bonus', icon: Icons.paid, color: Colors.grey),
  Category(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
];

extension TransactionTypeCategories on TransactionType {
  List<Category> get categories => switch (this) {
    TransactionType.expense => expenseCategories,
    TransactionType.income => incomeCategories,
  };

  Category get defaultCategory => categories.first;
}
