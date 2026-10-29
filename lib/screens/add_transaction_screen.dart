import 'package:buku555/models/category.dart';
import 'package:buku555/widgets/drop_down_category.dart';
import 'package:buku555/widgets/label_text_field.dart';
import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  Category? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            LabelTextField(
              label: 'Amount',
              hintText: 'RM 0.00',
              controller: _amountController,
            ),
            SizedBox(height: 10),
            LabelTextField(
              label: 'Description',
              hintText: 'eg. Lunch, Shopping',
              controller: _descriptionController,
            ),
            SizedBox(height: 10),
            DropDownCategory(
              selected: _selectedCategory,
              onChanged: (cat) => setState(() => _selectedCategory = cat),
            ),

            SizedBox(height: 10),
            LabelTextField(
              label: 'Notes (optional)',
              hintText: 'Add a note...',
              controller: _notesController,
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onPressed: () {},
                child: Text(
                  'Save Transaction',
                  style: TextStyle(fontSize: 16, fontWeight: .w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
