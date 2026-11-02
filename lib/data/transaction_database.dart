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
