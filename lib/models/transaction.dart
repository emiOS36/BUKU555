import 'transaction_kind.dart';

class Transaction {
  final int? id;
  final TransactionType type;
  final int amountInCents;
  final String description;
  final String category;
  final DateTime date;
  final String? notes;
  final String? receiptPath;

  const Transaction({
    this.id,
    required this.type,
    required this.amountInCents,
    required this.description,
    required this.category,
    required this.date,
    this.notes,
    this.receiptPath,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.name,
    'amount_in_cents': amountInCents,
    'description': description,
    'category': category,
    'date': date.toIso8601String(),
    'notes': notes,
    'receipt_path': receiptPath,
  };

  factory Transaction.fromMap(Map<String, Object?> map) => Transaction(
    id: map['id'] as int,
    type: TransactionType.values.byName(map['type'] as String),
    amountInCents: map['amount_in_cents'] as int,
    description: map['description'] as String,
    category: map['category'] as String,
    date: DateTime.parse(map['date'] as String),
    notes: map['notes'] as String?,
    receiptPath: map['receipt_path'] as String?,
  );
}
