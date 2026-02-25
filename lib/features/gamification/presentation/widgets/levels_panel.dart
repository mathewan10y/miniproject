import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Data model for a single lesson within a level.
class LevelLesson {
  final String code;
  final String title;
  final String? subtitle;
  const LevelLesson(this.code, this.title, {this.subtitle});
}

/// Data model for a level (0–6).
class LevelData {
  final int number;
  final String name;
  final String subtitle;
  final Color color;
  final IconData icon;
  final List<LevelLesson> lessons;
  const LevelData({
    required this.number,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.lessons,
  });
}

/// All 7 levels, hardcoded for frontend demo.
const _levels = <LevelData>[
  LevelData(
    number: 0,
    name: 'The Academy',
    subtitle: 'Life Support',
    color: Color(0xFF4FC3F7),
    icon: Icons.school_outlined,
    lessons: [
      LevelLesson('0.1', 'Power Generation', subtitle: 'Active vs. Passive Income'),
      LevelLesson('0.2', 'Hull Breaches', subtitle: 'Managing Needs vs. Wants'),
      LevelLesson('0.3', 'The Flow Gauge', subtitle: 'Maintaining Positive Cash Flow'),
      LevelLesson('0.4', 'Emergency Shield', subtitle: '6-month safety net before orbit'),
    ],
  ),
  LevelData(
    number: 1,
    name: 'Ground School',
    subtitle: 'The Shipyard',
    color: Color(0xFF81C784),
    icon: Icons.construction_outlined,
    lessons: [
      LevelLesson('1.1', 'The Shipyard', subtitle: 'How NSE/BSE & Brokers function'),
      LevelLesson('1.2', 'The Launch', subtitle: 'Primary market mechanics (IPOs)'),
      LevelLesson('1.3', 'Convoy Protocols', subtitle: 'Mutual Funds, ETFs & Index Funds'),
    ],
  ),
  LevelData(
    number: 2,
    name: 'Navigation',
    subtitle: 'Star Mapping',
    color: Color(0xFFFFD54F),
    icon: Icons.explore_outlined,
    lessons: [
      LevelLesson('2.1', 'Star Charts', subtitle: 'Reading Candlesticks (Price Action)'),
      LevelLesson('2.2', 'Gravitational Pull', subtitle: 'Identifying Trends & Cycles'),
      LevelLesson('2.3', 'Shield Placements', subtitle: 'Support & Resistance lines'),
      LevelLesson('2.4', 'Navigation Tools', subtitle: 'Indicators: MA, RSI, etc.'),
    ],
  ),
  LevelData(
    number: 3,
    name: 'Engineering',
    subtitle: 'Reactor Diagnostics',
    color: Color(0xFFFF8A65),
    icon: Icons.engineering_outlined,
    lessons: [
      LevelLesson('3.1', 'Hull Integrity', subtitle: 'Balance Sheets & P&L Statements'),
      LevelLesson('3.2', 'Efficiency Ratios', subtitle: 'P/E, ROE, Debt-to-Equity'),
      LevelLesson('3.3', 'Cargo Harvest', subtitle: 'Dividends, Splits & Buybacks'),
    ],
  ),
  LevelData(
    number: 4,
    name: 'Hyperdrive',
    subtitle: 'Warp Speed',
    color: Color(0xFFE040FB),
    icon: Icons.rocket_launch_outlined,
    lessons: [
      LevelLesson('4.1', 'Afterburners', subtitle: 'Leverage & large positions'),
      LevelLesson('4.2', 'Space Contracts', subtitle: 'Futures trading'),
      LevelLesson('4.3', 'Strategic Shields', subtitle: 'Options (Calls, Puts) & Hedging'),
    ],
  ),
  LevelData(
    number: 5,
    name: 'Crisis Mgmt',
    subtitle: 'Asteroid Field',
    color: Color(0xFFEF5350),
    icon: Icons.warning_amber_outlined,
    lessons: [
      LevelLesson('5.1', 'Cosmic Storms', subtitle: 'Inflation, Interest Rates & GDP'),
      LevelLesson('5.2', 'Space Madness', subtitle: 'Fear, Greed & FOMO'),
      LevelLesson('5.3', 'Auto-Eject', subtitle: 'Stop-Losses & Position Sizing'),
    ],
  ),
  LevelData(
    number: 6,
    name: 'The Outer Rim',
    subtitle: 'Uncharted Space',
    color: Color(0xFF7E57C2),
    icon: Icons.language_outlined,
    lessons: [
      LevelLesson('6.1', 'Distributed Logs', subtitle: 'Understanding the Blockchain'),
      LevelLesson('6.2', 'The Vaults', subtitle: 'Keys, Wallets & Custody'),
      LevelLesson('6.3', 'Rogue Tokens', subtitle: 'Spotting Rug Pulls & Ponzi'),
      LevelLesson('6.4', 'Imperial Tax', subtitle: 'STCG/LTCG & 30% Crypto tax'),
    ],
  ),
];

