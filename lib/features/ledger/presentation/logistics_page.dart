import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/refinery_provider.dart';
import '../expense_provider.dart';
import '../income_provider.dart';
import 'add_expense_sheet.dart';
import 'add_income_sheet.dart';
import '../../gamification/presentation/widgets/top_bar.dart';

class LogisticsPage extends ConsumerStatefulWidget {
  const LogisticsPage({super.key});

  @override
  ConsumerState<LogisticsPage> createState() => _LogisticsPageState();
}

class _LogisticsPageState extends ConsumerState<LogisticsPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _showAnalytics = false;
  String _selectedPeriod = 'daily'; // daily, weekly, monthly, yearly, alltime

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);
    final incomesAsync = ref.watch(incomeProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset('lib/assets/bg_left.jpg', fit: BoxFit.cover),
        // Dark overlay
        Container(color: Colors.black.withOpacity(0.5)),
        // Main content
        SafeArea(
          child: Column(
            children: [
              // Header
              const TopBar(title: 'LOGISTICS BAY'),
              // Content area - Transaction list or Analytics
              Expanded(
                child: expensesAsync.when(
                  data: (expenses) {
                    return incomesAsync.when(
                      data: (incomes) {
                        if (_showAnalytics) {
                          return _buildAnalyticsWithCalendarView(expenses);
                        } else {
                          return _buildTransactionListView(expenses, incomes);
                        }
                      },
                      loading:
                          () => const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00D9FF),
                              ),
                            ),
                          ),
                      error:
                          (err, stack) => Center(
                            child: Text(
                              'Error: $err',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                    );
                  },
                  loading:
                      () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                  error:
                      (err, stack) => Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
        // Action buttons - both in bottom right corner
        Positioned(
          bottom: 30,
          right: 260, // Expanded spacing: Expense(220) + Spacing(10) + margin(30) = 260
          child: _buildActionButton(
            onPressed: () => _openAddIncomeSheet(context),
            icon: Icons.download,
            label: 'INCOME',
            color: Colors.cyan,
          ),
        ),
        Positioned(
          bottom: 30,
          right: 30,
          child: _buildActionButton(
            onPressed: () => _openAddExpenseSheet(context),
            icon: Icons.upload,
            label: 'EXPENSE',
            color: Colors.orange,
            showGlow: false,
          ),
        ),
        
        // Chat Overlay
        const BotChatPanel(),
      ],
    );
  }

  void _openAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddExpenseSheet(
        onExpenseAdded: (double amount) {
          // Deduct from total savings
          final refineryNotifier = ref.read(refineryProvider.notifier);
          // Note: We'll need to add a method to deduct from savings
          // For now, this is a placeholder for the logic
          _showExpenseDeductionSnackBar(context, amount);
        },
      ),
    );
  }

  void _openAddIncomeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddIncomeSheet(
        onIncomeAdded: (double amount) {
          // Calculate ore from income
          final refineryNotifier = ref.read(refineryProvider.notifier);
          final oreGenerated = refineryNotifier.calculateOreFromIncome(amount);
          
          // Show mining success notification
          _showMiningSuccessSnackBar(context, amount, oreGenerated);
        },
      ),
    );
  }

  Widget _buildTransactionListView(
    List<Expense> allExpenses,
    List<Income> allIncomes,
  ) {
    final selectedDayExpenses =
        allExpenses.where((e) => isSameDay(e.timestamp, _selectedDay)).toList();
    final selectedDayIncomes =
        allIncomes.where((i) => isSameDay(i.timestamp, _selectedDay)).toList();

    // Combine expenses and incomes into a single list with type info
    final transactions = <Map<String, dynamic>>[];
    for (var expense in selectedDayExpenses) {
      transactions.add({'type': 'expense', 'item': expense});
    }
    for (var income in selectedDayIncomes) {
      transactions.add({'type': 'income', 'item': income});
    }

    // Sort by timestamp descending (most recent first)
    transactions.sort(
      (a, b) => (b['item'].timestamp as DateTime).compareTo(
        a['item'].timestamp as DateTime,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Calendar
          Expanded(
            flex: 2,
            child: _buildGlassmorphContainer(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate:
                            (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: const TextStyle(
                            color: Color(0xFFBBDEFF),
                          ),
                          weekendTextStyle: const TextStyle(
                            color: Color(0xFFBBDEFF),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: const Color(0xFF00D9FF),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFF00B8D4),
                            shape: BoxShape.circle,
                          ),
                          defaultDecoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          weekendDecoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonTextStyle: const TextStyle(
                            color: Color(0xFF00D9FF),
                          ),
                          titleTextStyle: const TextStyle(
                            color: Color(0xFF00D9FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFF00D9FF),
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Toggle Analytics Button (using button.png)
                  _buildCustomButton(
                    onPressed: () {
                      setState(() {
                        _showAnalytics = !_showAnalytics;
                      });
                    },
                    size: 80,
                    label: 'SHOW ANALYTICS',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Transaction list
          Expanded(
            flex: 2,
            child: _buildGlassmorphContainer(
              child:
                  transactions.isEmpty
                      ? const Center(
                        child: Text(
                          'No transactions on this day.',
                          style: TextStyle(color: Color(0xFFBBDEFF)),
                        ),
                      )
                      : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (ctx, index) {
                          final transaction = transactions[index];
                          final isIncome = transaction['type'] == 'income';

                          if (isIncome) {
                            final income = transaction['item'] as Income;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4A5568,
                                  ).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          income.category,
                                          style: const TextStyle(
                                            color: Color(0xFFE0FFFF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'INCOME',
                                          style: TextStyle(
                                            color: Colors.green.shade300,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '+\$${income.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.green.shade300,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            final expense = transaction['item'] as Expense;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          expense.category,
                                          style: const TextStyle(
                                            color: Color(0xFFE0FFFF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          expense.isWant ? 'WANT' : 'NEED',
                                          style: TextStyle(
                                            color:
                                                expense.isWant
                                                    ? Colors.orange
                                                    : Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '-\$${expense.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF00D9FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsWithCalendarView(List<Expense> expenses) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Calendar (same as transaction view)
          Expanded(
            flex: 2,
            child: _buildGlassmorphContainer(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate:
                            (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: const TextStyle(
                            color: Color(0xFFBBDEFF),
                          ),
                          weekendTextStyle: const TextStyle(
                            color: Color(0xFFBBDEFF),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: const Color(0xFF00D9FF),
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: const Color(0xFF00B8D4),
                            shape: BoxShape.circle,
                          ),
                          defaultDecoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          weekendDecoration: BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonTextStyle: const TextStyle(
                            color: Color(0xFF00D9FF),
                          ),
                          titleTextStyle: const TextStyle(
                            color: Color(0xFF00D9FF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFF00D9FF),
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF00D9FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Toggle Analytics Button
                  _buildCustomButton(
                    onPressed: () {
                      setState(() {
                        _showAnalytics = !_showAnalytics;
                      });
                    },
                    size: 80,
                    label: 'HIDE ANALYTICS',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Analytics with period filters
          Expanded(flex: 2, child: _buildAnalyticsView(expenses)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView(List<Expense> expenses) {
    return _buildGlassmorphContainer(
      child: Column(
        children: [
          // Period Display
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              _getPeriodDisplayText(),
              style: const TextStyle(
                color: Color(0xFF00D9FF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Period Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPeriodButton('DAILY', 'daily'),
                _buildPeriodButton('WEEKLY', 'weekly'),
                _buildPeriodButton('MONTHLY', 'monthly'),
                _buildPeriodButton('YEARLY', 'yearly'),
                _buildPeriodButton('ALL TIME', 'alltime'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Charts
          Expanded(
            child: Column(
              children: [
                // Pie Chart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: PieChart(
                      PieChartData(
                        sections: _getPieChartData(
                          _filterExpensesByPeriod(expenses),
                        ),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Bar Chart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: BarChart(
                      BarChartData(
                        barGroups: _getBarChartData(
                          _filterExpensesByPeriod(expenses),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const titles = ['D', 'W', 'M'];
                                if (value.toInt() < titles.length) {
                                  return Text(
                                    titles[value.toInt()],
                                    style: const TextStyle(
                                      color: Color(0xFF00D9FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    color: Color(0xFFBBDEFF),
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildGlassmorphContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassmorphButton({
    required String label,
    required bool isActive,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isActive
                    ? const Color(0xFF00D9FF).withOpacity(0.2)
                    : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF00D9FF) : Colors.white24,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isActive
                        ? const Color(0xFF00D9FF)
                        : const Color(0xFFBBDEFF),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartData(List<Expense> expenses) {
    Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final colors = [
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.orange,
    ];

    int colorIndex = 0;
    return categoryTotals.entries.map((entry) {
      final section = PieChartSectionData(
        value: entry.value,
        title: entry.key,
        color: colors[colorIndex % colors.length],
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      colorIndex++;
      return section;
    }).toList();
  }

  List<BarChartGroupData> _getBarChartData(List<Expense> expenses) {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: expenses
                .where((e) => _isSameDay(e.timestamp, DateTime.now()))
                .fold(0.0, (prev, e) => prev + e.amount),
            color: Colors.cyan,
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [BarChartRodData(toY: 250, color: Colors.blue)],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [BarChartRodData(toY: 350, color: Colors.purple)],
      ),
    ];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCustomButton({
    required VoidCallback onPressed,
    required double size,
    String label = '',
    bool isAddIncome = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Button image scaled to fit text
          Container(
            width: label.isEmpty ? size : size * 3.8,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              image: DecorationImage(
                image: AssetImage('lib/assets/button.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          // Add icon or label on top
          if (label.isEmpty)
            Icon(
              isAddIncome ? Icons.remove : Icons.add,
              color: Colors.white,
              size: 32,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isActive = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFF00D9FF).withOpacity(0.2)
                  : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF00D9FF) : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00D9FF) : const Color(0xFFBBDEFF),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _getPeriodDisplayText() {
    switch (_selectedPeriod) {
      case 'daily':
        return 'DAILY: ${_formatDate(_selectedDay)}';
      case 'weekly':
        final weekStart = _selectedDay.subtract(
          Duration(days: _selectedDay.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'WEEKLY: ${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
      case 'monthly':
        return 'MONTHLY: ${_getMonthName(_selectedDay.month)} ${_selectedDay.year}';
      case 'yearly':
        return 'YEARLY: ${_selectedDay.year}';
      case 'alltime':
        return 'ALL TIME ANALYTICS';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return months[month - 1];
  }

  List<Expense> _filterExpensesByPeriod(List<Expense> expenses) {
    switch (_selectedPeriod) {
      case 'daily':
        return expenses
            .where((e) => isSameDay(e.timestamp, _selectedDay))
            .toList();
      case 'weekly':
        final weekStart = _selectedDay.subtract(
          Duration(days: _selectedDay.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        return expenses
            .where(
              (e) =>
                  e.timestamp.isAfter(
                    weekStart.subtract(const Duration(seconds: 1)),
                  ) &&
                  e.timestamp.isBefore(weekEnd.add(const Duration(seconds: 1))),
            )
            .toList();
      case 'monthly':
        return expenses
            .where(
              (e) =>
                  e.timestamp.year == _selectedDay.year &&
                  e.timestamp.month == _selectedDay.month,
            )
            .toList();
      case 'yearly':
        return expenses
            .where((e) => e.timestamp.year == _selectedDay.year)
            .toList();
      case 'alltime':
      default:
        return expenses;
    }
  }

  // New Action Button Builder
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool showGlow = true,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 220, // Increased width from 200 to 220
        height: 85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: const DecorationImage(
            image: AssetImage('lib/assets/button.png'),
            fit: BoxFit.fill,
          ),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white, // White icon for better contrast on button
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white, // White text for better contrast
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mining Success SnackBar
  void _showMiningSuccessSnackBar(BuildContext context, double amount, int ore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.cyan.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Mining Successful! +$ore Ore Extracted',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Expense Deduction SnackBar
  void _showExpenseDeductionSnackBar(BuildContext context, double amount) {
    // Calculate ore reduction locally for display confidence
    // We access the provider logic helper directly
    final refineryNotifier = ref.read(refineryProvider.notifier);
    final oreReduced = refineryNotifier.calculateOreFromIncome(amount);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(Icons.trending_down, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Paid: -\$${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ore Consumed: -$oreReduced',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
