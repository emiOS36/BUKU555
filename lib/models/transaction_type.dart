import 'package:flutter/material.dart';

import 'transaction_kind.dart';

extension TransactionTypePresentation on TransactionType {
  String get label => switch (this) {
    TransactionType.expense => 'Expense',
    TransactionType.income => 'Income',
  };

  Color get color => Colors.teal;

  String get descriptionHint => switch (this) {
    TransactionType.expense => 'e.g. Lunch, Shopping',
    TransactionType.income => 'e.g. Salary, Bonus',
  };
}
