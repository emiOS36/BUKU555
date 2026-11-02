import 'package:flutter/material.dart';

import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/transaction.dart' as db_model;

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  TransactionScreenState createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen> {
  List<db_model.Transaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    reload();
  }

  // Reads transactions from SQLite and refreshes the list on screen.
  Future<void> reload() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await TransactionDatabase.instance.getAll();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load transactions: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTransaction(int id) async {
    await TransactionDatabase.instance.delete(id);
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions yet'));
    }

    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isIncome = transaction.type == db_model.TransactionType.income;
        final sign = isIncome ? '+' : '-';
        final amount = (transaction.amountInCents / 100).toStringAsFixed(2);
        final date = transaction.date.toLocal().toString().split(' ').first;

        return ListTile(
          title: Text(transaction.description),
          subtitle: Text('${transaction.category} • $date'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$sign RM $amount'),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteTransaction(transaction.id!),
              ),
            ],
          ),
        );
      },
    );
  }
}
