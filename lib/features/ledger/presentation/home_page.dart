import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../gamification/analysis_tab.dart';
import '../../gamification/credit_vault_widget.dart';
import 'add_expense_sheet.dart';
import 'expenses_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const AddExpenseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CyberFinance Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily Expenses'),
            Tab(text: 'Analysis'),
          ],
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CreditVault(tradingPower: 0.00), // Dummy data
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    ExpensesTab(),
                    AnalysisTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddExpenseSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
