import 'package:buku555/models/category.dart';
import 'package:buku555/models/transaction_type.dart';
import 'package:buku555/widgets/date_picker_field.dart';
import 'package:buku555/widgets/drop_down_category.dart';
import 'package:buku555/widgets/label_text_field.dart';
import 'package:buku555/widgets/pill_toggle.dart';
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

  TransactionType _type = TransactionType.expense;
  late Category? _selectedCategory = _type.defaultCategory;
  DateTime? _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _selectedCategory = type.defaultCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: .w500),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PillToggle<TransactionType>(
                selected: _type,
                onChanged: _onTypeChanged,
                options: [
                  for (final t in TransactionType.values)
                    PillToggleOption(
                      value: t,
                      label: t.label,
                      color: t.color,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              LabelTextField(
                label: 'Amount',
                hintText: 'RM 0.00',
                controller: _amountController,
              ),
              const SizedBox(height: 10),
              LabelTextField(
                label: 'Description',
                hintText: _type.descriptionHint,
                controller: _descriptionController,
              ),
              const SizedBox(height: 10),
              DropDownCategory(
                key: ValueKey(_type), // fresh dropdown when type changes
                categories: _type.categories,
                selected: _selectedCategory,
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 10),
              DatePickerField(
                selectedDate: _selectedDate,
                onDateSelected: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 10),
              LabelTextField(
                label: 'Notes (optional)',
                hintText: 'Add a note...',
                controller: _notesController,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    'Save ${_type.label}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
