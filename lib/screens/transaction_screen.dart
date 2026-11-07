import 'package:flutter/material.dart';

import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/category.dart';
import 'package:buku555/models/transaction.dart' as db_model;
import 'package:buku555/screens/reusable_card.dart';
import 'package:buku555/utils/money_formatter.dart';
import 'package:buku555/widgets/circle_icon.dart';
import 'package:buku555/widgets/pill_toggle.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  TransactionScreenState createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<db_model.Transaction> _transactions = [];
  List<db_model.Transaction> _visibleTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _isSearching = false;
  String _searchQuery = '';
  String _selectedType = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<db_model.Transaction>> _queryVisibleTransactions() {
    return TransactionDatabase.instance.searchTransactions(
      query: _searchQuery,
      type: _selectedType == 'All' ? null : _selectedType,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
  }

  /// Reads transactions from SQLite and refreshes the screen.
  Future<void> reload() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allTransactions = await TransactionDatabase.instance.getAll();
      final visibleTransactions = await _queryVisibleTransactions();

      if (!mounted) return;

      setState(() {
        _transactions = allTransactions;
        _visibleTransactions = visibleTransactions;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load transactions: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load transactions. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshVisibleTransactions() async {
    try {
      final transactions = await _queryVisibleTransactions();

      if (!mounted) return;

      setState(() {
        _visibleTransactions = transactions;
        _errorMessage = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Could not filter transactions: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not filter transactions. Please try again.';
      });
    }
  }

  Future<void> _deleteTransaction(db_model.Transaction transaction) async {
    final id = transaction.id;

    // SQLite needs the ID to know which row to delete.
    if (id == null) {
      await reload();
      return;
    }
    try {
      // Ask SQLite to delete the transaction with this ID.
      await TransactionDatabase.instance.delete(id);
      // Read the database again to update what the screen shows.
      await reload();
    } catch (error, stackTrace) {
      // These details are for debug console.
      debugPrint('Could not delete transaction: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      // Reload the screen, then show a message to the user.
      await reload();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete transaction. Please try again.'),
        ),
      );
    }
  }

  Future<bool> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This transaction will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return shouldDelete ?? false;
  }

  Future<void> _chooseDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
      helpText: 'Filter transactions by date',
    );

    if (pickedRange == null || !mounted) return;

    setState(() {
      _selectedDateRange = DateTimeRange(
        start: DateTime(
          pickedRange.start.year,
          pickedRange.start.month,
          pickedRange.start.day,
        ),
        end: DateTime(
          pickedRange.end.year,
          pickedRange.end.month,
          pickedRange.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
    await _refreshVisibleTransactions();
  }

  Future<void> _clearDateRange() async {
    setState(() {
      _selectedDateRange = null;
    });

    await _refreshVisibleTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selectedRange = _selectedDateRange;

    // No selected range: use this month's first day through next month's first day.
    // Selected range: include the full start and end days.
    final summaryStart = selectedRange == null
        ? DateTime(now.year, now.month)
        : DateTime(
            selectedRange.start.year,
            selectedRange.start.month,
            selectedRange.start.day,
          );

    final summaryEndExclusive = selectedRange == null
        ? DateTime(now.year, now.month + 1)
        : DateTime(
            selectedRange.end.year,
            selectedRange.end.month,
            selectedRange.end.day + 1,
          );

    final transactionsInSummaryPeriod = _transactions.where((transaction) {
      return !transaction.date.isBefore(summaryStart) &&
          transaction.date.isBefore(summaryEndExclusive);
    });

    final income = transactionsInSummaryPeriod
        .where(
          (transaction) => transaction.type == db_model.TransactionType.income,
        )
        .fold<int>(
          0,
          (total, transaction) => total + transaction.amountInCents,
        );

    final expenses = transactionsInSummaryPeriod
        .where(
          (transaction) => transaction.type == db_model.TransactionType.expense,
        )
        .fold<int>(
          0,
          (total, transaction) => total + transaction.amountInCents,
        );
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search description or category',
                  border: InputBorder.none,
                ),
                onChanged: (value) async {
                  setState(() {
                    _searchQuery = value;
                  });

                  await _refreshVisibleTransactions();
                },
              )
            : const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Close search' : 'Search',
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Filter by date',
            icon: Icon(
              Icons.filter_alt_outlined,
              color: _selectedDateRange == null
                  ? null
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _chooseDateRange,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ReusableCard(
                    icon: const CircleIcon(
                      icon: Icons.arrow_upward,
                      color: Colors.green,
                    ),
                    type: 'Income',
                    amount: income,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReusableCard(
                    icon: const CircleIcon(
                      icon: Icons.arrow_downward,
                      color: Colors.red,
                    ),
                    type: 'Expenses',
                    amount: expenses,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PillToggle<String>(
              selected: _selectedType,
              onChanged: (type) async {
                setState(() {
                  _selectedType = type;
                });

                await _refreshVisibleTransactions();
              },
              options: const [
                PillToggleOption(
                  value: 'All',
                  label: 'All',
                  color: Colors.teal,
                ),
                PillToggleOption(
                  value: 'Income',
                  label: 'Income',
                  color: Colors.teal,
                ),
                PillToggleOption(
                  value: 'Expense',
                  label: 'Expense',
                  color: Colors.teal,
                ),
              ],
            ),
            if (_selectedDateRange != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(
                    '${_formatFullDate(_selectedDateRange!.start)} – '
                    '${_formatFullDate(_selectedDateRange!.end)}',
                  ),
                  onDeleted: _clearDateRange,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: _buildTransactionList(_visibleTransactions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    List<db_model.Transaction> transactions,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 8),
            TextButton(
              onPressed: reload,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (transactions.isEmpty) {
      final hasFilters =
          _searchQuery.isNotEmpty ||
          _selectedType != 'All' ||
          _selectedDateRange != null;

      return Center(
        child: Text(
          hasFilters
              ? 'No transactions match these filters'
              : 'No transactions yet',
        ),
      );
    }

    final children = <Widget>[];
    DateTime? previousDay;

    for (final transaction in transactions) {
      final transactionDay = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (previousDay != transactionDay) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
            child: Text(
              _dateHeading(transaction.date),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        previousDay = transactionDay;
      }

      children.add(_buildTransactionRow(transaction));
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: children,
      ),
    );
  }

  Widget _buildTransactionRow(db_model.Transaction transaction) {
    final isIncome = transaction.type == db_model.TransactionType.income;
    final category = _findCategory(transaction.category);
    final amount = formatRM(transaction.amountInCents);

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => _deleteTransaction(transaction),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: CircleAvatar(
            backgroundColor: category.color,
            child: Icon(category.icon, color: Colors.white),
          ),
          title: Text(
            transaction.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${transaction.category} • '
            '${_transactionTimeOrDate(transaction.date)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isIncome ? '+' : '-'}$amount',
                style: TextStyle(
                  color: isIncome ? Colors.green[800] : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }

  Category _findCategory(String categoryName) {
    for (final category in [...expenseCategories, ...incomeCategories]) {
      if (category.name.toLowerCase() == categoryName.toLowerCase()) {
        return category;
      }
    }

    return const Category(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Colors.grey,
    );
  }

  String _dateHeading(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) {
      return 'Today, ${_formatDayMonth(date)}';
    }

    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatDayMonth(date)}';
    }

    return _formatFullDate(date);
  }

  String _transactionTimeOrDate(DateTime date) {
    final hasTime = date.hour != 0 || date.minute != 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final isTodayOrYesterday =
        day == today || day == today.subtract(const Duration(days: 1));

    if (hasTime && isTodayOrYesterday) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final suffix = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $suffix';
    }

    return _formatDayMonth(date);
  }

  String _formatDayMonth(DateTime date) {
    return '${date.day} ${_monthName(date.month)}';
  }

  String _formatFullDate(DateTime date) {
    return '${_formatDayMonth(date)} ${date.year}';
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }
}
