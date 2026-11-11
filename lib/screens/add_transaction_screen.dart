import 'package:buku555/models/category.dart';
import 'package:buku555/models/transaction_type.dart';
import 'package:buku555/widgets/date_picker_field.dart';
import 'package:buku555/widgets/drop_down_category.dart';
import 'package:buku555/widgets/label_text_field.dart';
import 'package:buku555/widgets/pill_toggle.dart';
import 'package:flutter/material.dart';
import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/transaction.dart' as db_model;

class AddTransactionScreen extends StatefulWidget {
  final db_model.Transaction? transaction;

  const AddTransactionScreen({
    super.key,
    this.transaction,
  });

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
  void initState() {
    super.initState();

    final existing = widget.transaction;
    if (existing == null) return;

    _type = existing.type == db_model.TransactionType.income
        ? TransactionType.income
        : TransactionType.expense;

    _selectedCategory = _type.categories.firstWhere(
      (category) => category.name == existing.category,
      orElse: () => _type.defaultCategory,
    );

    _amountController.text = (existing.amountInCents / 100).toStringAsFixed(2);
    _descriptionController.text = existing.description;
    _notesController.text = existing.notes ?? '';
    _selectedDate = existing.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount greater than zero')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a description')),
      );
      return;
    }

    final category = _selectedCategory;
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a category')),
      );
      return;
    }

    final transaction = db_model.Transaction(
      id: widget.transaction?.id,
      type: _type == TransactionType.income
          ? db_model.TransactionType.income
          : db_model.TransactionType.expense,
      amountInCents: (amount * 100).round(),
      description: description,
      category: category.name,
      date: _selectedDate ?? DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      if (widget.transaction == null) {
        await TransactionDatabase.instance.insert(transaction);
      } else {
        final updatedRows = await TransactionDatabase.instance.update(
          transaction,
        );

        if (updatedRows == 0) {
          throw StateError('The transaction could not be found.');
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save transaction: $error')),
      );
    }
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
        title: Text(
          widget.transaction == null ? 'Add Transaction' : 'Edit Transaction',
          style: const TextStyle(fontWeight: FontWeight.w500),
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
                  onPressed: _saveTransaction,

                  child: Text(
                    widget.transaction == null
                        ? 'Save ${_type.label}'
                        : 'Update ${_type.label}',
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
