import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

import '../models/app_currency.dart';
import '../models/transaction.dart' as model;
import 'currency_preferences.dart';
import 'receipt_storage.dart';
import 'transaction_database.dart';
import '../models/transaction_kind.dart';

class PreparedTransactionImport {
  const PreparedTransactionImport._({
    required this._transactions,
    required this.currencyCode,
    required this.missingReceiptCount,
  });

  final List<_PendingTransaction> _transactions;
  final String currencyCode;
  final int missingReceiptCount;

  int get transactionCount => _transactions.length;

  int get receiptCount => _transactions
      .where((transaction) => transaction.receiptBytes != null)
      .length;
}

class _PendingTransaction {
  const _PendingTransaction({
    required this.type,
    required this.amountInCents,
    required this.description,
    required this.category,
    required this.date,
    required this.notes,
    required this.receiptBytes,
    required this.receiptExtension,
  });

  final TransactionType type;
  final int amountInCents;
  final String description;
  final String category;
  final DateTime date;
  final String notes;
  final List<int>? receiptBytes;
  final String? receiptExtension;
}

class TransactionImporter {
  /// Reads and validates the ZIP without changing the database or files.
  static Future<PreparedTransactionImport> prepare(
    List<int> zipBytes,
  ) async {
    final existingTransactions = await TransactionDatabase.instance.getAll();

    if (existingTransactions.isNotEmpty) {
      throw StateError(
        'Import is only available when this ledger is empty.',
      );
    }

    final archive = ZipDecoder().decodeBytes(zipBytes);
    final csvFile = archive.findFile('transactions.csv');

    if (csvFile == null || !csvFile.isFile) {
      throw const FormatException(
        'This ZIP does not contain transactions.csv at its root.',
      );
    }

    final csvBytes = csvFile.readBytes();

    if (csvBytes == null) {
      throw const FormatException('Could not read transactions.csv.');
    }

    // Remove the UTF-8 BOM written by the exporter, if present.
    final csvText = utf8
        .decode(csvBytes, allowMalformed: false)
        .replaceFirst('\uFEFF', '');

    final rows = Csv().decodeWithHeaders(csvText);

    if (rows.isEmpty) {
      throw const FormatException(
        'The backup contains no transaction rows.',
      );
    }

    const requiredColumns = [
      'Date',
      'Type',
      'Description',
      'Category',
      'Amount',
      'Currency',
      'Notes',
      'Receipt file',
    ];

    final firstRow = rows.first;
    for (final column in requiredColumns) {
      if (!firstRow.headerMap.containsKey(column)) {
        throw FormatException('The CSV is missing the "$column" column.');
      }
    }

    final currencyCodes = rows
        .map((row) => _requiredText(row, 'Currency'))
        .toSet();

    if (currencyCodes.length != 1) {
      throw const FormatException(
        'The backup must use one currency throughout.',
      );
    }

    final currencyCode = currencyCodes.single;
    final supportedCurrency = AppCurrency.values.any(
      (currency) => currency.code == currencyCode,
    );

    if (!supportedCurrency) {
      throw FormatException(
        'Buku555 does not support the currency "$currencyCode".',
      );
    }

    final pendingTransactions = <_PendingTransaction>[];
    var missingReceiptCount = 0;

    for (final row in rows) {
      final dateText = _requiredText(row, 'Date');
      final date = DateTime.tryParse(dateText);

      if (date == null) {
        throw FormatException('Invalid transaction date: $dateText');
      }

      final typeText = _requiredText(row, 'Type');
      final type = switch (typeText) {
        'income' => TransactionType.income,
        'expense' => TransactionType.expense,
        _ => throw FormatException(
          'Unsupported transaction type: $typeText',
        ),
      };

      final amountInCents = _parseAmountToCents(
        _requiredText(row, 'Amount'),
      );

      final description = _requiredText(row, 'Description');
      final category = _requiredText(row, 'Category');

      if (description.trim().isEmpty || category.trim().isEmpty) {
        throw const FormatException(
          'A transaction is missing its description or category.',
        );
      }

      final receiptEntryName = _requiredText(row, 'Receipt file');
      List<int>? receiptBytes;
      String? receiptExtension;

      if (receiptEntryName == 'MISSING') {
        // The exporter recorded that this image was already missing.
        missingReceiptCount++;
      } else if (receiptEntryName.isNotEmpty) {
        // Accept only the filenames created by the Buku555 exporter.
        final validReceiptName = RegExp(
          r'^receipts/receipt_[0-9]+\.(jpg|jpeg|png|webp|heic)$',
        ).hasMatch(receiptEntryName);

        if (!validReceiptName) {
          throw FormatException(
            'Invalid receipt path in the CSV: $receiptEntryName',
          );
        }

        final imageEntry = archive.findFile(receiptEntryName);
        final imageBytes = imageEntry?.readBytes();

        if (imageEntry == null ||
            !imageEntry.isFile ||
            imageBytes == null ||
            imageBytes.isEmpty) {
          throw FormatException(
            'The ZIP is missing receipt file "$receiptEntryName".',
          );
        }

        receiptBytes = imageBytes;
        receiptExtension = p.extension(receiptEntryName).toLowerCase();
      }

      pendingTransactions.add(
        _PendingTransaction(
          type: type,
          amountInCents: amountInCents,
          description: description,
          category: category,
          date: date,
          notes: _text(row, 'Notes'),
          receiptBytes: receiptBytes,
          receiptExtension: receiptExtension,
        ),
      );
    }

    return PreparedTransactionImport._(
      transactions: pendingTransactions,
      currencyCode: currencyCode,
      missingReceiptCount: missingReceiptCount,
    );
  }

