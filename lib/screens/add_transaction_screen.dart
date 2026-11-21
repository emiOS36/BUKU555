import 'package:buku555/models/category.dart';
import 'package:buku555/models/transaction_type.dart';
import 'package:buku555/widgets/date_picker_field.dart';
import 'package:buku555/widgets/drop_down_category.dart';
import 'package:buku555/widgets/label_text_field.dart';
import 'package:buku555/widgets/pill_toggle.dart';
import 'package:material_ui/material_ui.dart';
import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/transaction_kind.dart';
import 'package:buku555/models/transaction.dart' as db_model;
import 'package:buku555/data/currency_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:buku555/data/receipt_storage.dart';

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

  final _imagePicker = ImagePicker();
  XFile? _newReceipt;
  String? _receiptPath;
  Future<File?>? _savedReceiptFile;
  bool _removeReceipt = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.transaction;
    if (existing == null) return;

    _receiptPath = existing.receiptPath;
    _savedReceiptFile = ReceiptStorage.fileFor(_receiptPath);

    _type = existing.type;

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

  int? _parseAmountInCents(String input) {
    final value = input.trim();

    // Accept whole Ringgit or up to two decimal places.
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(value)) {
      return null;
    }

    final parts = value.split('.');
    final ringgit = int.tryParse(parts[0]);
    if (ringgit == null) return null;

    final cents = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));

    return ringgit * 100 + cents;
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(source: source);

      if (!mounted || image == null) return;

      setState(() {
        _newReceipt = image;
        _removeReceipt = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not pick receipt: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select the receipt photo.')),
      );
    }
  }

  Future<void> _showReceiptSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Photos'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null && mounted) {
      await _pickReceipt(source);
    }
  }

  Future<void> _saveTransaction() async {
    final amountInCents = _parseAmountInCents(_amountController.text);

    if (amountInCents == null || amountInCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount greater than zero'),
        ),
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
    final notes = _notesController.text.trim();

    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a note')),
      );
      return;
    }

    try {
      final oldReceiptPath = widget.transaction?.receiptPath;
      String? copiedReceiptPath;
      String? receiptPathToSave;

      if (_type == TransactionType.expense && !_removeReceipt) {
        if (_newReceipt != null) {
          copiedReceiptPath = await ReceiptStorage.save(_newReceipt!);
          receiptPathToSave = copiedReceiptPath;
        } else {
          // Editing without replacing the receipt: keep the existing path.
          receiptPathToSave = oldReceiptPath;
        }
      }

      final transaction = db_model.Transaction(
        id: widget.transaction?.id,
        type: _type,
        amountInCents: amountInCents,
        description: description,
        category: category.name,
        date: _selectedDate ?? DateTime.now(),
        notes: notes,
        receiptPath: receiptPathToSave,
      );
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

      if (oldReceiptPath != null && oldReceiptPath != receiptPathToSave) {
        try {
          await ReceiptStorage.delete(oldReceiptPath);
        } catch (error) {
          debugPrint('Could not remove old receipt file: $error');
        }
      }

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Could not save transaction: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save transaction. Please try again.'),
        ),
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
                hintText:
                    '${CurrencyPreferences.instance.current.value.symbol} 0.00',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                label: 'Notes',
                hintText: 'Add a note...',
                controller: _notesController,
              ),
              if (_type == TransactionType.expense) ...[
                const SizedBox(height: 10),
                _buildReceiptSection(),
              ],
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

  Widget _buildReceiptSection() {
    final colors = Theme.of(context).colorScheme;
    final pickedImage = _newReceipt;
    final hasSavedReceipt = _receiptPath != null && !_removeReceipt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Receipt (Optional)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        if (pickedImage == null && !hasSavedReceipt)
          CustomPaint(
            painter: _DashedBorderPainter(color: colors.outlineVariant),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Material(
                color: colors.surfaceContainerLow,
                child: InkWell(
                  onTap: _showReceiptSourcePicker,
                  child: SizedBox(
                    width: double.infinity,
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.file_upload_outlined,
                          size: 28,
                          color: colors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload receipt here',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Browse photos',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'or take a photo with your camera',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                if (pickedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(pickedImage.path),
                      width: 56,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  FutureBuilder<File?>(
                    future: _savedReceiptFile,
                    builder: (context, snapshot) {
                      final savedFile = snapshot.data;

                      if (savedFile == null) {
                        return const Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                        );
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          savedFile,
                          width: 56,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickedImage != null
                            ? pickedImage.name
                            : 'Receipt attached',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickedImage != null
                            ? 'Ready to attach'
                            : 'Saved with this transaction',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showReceiptSourcePicker,
                  child: const Text('Replace'),
                ),
                IconButton(
                  tooltip: 'Remove receipt',
                  onPressed: () {
                    setState(() {
                      _newReceipt = null;
                      _removeReceipt = _receiptPath != null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(14),
        ),
      );

    for (final metric in border.computeMetrics()) {
      var distance = 0.0;

      while (distance < metric.length) {
        final end = distance + 6 < metric.length ? distance + 6 : metric.length;

        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
