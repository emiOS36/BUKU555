import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReceiptStorage {
  static Future<String> save(XFile image) async {
    final appDirectory = await getApplicationSupportDirectory();
    final receiptDirectory = Directory(
      p.join(appDirectory.path, 'receipts'),
    );
    await receiptDirectory.create(recursive: true);

    final extension = p.extension(image.name).isEmpty
        ? '.jpg'
        : p.extension(image.name);
    final fileName =
        'receipt_${DateTime.now().microsecondsSinceEpoch}$extension';
    final savedFile = File(p.join(receiptDirectory.path, fileName));

    await File(image.path).copy(savedFile.path);

    // Store this relative path in SQLite.
    return p.join('receipts', fileName);
  }

  static Future<File?> fileFor(String? relativePath) async {
    if (relativePath == null) return null;

    final appDirectory = await getApplicationSupportDirectory();
    final file = File(p.join(appDirectory.path, relativePath));

    return await file.exists() ? file : null;
  }

  static Future<void> delete(String? relativePath) async {
    final file = await fileFor(relativePath);
    if (file != null) await file.delete();
  }
}
