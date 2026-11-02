enum TransactionType { expense, income }

class Transaction {
  final int? id;
  final TransactionType type;
  final int amountInCents;
  final String description;
  final String category;
  final DateTime date;
  final String? notes;

  const Transaction({
    this.id,
    required this.type,
    required this.amountInCents,
    required this.description,
    required this.category,
    required this.date,
    this.notes,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.name,
    'amount_in_cents': amountInCents,
    'description': description,
    'category': category,
    'date': date.toIso8601String(),
    'notes': notes,
  };

  factory Transaction.fromMap(Map<String, Object?> map) => Transaction(
    id: map['id'] as int,
    type: TransactionType.values.byName(map['type'] as String),
    amountInCents: map['amount_in_cents'] as int,
    description: map['description'] as String,
    category: map['category'] as String,
    date: DateTime.parse(map['date'] as String),
    notes: map['notes'] as String?,
  );
}
