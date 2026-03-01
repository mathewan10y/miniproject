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
import '../../sms_sync/presentation/sms_sync_button.dart';

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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // Controls which dataset the Pie Chart displays
  String _pieChartMode = 'expenses'; // 'expenses' | 'incomes'
  // Controls which chart type to display on compact screens
  String _analyticsChartShow = 'pie'; // 'pie' | 'bar'

  // Responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;

  bool _isCompactLayout(double width) => width < _tabletBreakpoint;
  bool _isMobileLayout(double width) => width < _mobileBreakpoint;

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
              const TopBar(title: 'LOGISTICS BAY', actions: SmsSyncButton()),
              // Content area - Transaction list or Analytics
              Expanded(
                child: expensesAsync.when(
                  data: (expenses) {
                    return incomesAsync.when(
                      data: (incomes) {
                        if (_showAnalytics) {
                          return _buildAnalyticsWithCalendarView(
                            expenses,
                            incomes,
                          );
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

        // Chat Overlay
        const BotChatPanel(),
      ],
    );
  }

  void _openAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => AddExpenseSheet(
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
      builder:
          (ctx) => AddIncomeSheet(
            onIncomeAdded: (double amount) {
              // Calculate ore from income
              final refineryNotifier = ref.read(refineryProvider.notifier);
              final oreGenerated = refineryNotifier.calculateOreFromIncome(
                amount,
              );

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = _isCompactLayout(screenWidth);
        final isMobile = _isMobileLayout(screenWidth);
        final padding = isCompact ? 8.0 : 16.0;

        // Build calendar panel with toggle button
        Widget calendarPanel = _buildGlassmorphContainer(
          child: Column(
            children: [
              Expanded(child: _buildResponsiveCalendar(isCompact: isCompact)),
              SizedBox(height: isCompact ? 8 : 12),
              // Toggle Analytics Button
              _buildCustomButton(
                onPressed: () {
                  setState(() {
                    _showAnalytics = !_showAnalytics;
                  });
                },
                size: isCompact ? 60 : 80,
                label: 'SHOW ANALYTICS',
              ),
              SizedBox(height: isCompact ? 8 : 12),
            ],
          ),
        );

        // Build transaction list panel with action buttons inside
        Widget transactionPanel = _buildGlassmorphContainer(
          child: Column(
            children: [
              // Transaction list takes most space
              Expanded(child: _buildResponsiveTransactionList(transactions)),
              // Action buttons at bottom of transaction panel
              _buildActionButtonsRow(isCompact: isCompact, isMobile: isMobile),
            ],
          ),
        );

        if (isMobile) {
          // Vertical layout for mobile devices
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              children: [
                // Calendar takes less space on mobile
                Expanded(flex: 2, child: calendarPanel),
                const SizedBox(height: 12),
                // Transaction list with buttons inside
                Expanded(flex: 3, child: transactionPanel),
              ],
            ),
          );
        } else {
          // Horizontal layout for tablets and desktops
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              children: [
                // Calendar
                Expanded(flex: isCompact ? 3 : 2, child: calendarPanel),
                SizedBox(width: isCompact ? 12 : 16),
                // Transaction list with buttons inside
                Expanded(flex: 2, child: transactionPanel),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildAnalyticsWithCalendarView(
    List<Expense> expenses,
    List<Income> incomes,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = _isCompactLayout(screenWidth);
        final isMobile = _isMobileLayout(screenWidth);
        final padding = isCompact ? 8.0 : 16.0;

        // Build calendar panel with toggle button
        Widget calendarPanel = _buildGlassmorphContainer(
          child: Column(
            children: [
              Expanded(child: _buildResponsiveCalendar(isCompact: isCompact)),
              SizedBox(height: isCompact ? 8 : 12),
              // Toggle Analytics Button
              _buildCustomButton(
                onPressed: () {
                  setState(() {
                    _showAnalytics = !_showAnalytics;
                  });
                },
                size: isCompact ? 60 : 80,
                label: 'HIDE ANALYTICS',
              ),
              SizedBox(height: isCompact ? 8 : 12),
            ],
          ),
        );

        // Build analytics panel with action buttons inside
        Widget analyticsPanel = _buildAnalyticsViewWithButtons(
          expenses,
          incomes,
          isCompact: isCompact,
          isMobile: isMobile,
        );

        if (isMobile) {
          // Vertical layout for mobile devices
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              children: [
                // Calendar takes less space on mobile
                Expanded(flex: 2, child: calendarPanel),
                const SizedBox(height: 12),
                // Analytics with buttons inside
                Expanded(flex: 3, child: analyticsPanel),
              ],
            ),
          );
        } else {
          // Horizontal layout for tablets and desktops
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              children: [
                // Calendar
                Expanded(flex: isCompact ? 3 : 2, child: calendarPanel),
                SizedBox(width: isCompact ? 12 : 16),
                // Analytics with buttons inside
                Expanded(flex: 2, child: analyticsPanel),
              ],
            ),
          );
        }
      },
    );
  }

  // Analytics view with action buttons inside
  Widget _buildAnalyticsViewWithButtons(
    List<Expense> expenses,
    List<Income> incomes, {
    bool isCompact = false,
    bool isMobile = false,
  }) {
    return _buildGlassmorphContainer(
      child: Column(
        children: [
          // Analytics content takes most space
          Expanded(
            child: _buildAnalyticsContent(
              expenses,
              incomes,
              isCompact: isCompact,
            ),
          ),
          // Action buttons at bottom
          _buildActionButtonsRow(isCompact: isCompact, isMobile: isMobile),
        ],
      ),
    );
  }

  // Analytics content without the container
  Widget _buildAnalyticsContent(
    List<Expense> expenses,
    List<Income> incomes, {
    bool isCompact = false,
  }) {
    final filteredExpenses = _filterExpensesByPeriod(expenses);
    final filteredIncomes = _filterIncomesByPeriod(incomes);

    final double pieRadius = isCompact ? 50.0 : 80.0;
    final double centerSpace = isCompact ? 20.0 : 32.0;

    // Build inner pie chart widget
    Widget pieWidget = _buildPieChart(
      items: _pieChartMode == 'expenses' ? filteredExpenses : filteredIncomes,
      categoryFn:
          _pieChartMode == 'expenses'
              ? (e) => (e as Expense).category
              : (i) => (i as Income).category,
      amountFn:
          _pieChartMode == 'expenses'
              ? (e) => (e as Expense).amount
              : (i) => (i as Income).amount,
      radius: pieRadius,
      centerSpaceRadius: centerSpace,
      emptyLabel: _pieChartMode == 'expenses' ? 'No Expenses' : 'No Income',
    );

    // Build inner bar chart widget
    Widget barWidget = _buildBarChartWidget(
      filteredIncomes,
      filteredExpenses,
      isCompact: isCompact,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top controls bar ────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 8 : 12,
            isCompact ? 6 : 10,
            isCompact ? 8 : 12,
            0,
          ),
          child: Row(
            children: [
              // Period display
              Expanded(
                child: Text(
                  _getPeriodDisplayText(),
                  style: TextStyle(
                    color: const Color(0xFF00D9FF),
                    fontSize: isCompact ? 10 : 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Pie-mode chips (always visible)
              _buildMiniChip(
                label: 'EXP',
                active: _pieChartMode == 'expenses',
                activeColor: Colors.orange,
                onTap: () => setState(() => _pieChartMode = 'expenses'),
                isCompact: isCompact,
              ),
              SizedBox(width: isCompact ? 4 : 6),
              _buildMiniChip(
                label: 'INC',
                active: _pieChartMode == 'incomes',
                activeColor: Colors.green,
                onTap: () => setState(() => _pieChartMode = 'incomes'),
                isCompact: isCompact,
              ),
              // Chart-type toggle (compact only)
              if (isCompact) ...[
                const SizedBox(width: 8),
                _buildMiniChip(
                  label: 'PIE',
                  active: _analyticsChartShow == 'pie',
                  activeColor: const Color(0xFF00D9FF),
                  onTap: () => setState(() => _analyticsChartShow = 'pie'),
                  isCompact: isCompact,
                ),
                SizedBox(width: 4),
                _buildMiniChip(
                  label: 'BAR',
                  active: _analyticsChartShow == 'bar',
                  activeColor: const Color(0xFF00D9FF),
                  onTap: () => setState(() => _analyticsChartShow = 'bar'),
                  isCompact: isCompact,
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: isCompact ? 4 : 6),
        // ── Period filter buttons ────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 6.0 : 10.0),
          child: Wrap(
            spacing: isCompact ? 3 : 6,
            runSpacing: isCompact ? 3 : 6,
            alignment: WrapAlignment.center,
            children: [
              _buildPeriodButton('DAILY', 'daily', isCompact: isCompact),
              _buildPeriodButton('WEEKLY', 'weekly', isCompact: isCompact),
              _buildPeriodButton('MONTHLY', 'monthly', isCompact: isCompact),
              _buildPeriodButton('YEARLY', 'yearly', isCompact: isCompact),
              _buildPeriodButton('ALL', 'alltime', isCompact: isCompact),
            ],
          ),
        ),
        SizedBox(height: isCompact ? 4 : 8),
        // ── Chart area ───────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 6.0 : 10.0),
            child:
                isCompact
                    // Compact: one chart at a time, toggled above
                    ? (_analyticsChartShow == 'pie' ? pieWidget : barWidget)
                    // Wide: pie left, bar right
                    : Row(
                      children: [
                        Expanded(child: pieWidget),
                        const SizedBox(width: 12),
                        Expanded(child: barWidget),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  // Compact mini-chip used in the controls bar
  Widget _buildMiniChip({
    required String label,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 9,
          vertical: isCompact ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.2) : Colors.black38,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? activeColor : Colors.white24,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? activeColor : const Color(0xFFBBDEFF),
            fontSize: isCompact ? 8.5 : 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  // Extracted bar chart widget so it can be used independently
  Widget _buildBarChartWidget(
    List<Income> incomes,
    List<Expense> expenses, {
    bool isCompact = false,
  }) {
    return BarChart(
      BarChartData(
        barGroups: _getBarChartData(incomes, expenses),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isCompact ? 24 : 28,
              getTitlesWidget: (value, meta) {
                const labels = ['INC', 'EXP'];
                const colors = [Color(0xFF00E676), Color(0xFFFF6D00)];
                final idx = value.toInt();
                if (idx >= 0 && idx < labels.length) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[idx],
                        style: TextStyle(
                          color: colors[idx],
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 9 : 11,
                          letterSpacing: 0.5,
                        ),
                      ),
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
              reservedSize: isCompact ? 32 : 42,
              getTitlesWidget: (value, meta) {
                final label =
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toInt().toString();
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFFBBDEFF),
                      fontSize: isCompact ? 8 : 10,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D9FF).withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D9FF).withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
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

  // Generic pie chart – works for both Expense and Income lists.
  Widget _buildPieChart({
    required List<dynamic> items,
    required String Function(dynamic) categoryFn,
    required double Function(dynamic) amountFn,
    required double radius,
    required double centerSpaceRadius,
    String emptyLabel = 'No Data',
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              emptyLabel,
              style: const TextStyle(color: Color(0xFFBBDEFF), fontSize: 12),
            ),
          ],
        ),
      );
    }

    final Map<String, double> totals = {};
    for (final item in items) {
      final cat = categoryFn(item);
      totals[cat] = (totals[cat] ?? 0) + amountFn(item);
    }

    const colors = [
      Color(0xFF00D9FF), // cyan
      Color(0xFF7C4DFF), // purple
      Color(0xFFFF6D00), // deep orange
      Color(0xFF00E676), // green
      Color(0xFFFF4081), // pink
      Color(0xFF40C4FF), // light blue
      Color(0xFFFFD740), // amber
    ];

    final total = totals.values.fold(0.0, (s, v) => s + v);
    int idx = 0;
    final sections =
        totals.entries.map((entry) {
          final pct = total > 0 ? (entry.value / total * 100) : 0;
          // Only render label when the slice is large enough to fit text
          final showTitle = pct >= 8;
          final s = PieChartSectionData(
            value: entry.value,
            title:
                showTitle
                    ? (entry.key.length > 6
                        ? '${entry.key.substring(0, 5)}…'
                        : entry.key)
                    : '',
            color: colors[idx % colors.length],
            radius: radius,
            titleStyle: TextStyle(
              color: Colors.white,
              fontSize: radius < 60 ? 8 : 10,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          );
          idx++;
          return s;
        }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: centerSpaceRadius,
        sectionsSpace: 3,
        pieTouchData: PieTouchData(enabled: false),
      ),
    );
  }

  // Comparative bar chart: Bar 0 = Total Income (green), Bar 1 = Total Expenses (orange)
  List<BarChartGroupData> _getBarChartData(
    List<Income> incomes,
    List<Expense> expenses,
  ) {
    final totalIncome = incomes.fold(0.0, (s, i) => s + i.amount);
    final totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: totalIncome,
            color: Colors.green,
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: totalExpenses,
            color: Colors.orange,
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ),
    ];
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

  Widget _buildPeriodButton(
    String label,
    String period, {
    bool isCompact = false,
  }) {
    final isActive = _selectedPeriod == period;
    final horizontalPadding = isCompact ? 8.0 : 12.0;
    final verticalPadding = isCompact ? 6.0 : 8.0;
    final fontSize = isCompact ? 9.0 : 11.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
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
            fontSize: fontSize,
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

  /// Normalises [d] to midnight (00:00:00.000) so duration arithmetic
  /// is never skewed by the time-of-day component of [_selectedDay].
  DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Expense> _filterExpensesByPeriod(List<Expense> expenses) {
    final day = _midnight(_selectedDay);
    switch (_selectedPeriod) {
      case 'daily':
        return expenses.where((e) => isSameDay(e.timestamp, day)).toList();
      case 'weekly':
        // Week starts on Monday 00:00, ends before the following Monday 00:00
        final weekStart = day.subtract(Duration(days: day.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7)); // exclusive
        return expenses
            .where(
              (e) =>
                  !e.timestamp.isBefore(weekStart) &&
                  e.timestamp.isBefore(weekEnd),
            )
            .toList();
      case 'monthly':
        return expenses
            .where(
              (e) =>
                  e.timestamp.year == day.year &&
                  e.timestamp.month == day.month,
            )
            .toList();
      case 'yearly':
        return expenses.where((e) => e.timestamp.year == day.year).toList();
      case 'alltime':
      default:
        return expenses;
    }
  }

  // Mirrors _filterExpensesByPeriod for Income records.
  List<Income> _filterIncomesByPeriod(List<Income> incomes) {
    final day = _midnight(_selectedDay);
    switch (_selectedPeriod) {
      case 'daily':
        return incomes.where((i) => isSameDay(i.timestamp, day)).toList();
      case 'weekly':
        final weekStart = day.subtract(Duration(days: day.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7)); // exclusive
        return incomes
            .where(
              (i) =>
                  !i.timestamp.isBefore(weekStart) &&
                  i.timestamp.isBefore(weekEnd),
            )
            .toList();
      case 'monthly':
        return incomes
            .where(
              (i) =>
                  i.timestamp.year == day.year &&
                  i.timestamp.month == day.month,
            )
            .toList();
      case 'yearly':
        return incomes.where((i) => i.timestamp.year == day.year).toList();
      case 'alltime':
      default:
        return incomes;
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
          boxShadow:
              showGlow
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
  void _showMiningSuccessSnackBar(
    BuildContext context,
    double amount,
    int ore,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.cyan.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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

  // Responsive Action Button Builder
  Widget _buildResponsiveActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool showGlow = true,
    bool compact = false,
  }) {
    final buttonWidth = compact ? 130.0 : 160.0;
    final buttonHeight = compact ? 50.0 : 60.0;
    final iconSize = compact ? 18.0 : 20.0;
    final fontSize = compact ? 10.0 : 12.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: buttonWidth,
        height: buttonHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('lib/assets/button.png'),
            fit: BoxFit.fill,
          ),
          boxShadow:
              showGlow
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
            Icon(icon, color: Colors.white, size: iconSize),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action Buttons Row Builder - fits inside transaction/analytics panel
  Widget _buildActionButtonsRow({
    required bool isCompact,
    required bool isMobile,
  }) {
    final spacing = isCompact ? 8.0 : 12.0;
    final padding = isCompact ? 8.0 : 12.0;

    if (isMobile) {
      // Vertical stack for mobile
      return Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResponsiveActionButton(
              onPressed: () => _openAddIncomeSheet(context),
              icon: Icons.download,
              label: 'INCOME',
              color: Colors.cyan,
              compact: true,
            ),
            SizedBox(height: spacing),
            _buildResponsiveActionButton(
              onPressed: () => _openAddExpenseSheet(context),
              icon: Icons.upload,
              label: 'EXPENSE',
              color: Colors.orange,
              showGlow: false,
              compact: true,
            ),
          ],
        ),
      );
    } else {
      // Horizontal row for larger screens
      return Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: _buildResponsiveActionButton(
                onPressed: () => _openAddIncomeSheet(context),
                icon: Icons.download,
                label: 'INCOME',
                color: Colors.cyan,
                compact: isCompact,
              ),
            ),
            SizedBox(width: spacing),
            Flexible(
              child: _buildResponsiveActionButton(
                onPressed: () => _openAddExpenseSheet(context),
                icon: Icons.upload,
                label: 'EXPENSE',
                color: Colors.orange,
                showGlow: false,
                compact: isCompact,
              ),
            ),
          ],
        ),
      );
    }
  }

  // Responsive Calendar Widget Builder
  Widget _buildResponsiveCalendar({required bool isCompact}) {
    final rowHeight = isCompact ? 40.0 : 52.0;
    final headerFontSize = isCompact ? 14.0 : 16.0;
    final dayFontSize = isCompact ? 12.0 : 14.0;

    return Column(
      children: [
        // Format toggle buttons for compact view
        if (isCompact)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCalendarFormatButton('Month', CalendarFormat.month),
                const SizedBox(width: 8),
                _buildCalendarFormatButton('2 Weeks', CalendarFormat.twoWeeks),
                const SizedBox(width: 8),
                _buildCalendarFormatButton('Week', CalendarFormat.week),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 weeks',
                CalendarFormat.week: 'Week',
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                cellMargin: EdgeInsets.all(isCompact ? 2 : 4),
                rowDecoration: BoxDecoration(),
                defaultTextStyle: TextStyle(
                  color: const Color(0xFFBBDEFF),
                  fontSize: dayFontSize,
                ),
                weekendTextStyle: TextStyle(
                  color: const Color(0xFFBBDEFF),
                  fontSize: dayFontSize,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF00D9FF),
                  shape: BoxShape.circle,
                ),
                todayDecoration: const BoxDecoration(
                  color: Color(0xFF00B8D4),
                  shape: BoxShape.circle,
                ),
                defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
                weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
              ),
              rowHeight: rowHeight,
              daysOfWeekHeight: isCompact ? 20 : 24,
              headerStyle: HeaderStyle(
                formatButtonVisible: !isCompact,
                formatButtonTextStyle: TextStyle(
                  color: const Color(0xFF00D9FF),
                  fontSize: isCompact ? 10 : 12,
                ),
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00D9FF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                titleTextStyle: TextStyle(
                  color: const Color(0xFF00D9FF),
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: const Color(0xFF00D9FF),
                  size: isCompact ? 20 : 24,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF00D9FF),
                  size: isCompact ? 20 : 24,
                ),
                headerPadding: EdgeInsets.symmetric(
                  vertical: isCompact ? 8 : 12,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: const Color(0xFF00D9FF),
                  fontSize: isCompact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  color: const Color(0xFF00D9FF),
                  fontSize: isCompact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Calendar Format Button Builder
  Widget _buildCalendarFormatButton(String label, CalendarFormat format) {
    final isActive = _calendarFormat == format;
    return GestureDetector(
      onTap: () {
        setState(() {
          _calendarFormat = format;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFF00D9FF).withOpacity(0.2)
                  : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF00D9FF) : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00D9FF) : const Color(0xFFBBDEFF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Responsive Transaction List Builder
  Widget _buildResponsiveTransactionList(
    List<Map<String, dynamic>> transactions,
  ) {
    return transactions.isEmpty
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
              return _buildTransactionCard(
                title: income.category,
                subtitle: 'INCOME',
                subtitleColor: Colors.green.shade300,
                amount: '+\$${income.amount.toStringAsFixed(2)}',
                amountColor: Colors.green.shade300,
                isIncome: true,
              );
            } else {
              final expense = transaction['item'] as Expense;
              return _buildTransactionCard(
                title: expense.category,
                subtitle: expense.isWant ? 'WANT' : 'NEED',
                subtitleColor: expense.isWant ? Colors.orange : Colors.green,
                amount: '-\$${expense.amount.toStringAsFixed(2)}',
                amountColor: const Color(0xFF00D9FF),
                isIncome: false,
              );
            }
          },
        );
  }

  // Transaction Card Builder — enhanced glassmorphism with accent bar
  Widget _buildTransactionCard({
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required String amount,
    required Color amountColor,
    required bool isIncome,
  }) {
    final accentColor =
        isIncome
            ? const Color(0xFF00E676) // green for income
            : const Color(0xFFFF6D00); // orange for expense

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Color(0xFFE0FFFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Pill-style subtitle badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: subtitleColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: subtitleColor.withOpacity(0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            amount,
                            style: TextStyle(
                              color: amountColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
