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

  // ── Week Strip (mobile) ────────────────────────────────────────────────────
  static const double _podWidth = 62.0;
  static const int _pastDays = 365;
  static const int _futureDays = 0; // Disabled future dates per user request

  // 730-day list: index 0 = 365 days ago, index 365 = today
  late final List<DateTime> _dateList;
  late final ScrollController _weekStripController;

  // Month currently shown in the nav header (independent of _selectedDay)
  late DateTime _focusedMonth;

  // Responsive breakpoints
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;

  bool _isCompactLayout(double width) => width < _tabletBreakpoint;
  bool _isMobileLayout(double width) => width < _mobileBreakpoint;

  @override
  void initState() {
    super.initState();
    // Build date list centred on today
    final today = DateTime.now();
    _focusedMonth = DateTime(today.year, today.month);
    _dateList = List.generate(
      _pastDays + _futureDays + 1,
      (i) => DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: i - _pastDays)),
    );
    // Auto-scroll so today (which is now the last item at index _pastDays) is visible
    // We intentionally scroll to the maximum possible extent.
    final initialOffset = (_pastDays * (_podWidth + 8)).toDouble();
    _weekStripController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _weekStripController.dispose();
    super.dispose();
  }

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
              _buildResponsiveCalendar(isCompact: isCompact),
              SizedBox(height: isCompact ? 8 : 12),
              // Premium Analytics Toggle Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                  vertical: 4,
                ),
                child: _buildAnalyticsToggleButton(
                  isAnalytics: false,
                  isCompact: isCompact,
                ),
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
          // Mobile: compact week strip at top, full-height transaction panel below
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              children: [
                // ── Week Strip + toggle row ──
                _buildMobileHeader(isAnalytics: false, isCompact: isCompact),
                const SizedBox(height: 8),
                // Transaction list fills remaining space
                Expanded(child: transactionPanel),
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
              _buildResponsiveCalendar(isCompact: isCompact),
              SizedBox(height: isCompact ? 8 : 12),
              // Premium Analytics Toggle Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 10 : 14,
                  vertical: 4,
                ),
                child: _buildAnalyticsToggleButton(
                  isAnalytics: true,
                  isCompact: isCompact,
                ),
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
          // Mobile: compact week strip at top, full-height analytics panel below
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              children: [
                // ── Week Strip + toggle row ──
                _buildMobileHeader(isAnalytics: true, isCompact: isCompact),
                const SizedBox(height: 8),
                // Analytics fills remaining space
                Expanded(child: analyticsPanel),
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

    final double pieRadius = isCompact ? 80.0 : 130.0;
    final double centerSpace = isCompact ? 28.0 : 46.0;

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
        // ── Top controls bar: period display + EXP/INC toggle + chart type ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 8 : 12,
            isCompact ? 6 : 10,
            isCompact ? 8 : 12,
            0,
          ),
          child: Row(
            children: [
              // Period display text
              Expanded(
                child: Text(
                  _getPeriodDisplayText(),
                  style: TextStyle(
                    color: const Color(0xFF00D9FF),
                    fontSize: isCompact ? 9 : 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // EXP / INC pie-mode chips
              _buildMiniChip(
                label: 'EXP',
                active: _pieChartMode == 'expenses',
                activeColor: Colors.orange,
                onTap: () => setState(() => _pieChartMode = 'expenses'),
                isCompact: isCompact,
              ),
              const SizedBox(width: 4),
              _buildMiniChip(
                label: 'INC',
                active: _pieChartMode == 'incomes',
                activeColor: const Color(0xFF00E676),
                onTap: () => setState(() => _pieChartMode = 'incomes'),
                isCompact: isCompact,
              ),
              // Chart-type toggle (compact only)
              if (isCompact) ...[
                const SizedBox(width: 6),
                _buildMiniChip(
                  label: 'PIE',
                  active: _analyticsChartShow == 'pie',
                  activeColor: const Color(0xFF00D9FF),
                  onTap: () => setState(() => _analyticsChartShow = 'pie'),
                  isCompact: isCompact,
                ),
                const SizedBox(width: 4),
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
        const SizedBox(height: 6),
        // ── Period filter chips: horizontal scroll row ─────────────────────
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 10),
            children: [
              _buildNeonPeriodChip('DAY', 'daily'),
              const SizedBox(width: 6),
              _buildNeonPeriodChip('WEEK', 'weekly'),
              const SizedBox(width: 6),
              _buildNeonPeriodChip('MONTH', 'monthly'),
              const SizedBox(width: 6),
              _buildNeonPeriodChip('YEAR', 'yearly'),
              const SizedBox(width: 6),
              _buildNeonPeriodChip('ALL', 'alltime'),
            ],
          ),
        ),
        const SizedBox(height: 6),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 7 : 10,
              vertical: isCompact ? 3 : 5,
            ),
            decoration: BoxDecoration(
              color: active ? activeColor.withOpacity(0.18) : Colors.black38,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? activeColor : Colors.white24,
                width: active ? 1.5 : 1,
              ),
              boxShadow:
                  active
                      ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                      : [],
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
        ),
      ),
    );
  }

  /// Neon period filter chip used in the horizontal scroll row.
  Widget _buildNeonPeriodChip(String label, String period) {
    final isActive = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:
              isActive
                  ? const Color(0xFF00D9FF).withOpacity(0.15)
                  : Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF00D9FF) : Colors.white24,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: const Color(0xFF00D9FF).withOpacity(0.45),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                  : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF00D9FF) : const Color(0xFFBBDEFF),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // Neon Data Rod Bar Chart
  Widget _buildBarChartWidget(
    List<Income> incomes,
    List<Expense> expenses, {
    bool isCompact = false,
  }) {
    return BarChart(
      BarChartData(
        barGroups: _getBarChartData(incomes, expenses),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        backgroundColor: Colors.transparent,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isCompact ? 24 : 28,
              getTitlesWidget: (value, meta) {
                const labels = ['INCOME', 'EXPENSE'];
                const colors = [Color(0xFF00E5FF), Color(0xFFFF6D00)];
                final idx = value.toInt();
                if (idx >= 0 && idx < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      labels[idx],
                      style: TextStyle(
                        color: colors[idx],
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 8 : 9,
                        letterSpacing: 0.8,
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
              reservedSize: isCompact ? 38 : 48,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max)
                  return const SizedBox();
                final label =
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(1)}k'
                        : value.toInt().toString();
                return Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFFBBDEFF).withOpacity(0.6),
                    fontSize: isCompact ? 8 : 9,
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

  // Holographic Donut Chart with legend
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
              Icons.donut_large_outlined,
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              emptyLabel,
              style: const TextStyle(color: Color(0xFFBBDEFF), fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Aggregate by category
    final Map<String, double> totals = {};
    for (final item in items) {
      final cat = categoryFn(item);
      totals[cat] = (totals[cat] ?? 0) + amountFn(item);
    }

    const colors = [
      Color(0xFF00D9FF),
      Color(0xFF7C4DFF),
      Color(0xFFFF6D00),
      Color(0xFF00E676),
      Color(0xFFFF4081),
      Color(0xFF40C4FF),
      Color(0xFFFFD740),
      Color(0xFFE040FB),
    ];

    final total = totals.values.fold(0.0, (s, v) => s + v);
    final entries = totals.entries.toList();

    // Sections — thin donut ring
    final sections =
        entries.asMap().entries.map((e) {
          final i = e.key;
          final entry = e.value;
          return PieChartSectionData(
            value: entry.value,
            title: '',
            showTitle: false,
            color: colors[i % colors.length],
            radius: radius * 0.38, // thin donut ring
            borderSide: const BorderSide(color: Colors.transparent, width: 0),
          );
        }).toList();

    // Center label
    final totalStr =
        total >= 1000
            ? '₹${(total / 1000).toStringAsFixed(1)}k'
            : '₹${total.toStringAsFixed(0)}';

    return Column(
      children: [
        // ── Donut + centered total ──
        Expanded(
          flex: 6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: centerSpaceRadius * 1.8,
                  sectionsSpace: 2.5,
                  pieTouchData: PieTouchData(enabled: false),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalStr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius < 90 ? 15 : 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00D9FF).withOpacity(0.9),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      color: const Color(0xFF00D9FF).withOpacity(0.75),
                      fontSize: radius < 90 ? 8 : 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ── Scrollable legend ──
        Expanded(
          flex: 4,
          child: ListView.builder(
            itemCount: entries.length,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemBuilder: (ctx, i) {
              final entry = entries[i];
              final pct = total > 0 ? (entry.value / total * 100) : 0.0;
              final amtStr =
                  entry.value >= 1000
                      ? '₹${(entry.value / 1000).toStringAsFixed(1)}k'
                      : '₹${entry.value.toStringAsFixed(0)}';
              final color = colors[i % colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    // Color dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category name
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Percentage
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFFBBDEFF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount
                    Text(
                      amtStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _getBarChartData(
    List<Income> incomes,
    List<Expense> expenses,
  ) {
    final totalIncome = incomes.fold(0.0, (s, i) => s + i.amount);
    final totalExpenses = expenses.fold(0.0, (s, e) => s + e.amount);
    const double rodWidth = 32;
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: totalIncome,
            width: rodWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF005B7F), Color(0xFF00E5FF)],
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY:
                  totalIncome == 0 && totalExpenses == 0
                      ? 100
                      : (totalIncome > totalExpenses
                              ? totalIncome
                              : totalExpenses) *
                          1.1,
              color: const Color(0xFF00D9FF).withOpacity(0.07),
            ),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: totalExpenses,
            width: rodWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF7A1800), Color(0xFFFF6D00)],
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY:
                  totalIncome == 0 && totalExpenses == 0
                      ? 100
                      : (totalIncome > totalExpenses
                              ? totalIncome
                              : totalExpenses) *
                          1.1,
              color: const Color(0xFFFF6D00).withOpacity(0.07),
            ),
          ),
        ],
      ),
    ];
  }

  /// Shared premium analytics toggle button — used on both mobile and desktop.
  Widget _buildAnalyticsToggleButton({
    required bool isAnalytics,
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _showAnalytics = !_showAnalytics),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isCompact ? 9 : 12,
            ),
            decoration: BoxDecoration(
              color:
                  isAnalytics
                      ? const Color(0xFF7C4DFF).withOpacity(0.15)
                      : const Color(0xFF00D9FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isAnalytics
                        ? const Color(0xFF7C4DFF).withOpacity(0.7)
                        : const Color(0xFF00D9FF).withOpacity(0.4),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      isAnalytics
                          ? const Color(0xFF7C4DFF).withOpacity(0.28)
                          : const Color(0xFF00D9FF).withOpacity(0.14),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Gradient icon circle
                Container(
                  width: isCompact ? 30 : 36,
                  height: isCompact ? 30 : 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        isAnalytics
                            ? const LinearGradient(
                              colors: [Color(0xFF4A148C), Color(0xFF9C27B0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : const LinearGradient(
                              colors: [Color(0xFF006064), Color(0xFF00E5FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isAnalytics
                                ? const Color(0xFF7C4DFF).withOpacity(0.5)
                                : const Color(0xFF00D9FF).withOpacity(0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isAnalytics
                        ? Icons.bar_chart_rounded
                        : Icons.analytics_outlined,
                    color: Colors.white,
                    size: isCompact ? 15 : 18,
                  ),
                ),
                SizedBox(width: isCompact ? 10 : 12),
                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAnalytics ? 'HIDE ANALYTICS' : 'SHOW ANALYTICS',
                        style: TextStyle(
                          color:
                              isAnalytics
                                  ? const Color(0xFFCE93D8)
                                  : const Color(0xFF00D9FF),
                          fontSize: isCompact ? 11 : 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        isAnalytics
                            ? 'Back to transactions'
                            : 'Charts & insights',
                        style: TextStyle(
                          color:
                              isAnalytics
                                  ? const Color(0xFFCE93D8).withOpacity(0.6)
                                  : const Color(0xFF00D9FF).withOpacity(0.55),
                          fontSize: isCompact ? 8 : 9,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  isAnalytics
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color:
                      isAnalytics
                          ? const Color(0xFFCE93D8).withOpacity(0.7)
                          : const Color(0xFF00D9FF).withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
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

  // Premium Glassmorphic Action Button
  Widget _buildResponsiveActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Gradient gradient,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 20,
              vertical: compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.45), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.22),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child:
                compact
                    // ---- Compact pill (mobile row) ----
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: gradient,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.45),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 17),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: color.withOpacity(0.6),
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                    // ---- Wide card (desktop row) ----
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: gradient,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: color.withOpacity(0.6),
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }

  // Action Buttons Row Builder - fits inside transaction/analytics panel
  Widget _buildActionButtonsRow({
    required bool isCompact,
    required bool isMobile,
  }) {
    final padding = isCompact ? 8.0 : 12.0;

    const incomeGradient = LinearGradient(
      colors: [Color(0xFF006064), Color(0xFF00E5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    const expenseGradient = LinearGradient(
      colors: [Color(0xFF7A1800), Color(0xFFFF6D00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final incomeBtn = _buildResponsiveActionButton(
      onPressed: () => _openAddIncomeSheet(context),
      icon: Icons.south_west_rounded,
      label: 'INCOME',
      subtitle: 'Add a receipt',
      color: const Color(0xFF00E5FF),
      gradient: incomeGradient,
      compact: isMobile,
    );
    final expenseBtn = _buildResponsiveActionButton(
      onPressed: () => _openAddExpenseSheet(context),
      icon: Icons.north_east_rounded,
      label: 'EXPENSE',
      subtitle: 'Log a payment',
      color: const Color(0xFFFF6D00),
      gradient: expenseGradient,
      compact: isMobile,
    );

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
        child: Row(
          children: [
            Expanded(child: incomeBtn),
            const SizedBox(width: 10),
            Expanded(child: expenseBtn),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: incomeBtn),
            SizedBox(width: isCompact ? 10 : 16),
            Flexible(child: expenseBtn),
          ],
        ),
      );
    }
  }

  // ── Navigational Chronometer (Mobile Week Strip) ──────────────────────────

  /// Scrolls the week strip to the 1st of [month] with smooth animation.
  void _jumpToMonth(DateTime month) {
    final origin = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final target = DateTime(month.year, month.month, 1);
    final diff = target.difference(origin).inDays;
    final index = (_pastDays + diff).clamp(0, _dateList.length - 1);
    final offset = (index * (_podWidth + 10)).toDouble();
    _weekStripController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() => _focusedMonth = month);
  }

  /// Compact header for mobile: month nav + week strip + analytics toggle.
  Widget _buildMobileHeader({
    required bool isAnalytics,
    required bool isCompact,
  }) {
    const monthNames = [
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Month / Year Navigation ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              _buildNavArrow(Icons.chevron_left, () {
                _jumpToMonth(
                  DateTime(_focusedMonth.year, _focusedMonth.month - 1),
                );
              }),
              Expanded(
                child: Text(
                  '${monthNames[_focusedMonth.month - 1]}  ${_focusedMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF00D9FF),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              _buildNavArrow(Icons.chevron_right, () {
                _jumpToMonth(
                  DateTime(_focusedMonth.year, _focusedMonth.month + 1),
                );
              }),
            ],
          ),
        ),
        _buildWeekStrip(),
        const SizedBox(height: 6),
        // ── Analytics Toggle Button (premium card) ──
        _buildAnalyticsToggleButton(
          isAnalytics: isAnalytics,
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF00D9FF).withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.4)),
        ),
        child: Icon(icon, color: const Color(0xFF00D9FF), size: 18),
      ),
    );
  }

  /// Horizontal scrollable row of glassmorphic date pods.
  Widget _buildWeekStrip() {
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
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
    final today = DateTime.now();

    return SizedBox(
      height: 96,
      child: ListView.builder(
        controller: _weekStripController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        itemCount: _dateList.length,
        itemBuilder: (context, index) {
          final date = _dateList[index];
          final isSelected = isSameDay(date, _selectedDay);
          final isToday = isSameDay(date, today);
          final weekdayLabel = weekdays[date.weekday - 1];
          final monthLabel = months[date.month - 1];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = date;
                _focusedDay = date;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _podWidth,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF00D9FF).withOpacity(0.20)
                              : Colors.black.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF00D9FF)
                                : Colors.white24,
                        width: isSelected ? 1.6 : 1.0,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00D9FF,
                                  ).withOpacity(0.35),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ]
                              : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Weekday
                        Text(
                          weekdayLabel,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? const Color(0xFF00D9FF)
                                    : const Color(0xFFBBDEFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Day number
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color:
                                isSelected
                                    ? const Color(0xFF00D9FF)
                                    : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Month abbrev
                        Text(
                          monthLabel,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? const Color(0xFF00D9FF).withOpacity(0.8)
                                    : const Color(0xFFBBDEFF),
                            fontSize: 9,
                            letterSpacing: 0.3,
                          ),
                        ),
                        // Today dot indicator
                        if (isToday) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected
                                      ? const Color(0xFF00D9FF)
                                      : const Color(
                                        0xFF00D9FF,
                                      ).withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Responsive Calendar Widget Builder (tablet/desktop only)
  Widget _buildResponsiveCalendar({required bool isCompact}) {
    final rowHeight = isCompact ? 40.0 : 52.0;
    final headerFontSize = isCompact ? 14.0 : 16.0;
    final dayFontSize = isCompact ? 12.0 : 14.0;

    return Expanded(
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
          onFormatChanged: (format) => setState(() => _calendarFormat = format),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            cellMargin: EdgeInsets.all(isCompact ? 2 : 4),
            rowDecoration: const BoxDecoration(),
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
            headerPadding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 12),
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
