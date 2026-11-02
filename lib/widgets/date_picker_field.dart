import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DatePickerField({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
  });

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          'Date',
          style: TextStyle(fontSize: 15, fontWeight: .w600),
        ),
        TextFormField(
          key: ValueKey(selectedDate),
          initialValue: selectedDate == null ? '' : _formatDate(selectedDate!),
          readOnly: true,
          onTap: () => _pickDate(context),
          decoration: InputDecoration(
            hintText: 'Select Date',
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (_) => selectedDate == null ? 'Please select date' : null,
        ),
      ],
    );
  }
}