class LevelsPanel extends StatefulWidget {
  const LevelsPanel({super.key});

  @override
  State<LevelsPanel> createState() => _LevelsPanelState();
}

class _LevelsPanelState extends State<LevelsPanel> {
  int? _expandedLevel; // Which level is currently expanded
  bool _isCollapsed = false; // Whether the whole panel is collapsed

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Responsive panel width: 28% of screen, but at least 260px and at most 450px
    final panelWidth = (screenW * 0.28).clamp(260.0, 450.0); 
    final collapsedWidth = 40.0; // Just enough for the expand button
    final currentWidth = _isCollapsed ? collapsedWidth : panelWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: currentWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17).withAlpha(230),
        border: const Border(
          right: BorderSide(color: Color(0xFF1A2A3A), width: 1),
        ),
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: panelWidth,
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60), // Space for TopBar
          
          // Collapse / Expand toggle button
          GestureDetector(
            onTap: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                children: [
                   if (!_isCollapsed) ...[
                      const Icon(Icons.account_tree_outlined,
                          color: Color(0xFF00D9FF), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MISSION LEVELS',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF00D9FF),
                            fontSize: 12, // Increased font
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                   ],
                   Icon(
                     _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                     color: const Color(0xFF00D9FF),
                     size: 24, // Bigger arrow
                   )
                ],
              ),
            ),
          ),
          
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFF1A2A3A),
          ),
          
          // Level list (hidden if collapsed)
          if (!_isCollapsed)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _levels.length,
                itemBuilder: (ctx, i) => _buildLevelTile(_levels[i]),
              ),
            ),
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelTile(LevelData level) {
    final isExpanded = _expandedLevel == level.number;

    return Column(
      children: [
        // Level button
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedLevel = isExpanded ? null : level.number;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isExpanded
                  ? level.color.withAlpha(25)
                  : Colors.white.withAlpha(5),
              border: Border(
                left: BorderSide(
                  color: isExpanded ? level.color : Colors.transparent,
                  width: 3,
                ),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                // Level number badge
                Container(
                  width: 28, // Bigger badge
                  height: 28,
                  decoration: BoxDecoration(
                    color: level.color.withAlpha(30),
                    border: Border.all(color: level.color.withAlpha(80)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${level.number}',
                    style: GoogleFonts.orbitron(
                      color: level.color,
                      fontSize: 14, // Increased
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.name,
                        style: GoogleFonts.shareTechMono(
                          color: isExpanded ? level.color : Colors.white70,
                          fontSize: 13, // Increased from 11
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.subtitle,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white54,
                          fontSize: 11, // Increased from 9
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Arrow
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: isExpanded ? level.color : Colors.white30,
                    size: 20, // Increased
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded lessons
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildLessonList(level),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildLessonList(LevelData level) {
    return Column(
      children: level.lessons.map((lesson) {
        return GestureDetector(
          onTap: () {
            // TODO: Backend integration — navigate to lesson content
          },
          child: Container(
            margin: const EdgeInsets.only(left: 32, right: 8, top: 2, bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              border: Border(
                left: BorderSide(
                  color: level.color.withAlpha(50),
                  width: 2,
                ),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                // Lesson code
                SizedBox(
                  width: 30, // Increased
                  child: Text(
                    lesson.code,
                    style: GoogleFonts.shareTechMono(
                      color: level.color.withAlpha(200),
                      fontSize: 11, // Increased
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Lesson title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white70,
                          fontSize: 12, // Increased
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      if (lesson.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          lesson.subtitle!,
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white30,
                            fontSize: 10, // Increased
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

