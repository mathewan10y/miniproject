import '../domain/models/varsity_level.dart';

class VarsityService {
  List<VarsityLevel> getLevels() {
    return [
      const VarsityLevel(
        id: 'lvl1',
        title: 'Level 1',
        name: 'The Recruit',
        description: 'Understanding the battlefield. Basic Training.',
        modules: [
          'Module 1: Introduction to Stock Markets (IPOs, Indices, Regulators)',
          'Module 7: Markets & Taxation (Why taxes exist, basic rules)',
          'App Feature: Simple quizzes. "What is an IPO?"',
        ],
        isLocked: false,
      ),
      const VarsityLevel(
        id: 'lvl2',
        title: 'Level 2',
        name: 'The Scout',
        description: 'Technical Analysis. Visual pattern recognition.',
        modules: [
          'Module 2: Technical Analysis (Candlesticks, Support/Resistance)',
          'Module 10: Trading Systems (Basic setups)',
          'App Feature: Chart Pattern Recognition (Doji, Head & Shoulders)',
        ],
        isLocked: true,
      ),
      const VarsityLevel(
        id: 'lvl3',
        title: 'Level 3',
        name: 'The Strategist',
        description: 'Fundamental Analysis. Reading the business.',
        modules: [
          'Module 3: Fundamental Analysis (P&L, Balance Sheets)',
          'Module 7: Markets & Taxation (Advanced tax implications)',
          'App Feature: "Buy or Sell?" scenarios based on P/E ratio',
        ],
        isLocked: true,
      ),
      const VarsityLevel(
        id: 'lvl4',
        title: 'Level 4',
        name: 'The Speculator',
        description: 'Futures & Options. High risk, high reward.',
        modules: [
          'Module 4: Futures Trading',
          'Module 5: Options Theory (Greeks)',
          'Module 6: Option Strategies',
          'Module 9: Risk Management & Psychology',
        ],
        isLocked: true,
      ),
    ];
  }
}
