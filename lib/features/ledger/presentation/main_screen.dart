import 'package:flutter/material.dart';
import 'reactor_core_page.dart';
import 'logistics_page.dart';
import 'flight_deck_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Initialize with page 1 (center/reactor core)
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: const [
          LogisticsPage(), // Page 0 - Left
          ReactorCorePage(), // Page 1 - Center (Default)
          FlightDeckPage(), // Page 2 - Right
        ],
      ),
    );
  }
}
