import 'package:flutter/material.dart';

class LabelTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;

  const LabelTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 15, fontWeight: .w600),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: IconButton(
              onPressed: () {
                controller.clear();
              },
              icon: Icon(Icons.clear),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
