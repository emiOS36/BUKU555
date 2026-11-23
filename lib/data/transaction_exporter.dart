import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'currency_preferences.dart';
import 'receipt_storage.dart';
import 'transaction_database.dart';

class TransactionExporter {
  /// Returns null if there are no transactions.
  /// Otherwise returns the number of saved receipt files that were missing.
  static Future<int?> exportAll({
    Rect? sharePositionOrigin,
  }) async {
    final transactions = await TransactionDatabase.instance.getAll();

    if (transactions.isEmpty) {
      return null;
    }

    final currency = CurrencyPreferences.instance.current.value;
    final archive = Archive();
    final csvRows = <List<String>>[
      [
        'Date',
        'Type',
        'Description',
        'Category',
        'Amount',
        'Currency',
        'Notes',
        'Receipt file',
      ],
    ];

    var missingReceiptCount = 0;

    for (var index = 0; index < transactions.length; index++) {
      final transaction = transactions[index];
      var receiptFileInZip = '';

      if (transaction.receiptPath != null) {
        final receipt = await ReceiptStorage.fileFor(
          transaction.receiptPath,
        );

        if (receipt == null) {
          // The database has a receipt path, but the image file is missing.
          missingReceiptCount++;
          receiptFileInZip = 'MISSING';
        } else {
          final extension = _safeImageExtension(
            transaction.receiptPath!,
          );
          final receiptName = 'receipt_${transaction.id ?? index}$extension';

          // This is the path inside the ZIP, not the phone's private path.
          receiptFileInZip = 'receipts/$receiptName';

          archive.addFile(
            ArchiveFile.bytes(
              receiptFileInZip,
              await receipt.readAsBytes(),
            ),
          );
        }
      }

      csvRows.add([
        transaction.date.toIso8601String(),
        transaction.type.name,
        transaction.description,
        transaction.category,
        _amountFromCents(transaction.amountInCents),
        currency.code,
        transaction.notes ?? '',
        receiptFileInZip,
      ]);
    }

    final csv = csvRows.map((row) => row.map(_csvCell).join(',')).join('\r\n');

    // Add a UTF-8 BOM so spreadsheet apps are more likely to display
    // names and notes correctly.
    archive.addFile(
      ArchiveFile.bytes(
        'transactions.csv',
        [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)],
      ),
    );

    final now = DateTime.now();
    final timestamp =
        '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_'
        '${_twoDigits(now.hour)}${_twoDigits(now.minute)}';

    final zipName = 'buku555_export_$timestamp.zip';
    final temporaryDirectory = await getTemporaryDirectory();
    final zipFile = File(p.join(temporaryDirectory.path, zipName));

    final zipBytes = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipBytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        title: 'Export Buku555 data',
        subject: 'Buku555 transaction export',
        files: [XFile(zipFile.path)],
        fileNameOverrides: [zipName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );

    return missingReceiptCount;
  }

  static String _amountFromCents(int cents) {
    final absoluteCents = cents.abs();
    final wholeAmount = absoluteCents ~/ 100;
    final fractionalAmount = (absoluteCents % 100).toString().padLeft(2, '0');
    final sign = cents < 0 ? '-' : '';

    return '$sign$wholeAmount.$fractionalAmount';
  }

  static String _csvCell(String value) {
    // Prevent spreadsheet apps from treating user-entered text as a formula.
    final startsWithFormulaCharacter = RegExp(r'^[=+\-@\t\r]').hasMatch(value);
    final safeValue = startsWithFormulaCharacter ? "'$value" : value;

    // A quote inside a CSV field must be doubled.
    return '"${safeValue.replaceAll('"', '""')}"';
  }

  static String _safeImageExtension(String receiptPath) {
    final extension = p.extension(receiptPath).toLowerCase();
    const allowedExtensions = {
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
    };

    return allowedExtensions.contains(extension) ? extension : '.jpg';
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}
