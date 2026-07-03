import 'package:flutter/material.dart';

class CategoryModel {
  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  static const Map<String, IconData> defaultIcons = {
    'Food': Icons.restaurant,
    'Travel': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Healthcare': Icons.local_hospital,
    'Bills': Icons.receipt_long,
    'Salary': Icons.account_balance_wallet,
    'Investment': Icons.trending_up,
    'Education': Icons.school,
    'Others': Icons.category,
  };

  static IconData iconFor(String category) =>
      defaultIcons[category] ?? Icons.category;
}
