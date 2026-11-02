import 'package:buku555/models/category.dart';
import 'package:flutter/material.dart';

class DropDownCategory extends StatelessWidget {
  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category?> onChanged;

  const DropDownCategory({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          'Category',
          style: TextStyle(fontSize: 15, fontWeight: .w600),
        ),
        SizedBox(height: 5),
        DropdownButtonFormField<Category>(
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items: [
            for (final cat in categories)
              DropdownMenuItem(
                value: cat,
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color, size: 20),
                    const SizedBox(width: 10),
                    Text(cat.name),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
