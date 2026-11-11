import 'dart:math' as math;
import 'package:buku555/utils/chart_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/transaction.dart' as db_model;
import 'package:buku555/utils/money_formatter.dart';
import 'package:buku555/widgets/pill_toggle.dart';

enum _StatisticsTab { expenses, income }

enum _StatisticsPeriod { thisMonth, lastMonth }

extension on _StatisticsPeriod {
  String get label => switch (this) {
    _StatisticsPeriod.thisMonth => 'This Month',
    _StatisticsPeriod.lastMonth => 'Last Month',
  };
}

extension on _StatisticsTab {
  String get tabLabel => switch (this) {
    _StatisticsTab.expenses => 'Expenses',
    _StatisticsTab.income => 'Income',
  };
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  List<db_model.Transaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  _StatisticsTab _selectedTab = _StatisticsTab.expenses;
  _StatisticsPeriod _selectedPeriod = _StatisticsPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Reloads transactions from SQLite.
  /// NavigationScreen can call this after a transaction is saved.
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
    } catch (error, stackTrace) {
      debugPrint('Could not load statistics: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load statistics. Please try again.';
        _isLoading = false;
      });
    }
  }

  DateTimeRange get _periodRange {
    final now = DateTime.now();

    if (_selectedPeriod == _StatisticsPeriod.thisMonth) {
      return DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1),
      );
    }

    final previousMonth = DateTime(now.year, now.month - 1);

    return DateTimeRange(
      start: DateTime(previousMonth.year, previousMonth.month),
      end: DateTime(previousMonth.year, previousMonth.month + 1),
    );
  }

  List<db_model.Transaction> get _periodTransactions {
    final range = _periodRange;

    return _transactions.where((transaction) {
      return !transaction.date.isBefore(range.start) &&
          transaction.date.isBefore(range.end);
    }).toList();
  }

  bool get _showIncome => _selectedTab == _StatisticsTab.income;

  List<db_model.Transaction> get _chartTransactions {
    final type = _showIncome
        ? db_model.TransactionType.income
        : db_model.TransactionType.expense;

    return _periodTransactions
        .where((transaction) => transaction.type == type)
        .toList();
  }

  int get _totalCents {
    return _chartTransactions.fold<int>(
      0,
      (total, transaction) => total + transaction.amountInCents,
    );
  }

  /// Divides this month into W1, W2, and so on, totaling transactions
  /// by the day of the month.
  List<int> get _weeklyTotals {
    final range = _periodRange;
    final daysInMonth = DateTime(
      range.start.year,
      range.start.month + 1,
      0,
    ).day;
    final weekCount = (daysInMonth + 6) ~/ 7;
    final totals = List<int>.filled(weekCount, 0);

    for (final transaction in _chartTransactions) {
      final weekIndex = (transaction.date.day - 1) ~/ 7;
      totals[weekIndex] += transaction.amountInCents;
    }

    return totals;
  }

  List<int> _weeklyTotalsFor(db_model.TransactionType type) {
    final range = _periodRange;
    final daysInMonth = DateTime(
      range.start.year,
      range.start.month + 1,
      0,
    ).day;
    final weekCount = (daysInMonth + 6) ~/ 7;
    final totals = List<int>.filled(weekCount, 0);

    for (final transaction in _periodTransactions) {
      if (transaction.type != type) continue;

      final weekIndex = (transaction.date.day - 1) ~/ 7;
      totals[weekIndex] += transaction.amountInCents;
    }

    return totals;
  }

  List<MapEntry<String, int>> get _categoryBreakdown {
    final totals = <String, int>{};

    for (final transaction in _chartTransactions) {
      totals.update(
        transaction.category,
        (current) => current + transaction.amountInCents,
        ifAbsent: () => transaction.amountInCents,
      );
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.length <= 5) return sorted;

    final topCategories = sorted.take(4).toList();
    final otherAmount = sorted
        .skip(4)
        .fold<int>(
          0,
          (total, entry) => total + entry.value,
        );

    return [
      ...topCategories,
      MapEntry('Other categories', otherAmount),
    ];
  }

  List<int> get _cumulativeWeeklyTotals {
    var runningTotal = 0;

    return _weeklyTotals.map((weeklyTotal) {
      runningTotal += weeklyTotal;
      return runningTotal;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Statistics',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<_StatisticsPeriod>(
              tooltip: 'Choose period',
              onSelected: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              itemBuilder: (context) => [
                for (final period in _StatisticsPeriod.values)
                  PopupMenuItem(
                    value: period,
                    child: Text(period.label),
                  ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedPeriod.label),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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

    return RefreshIndicator(
      onRefresh: reload,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 16),
            _buildWeeklyChartCard(),
            const SizedBox(height: 16),
            _buildCategoryBreakdownCard(),
            const SizedBox(height: 16),
            _buildTrendCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return PillToggle<_StatisticsTab>(
      selected: _selectedTab,
      onChanged: (tab) {
        setState(() {
          _selectedTab = tab;
        });
      },
      options: [
        for (final tab in _StatisticsTab.values)
          PillToggleOption(
            value: tab,
            label: tab.tabLabel,
            color: Colors.teal,
          ),
      ],
    );
  }

  Widget _buildWeeklyChartCard() {
    final weeklyTotals = _weeklyTotals;
    final chartMax = _chartMaximum(
      weeklyTotals.map((amount) => amount / 100).toList(),
    );
    final title = _showIncome ? 'Income by Week' : 'Expenses by Week';

    return _StatisticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            formatRM(_totalCents),
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 180,
            child: weeklyTotals.every((amount) => amount == 0)
                ? const _ChartEmptyState()
                : BarChart(
                    BarChartData(
                      maxY: chartMax,
                      barGroups: [
                        for (
                          var index = 0;
                          index < weeklyTotals.length;
                          index++
                        )
                          BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: weeklyTotals[index] / 100,
                                width: 18,
                                color: _showIncome ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ],
                          ),
                      ],
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: chartMax,
                            color: Colors.blueGrey.withValues(alpha: 0.35),
                            strokeWidth: 1,
                            dashArray: [6, 4],
                          ),
                        ],
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMax / 4,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: chartMax / 4,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  formatChartValue(value),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final week = value.toInt();

                              if (week < 0 || week >= weeklyTotals.length) {
                                return const SizedBox.shrink();
                              }

                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  'W${week + 1}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final breakdown = _categoryBreakdown;
    final hasData = breakdown.isNotEmpty && _totalCents != 0;

    return _StatisticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (!hasData)
            const SizedBox(
              height: 170,
              child: _ChartEmptyState(),
            )
          else ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = constraints.maxWidth < 360 ? 135.0 : 155.0;

                return Row(
                  children: [
                    SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 0,
                          sectionsSpace: 2,
                          sections: [
                            for (
                              var index = 0;
                              index < breakdown.length;
                              index++
                            )
                              PieChartSectionData(
                                value: breakdown[index].value.toDouble(),
                                color: _categoryColor(index),
                                radius: chartSize * 0.45,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          for (var index = 0; index < breakdown.length; index++)
                            _buildCategoryLegendRow(
                              breakdown[index],
                              index,
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryLegendRow(
    MapEntry<String, int> entry,
    int colorIndex,
  ) {
    final percentage = _totalCents == 0
        ? 0
        : (entry.value / _totalCents * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 5,
            backgroundColor: _categoryColor(colorIndex),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    final cumulativeTotals = _cumulativeWeeklyTotals;
    final chartValues = cumulativeTotals.map((amount) => amount / 100).toList();
    final chartMax = _chartMaximum(chartValues);

    return _StatisticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Trend',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: cumulativeTotals.every((amount) => amount == 0)
                ? const _ChartEmptyState()
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: chartMax,
                      maxX: (cumulativeTotals.length - 1).toDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMax / 4,
                      ),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: chartMax,
                            color: Colors.blueGrey.withValues(alpha: 0.35),
                            strokeWidth: 1,
                            dashArray: [6, 4],
                          ),
                        ],
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: chartMax / 4,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  formatChartValue(value),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final weekIndex = value.toInt();

                              if (weekIndex < 0 ||
                                  weekIndex >= cumulativeTotals.length) {
                                return const SizedBox.shrink();
                              }

                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  'W${weekIndex + 1}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (
                              var index = 0;
                              index < cumulativeTotals.length;
                              index++
                            )
                              FlSpot(
                                index.toDouble(),
                                cumulativeTotals[index] / 100,
                              ),
                          ],
                          isCurved: true,
                          color: Colors.teal,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.teal.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _chartMaximum(List<double> values) {
    final largestValue = values.fold<double>(
      0,
      (largest, value) => math.max(largest, value),
    );

    // Show a useful scale when there are no values.
    if (largestValue <= 0) return 400;

    // We want four equal steps: 0, ¼, ½, ¾, and the maximum.
    final rawStep = largestValue / 4;

    // Round each step up to a readable size.
    final roundingUnit = rawStep >= 10000
        ? 10000.0
        : rawStep >= 1000
        ? 1000.0
        : rawStep >= 100
        ? 100.0
        : rawStep >= 10
        ? 10.0
        : rawStep >= 1
        ? 1.0
        : rawStep >= 0.1
        ? 0.1
        : 0.01;

    final roundedStep = (rawStep / roundingUnit).ceil() * roundingUnit;

    // Four rounded steps give the chart's maximum.
    return roundedStep * 4;
  }

  Color _categoryColor(int index) {
    const colors = [
      Color(0xFF3983F6),
      Color(0xFFF58A12),
      Color(0xFFEB6683),
      Color(0xFF9254E8),
      Color(0xFF32B875),
      Color(0xFFF2C94C),
      Color(0xFF20A4B8),
    ];

    return colors[index % colors.length];
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No transactions for this period',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }
}
