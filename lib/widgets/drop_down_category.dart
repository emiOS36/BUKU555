import 'package:buku555/models/category.dart';
import 'package:flutter/material.dart';

class DropDownCategory extends StatelessWidget {
  final Category? selected;
  final ValueChanged<Category?> onChanged;

  const DropDownCategory({
    super.key,
    required this.selected,
    required this.onChanged,
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
          hint: const Text('Select category'),
          items: kCategories.map((cat) {
            return DropdownMenuItem<Category>(
              value: cat,
              child: Row(
                children: [
                  Icon(cat.icon, color: cat.color, size: 20),
                  const SizedBox(width: 10),
                  Text(cat.name),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) =>
              value == null ? 'Please select a category' : null,
        ),
      ],
    );
  }
}
