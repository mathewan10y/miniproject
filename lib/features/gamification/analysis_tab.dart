import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../ledger/expense_provider.dart';

enum TimeFrame { Daily, Weekly, Yearly }

class AnalysisTab extends ConsumerStatefulWidget {
  const AnalysisTab({super.key});

  @override
  ConsumerState<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends ConsumerState<AnalysisTab> {
  TimeFrame _selectedTimeFrame = TimeFrame.Daily;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);

    return expensesAsync.when(
      data: (expenses) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ToggleButtons(
                isSelected: TimeFrame.values.map((e) => e == _selectedTimeFrame).toList(),
                onPressed: (index) {
                  setState(() {
                    _selectedTimeFrame = TimeFrame.values[index];
                  });
                },
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Daily')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Weekly')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Yearly')),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sections: _getPieChartData(expenses),
                            ),
                          ),
                        ),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              barGroups: _getBarChartData(expenses),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Financial Advice: You are spending a lot on food. Consider cooking at home more often.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  List<PieChartSectionData> _getPieChartData(List<dynamic> expenses) {
    // In a real app, you would process expenses to generate this data
    return [
      PieChartSectionData(value: 40, title: 'Food', color: Colors.blue),
      PieChartSectionData(value: 30, title: 'Shopping', color: Colors.red),
      PieChartSectionData(value: 30, title: 'Transport', color: Colors.green),
    ];
  }

  List<BarChartGroupData> _getBarChartData(List<dynamic> expenses) {
    // In a real app, you would process expenses to generate this data
    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8)]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14)]),
    ];
  }
}