  /// Saves receipt images and inserts the transactions after user confirmation.
  static Future<void> importPrepared(
    PreparedTransactionImport prepared,
  ) async {
    // Check again in case another operation added transactions after preview.
    final existingTransactions = await TransactionDatabase.instance.getAll();

    if (existingTransactions.isNotEmpty) {
      throw StateError(
        'Transactions were added after the backup was selected. '
        'Import was stopped to prevent duplicates.',
      );
    }

    final previousCurrency = CurrencyPreferences.instance.current.value;
    final importedCurrency = AppCurrency.values.firstWhere(
      (currency) => currency.code == prepared.currencyCode,
    );

    final savedReceiptPaths = <String>[];

    await CurrencyPreferences.instance.save(importedCurrency);

    try {
      final transactionsToInsert = <model.Transaction>[];

      for (final pending in prepared._transactions) {
        String? savedReceiptPath;

        if (pending.receiptBytes != null) {
          savedReceiptPath = await ReceiptStorage.saveBytes(
            pending.receiptBytes!,
            extension: pending.receiptExtension!,
          );
          savedReceiptPaths.add(savedReceiptPath);
        }

        transactionsToInsert.add(
          model.Transaction(
            // Leave id null so SQLite assigns a new local ID.
            type: pending.type,
            amountInCents: pending.amountInCents,
            description: pending.description,
            category: pending.category,
            date: pending.date,
            notes: pending.notes,
            receiptPath: savedReceiptPath,
          ),
        );
      }

      await TransactionDatabase.instance.insertAll(
        transactionsToInsert,
      );
    } catch (_) {
      // If SQLite rejects the import, remove the copied receipt images.
      for (final path in savedReceiptPaths) {
        try {
          await ReceiptStorage.delete(path);
        } catch (_) {
          // Keep cleaning the other imported files.
        }
      }

      await CurrencyPreferences.instance.save(previousCurrency);
      rethrow;
    }
  }

  static String _requiredText(CsvRow row, String column) {
    final value = row[column];

    if (value == null) {
      throw FormatException('The CSV row has no "$column" value.');
    }

    return value.toString();
  }

  static String _text(CsvRow row, String column) {
    return row[column]?.toString() ?? '';
  }

  static int _parseAmountToCents(String amount) {
    // The exporter writes amounts such as 10.00, without currency symbols.
    final match = RegExp(r'^(-?)(\d+)\.(\d{2})$').firstMatch(amount);

    if (match == null) {
      throw FormatException('Invalid transaction amount: $amount');
    }

    final wholeAmount = int.parse(match.group(2)!);
    final cents = int.parse(match.group(3)!);
    final absoluteAmountInCents = wholeAmount * 100 + cents;

    return match.group(1) == '-'
        ? -absoluteAmountInCents
        : absoluteAmountInCents;
  }
}
