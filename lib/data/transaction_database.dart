import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

import '../models/transaction.dart';

class TransactionDatabase {
  TransactionDatabase._();

  static final TransactionDatabase instance = TransactionDatabase._();

  static const _databaseName = 'buku555.db';
  static const _databaseVersion = 1;
  static const _tableName = 'transactions';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            amount_in_cents INTEGER NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT
          )
        ''');
      },
    );

    return _database!;
  }

  // CREATE
  Future<int> insert(Transaction transaction) async {
    final db = await database;
    return db.insert(_tableName, transaction.toMap());
  }

  // READ
  Future<List<Transaction>> getAll() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'date DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  //for search function
  Future<List<Transaction>> searchTransactions({
    String query = '',
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final arguments = <Object?>[];

    // The database stores these values as "income" or "expense".
    if (type == 'Income') {
      conditions.add('type = ?');
      arguments.add('income');
    } else if (type == 'Expense') {
      conditions.add('type = ?');
      arguments.add('expense');
    }

    // Search both the description and category.
    final searchText = query.trim();
    if (searchText.isNotEmpty) {
      conditions.add('(description LIKE ? OR category LIKE ?)');
      arguments.add('%$searchText%');
      arguments.add('%$searchText%');
    }

    // Include transactions on or after the start date.
    if (startDate != null) {
      final startOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      conditions.add('date >= ?');
      arguments.add(startOfDay.toIso8601String());
    }

    // Include the entire end date by stopping just before the next day.
    if (endDate != null) {
      final dayAfterEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day + 1,
      );

      conditions.add('date < ?');
      arguments.add(dayAfterEnd.toIso8601String());
    }

    final rows = await db.query(
      _tableName,
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : arguments,
      orderBy: 'date DESC, id DESC',
    );

    return rows.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getRecent({int limit = 10}) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'date DESC, id DESC',
      limit: limit,
    );
    return rows.map(Transaction.fromMap).toList();
  }

  // UPDATE
  Future<int> update(Transaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('Cannot update a transaction without an ID.');
    }

    final db = await database;
    return db.update(
      _tableName,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
