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

const List<Category> kCategories = [
  Category(
    name: 'Food and beverage',
    icon: Icons.restaurant,
    color: Colors.grey,
  ),
  Category(
    name: 'Transport',
    icon: Icons.directions_car,
    color: Colors.grey,
  ),
  Category(
    name: 'Grocery',
    icon: Icons.shopping_cart,
    color: Colors.grey,
  ),
  Category(
    name: 'Shopping',
    icon: Icons.shopping_bag,
    color: Colors.grey,
  ),
  Category(
    name: 'Subscription',
    icon: Icons.subscriptions,
    color: Colors.grey,
  ),
  Category(
    name: 'Utilities',
    icon: Icons.receipt_long,
    color: Colors.grey,
  ),
  Category(
    name: 'Debt & Loan Payment',
    icon: Icons.account_balance,
    color: Colors.grey,
  ),
  Category(
    name: 'Insurance',
    icon: Icons.shield,
    color: Colors.grey,
  ),
  Category(
    name: 'Others',
    icon: Icons.more_horiz,
    color: Colors.grey,
  ),
];
