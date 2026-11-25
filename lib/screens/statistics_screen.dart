import 'dart:math' as math;
import 'package:buku555/utils/chart_formatter.dart';
import 'package:buku555/widgets/currency_amount.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:buku555/models/transaction_kind.dart';
import 'package:buku555/data/transaction_database.dart';
import 'package:buku555/models/transaction.dart' as db_model;
import 'package:buku555/widgets/pill_toggle.dart';
import 'package:buku555/data/currency_preferences.dart';
import 'package:buku555/utils/money_formatter.dart';

enum _StatisticsTab { expenses, income }

enum _StatisticsPeriod { thisMonth, lastMonth, last12Months }

extension on _StatisticsPeriod {
  String get label => switch (this) {
    _StatisticsPeriod.thisMonth => 'This Month',
    _StatisticsPeriod.lastMonth => 'Last Month',
    _StatisticsPeriod.last12Months => 'Last 12 Months',
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

    switch (_selectedPeriod) {
      case _StatisticsPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month),
          end: DateTime(now.year, now.month + 1),
        );

      case _StatisticsPeriod.lastMonth:
        final previousMonth = DateTime(now.year, now.month - 1);
        return DateTimeRange(
          start: DateTime(previousMonth.year, previousMonth.month),
          end: DateTime(previousMonth.year, previousMonth.month + 1),
        );

      case _StatisticsPeriod.last12Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 11),
          end: DateTime(now.year, now.month + 1),
        );
    }
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
    final type = _showIncome ? TransactionType.income : TransactionType.expense;

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

  List<int> get _monthlyTotals {
    final range = _periodRange;
    final totals = List<int>.filled(12, 0);

    for (final transaction in _chartTransactions) {
      final monthIndex =
          (transaction.date.year - range.start.year) * 12 +
          transaction.date.month -
          range.start.month;

      if (monthIndex >= 0 && monthIndex < totals.length) {
        totals[monthIndex] += transaction.amountInCents;
      }
    }

    return totals;
  }

  List<int> get _chartTotals {
    return _selectedPeriod == _StatisticsPeriod.last12Months
        ? _monthlyTotals
        : _weeklyTotals;
  }

  String _chartLabel(int index) {
    if (_selectedPeriod != _StatisticsPeriod.last12Months) {
      final firstDay = index * 7 + 1;
      final range = _periodRange;
      final daysInMonth = DateTime(
        range.start.year,
        range.start.month + 1,
        0,
      ).day;
      final lastDay = math.min(firstDay + 6, daysInMonth);

      return '$firstDay–$lastDay';
    }

    final month = DateTime(
      _periodRange.start.year,
      _periodRange.start.month + index,
    );

    const monthNames = [
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

    return monthNames[month.month - 1];
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

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedPeriod.label,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
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
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }

  Widget _buildWeeklyChartCard() {
    final totals = _chartTotals;
    final chartMax = _chartMaximum(
      totals.map((amount) => amount / 100).toList(),
    );

    final title = _selectedPeriod == _StatisticsPeriod.last12Months
        ? (_showIncome ? 'Income by Month' : 'Expenses by Month')
        : (_showIncome ? 'Income by Week' : 'Expenses by Week');

    return _StatisticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          CurrencyAmount(
            amountInCents: _totalCents,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 180,
            child: totals.every((amount) => amount == 0)
                ? const _ChartEmptyState()
                : BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final amountInCents = totals[group.x];
                            final currency =
                                CurrencyPreferences.instance.current.value;

                            return BarTooltipItem(
                              formatCurrency(amountInCents, currency),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      maxY: chartMax,
                      barGroups: [
                        for (var index = 0; index < totals.length; index++)
                          BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: totals[index] / 100,
                                width: 12,
                                color: _showIncome ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.zero,
                              ),
                            ],
                          ),
                      ],
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 0,
                            color: Colors.blueGrey.withValues(alpha: 0.35),
                            strokeWidth: 1,
                            dashArray: [6, 4],
                          ),
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
                            interval:
                                _selectedPeriod ==
                                    _StatisticsPeriod.last12Months
                                ? 2
                                : 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();

                              if (index < 0 || index >= totals.length) {
                                return const SizedBox.shrink();
                              }
                              if (_selectedPeriod ==
                                      _StatisticsPeriod.last12Months &&
                                  index.isEven) {
                                return const SizedBox.shrink();
                              }

                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  _chartLabel(index),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 5,
            backgroundColor: _categoryColor(colorIndex),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.key,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: .w600),
                ),
                const SizedBox(height: 2),
                CurrencyAmount(
                  amountInCents: entry.value,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: const TextStyle(fontSize: 13, fontWeight: .w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    final totals = _chartTotals;
    final chartValues = totals.map((amount) => amount / 100).toList();
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
            child: totals.every((amount) => amount == 0)
                ? const _ChartEmptyState()
                : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();

                              if (index < 0 || index >= totals.length) {
                                return null;
                              }

                              final amountInCents = totals[index];
                              final currency =
                                  CurrencyPreferences.instance.current.value;

                              return LineTooltipItem(
                                formatCurrency(amountInCents, currency),
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      minY: 0,
                      maxY: chartMax,
                      maxX: (totals.length - 1).toDouble(),
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
                              final index = value.toInt();

                              if (index < 0 || index >= totals.length) {
                                return const SizedBox.shrink();
                              }

                              if (_selectedPeriod ==
                                      _StatisticsPeriod.last12Months &&
                                  index.isEven) {
                                return const SizedBox.shrink();
                              }

                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  _chartLabel(index),
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
                            for (var index = 0; index < totals.length; index++)
                              FlSpot(
                                index.toDouble(),
                                totals[index] / 100,
                              ),
                          ],
                          isCurved: false,
                          color: Theme.of(context).colorScheme.primary,
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
