import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../user_stats_provider.dart';
import '../../services/tutorial_engine_service.dart';
import '../../data/tutorial_scripts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'tutorial_overlay_widget.dart';
import 'mini_quiz_sheet.dart';
import '../pages/boss_fight_screen.dart';

// ─── Level metadata ────────────────────────────────────────────

class _LevelMeta {
  final int level;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String assetPath;
  const _LevelMeta({
    required this.level, required this.title, required this.subtitle,
    required this.accent, required this.icon, required this.assetPath,
  });
}

const _levels = <_LevelMeta>[
  _LevelMeta(level: 0, title: 'THE ACADEMY',         subtitle: 'Life Support',      accent: Color(0xFF4FC3F7), icon: Icons.school_outlined,         assetPath: 'lib/assets/documents/level0'),
  _LevelMeta(level: 1, title: 'GROUND SCHOOL',        subtitle: 'The Shipyard',      accent: Color(0xFF66BB6A), icon: Icons.construction_outlined,   assetPath: 'lib/assets/documents/level1'),
  _LevelMeta(level: 2, title: 'NAVIGATION',           subtitle: 'Star Mapping',      accent: Color(0xFFFFD54F), icon: Icons.explore_outlined,         assetPath: 'lib/assets/documents/level2'),
  _LevelMeta(level: 3, title: 'ENGINEERING',          subtitle: 'Reactor Diag.',     accent: Color(0xFFFF8A65), icon: Icons.engineering_outlined,     assetPath: 'lib/assets/documents/level3'),
  _LevelMeta(level: 4, title: 'HYPERDRIVE',           subtitle: 'Warp Speed',        accent: Color(0xFFCE93D8), icon: Icons.rocket_launch_outlined,   assetPath: 'lib/assets/documents/level4'),
  _LevelMeta(level: 5, title: 'CRISIS MGMT',          subtitle: 'Asteroid Field',    accent: Color(0xFFEF9A9A), icon: Icons.shield_outlined,          assetPath: 'lib/assets/documents/level5'),
  _LevelMeta(level: 6, title: 'THE OUTER RIM',        subtitle: 'Uncharted Space',   accent: Color(0xFFB39DDB), icon: Icons.language_outlined,        assetPath: 'lib/assets/documents/level6'),
];

// ─── Main widget ───────────────────────────────────────────────

class AcademyCodexDialog extends ConsumerStatefulWidget {
  const AcademyCodexDialog({super.key});
  @override
  ConsumerState<AcademyCodexDialog> createState() => _AcademyCodexDialogState();
}

class _AcademyCodexDialogState extends ConsumerState<AcademyCodexDialog>
    with TickerProviderStateMixin {
  int _selectedLevel = 0;
  bool _navCollapsed = false;
  final Map<int, String> _loadedContent = {};
  bool _isLoading = true;
  late final AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late final AnimationController _navCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _navCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _navCtrl.value = 1.0;
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait(_levels.map(_loadOne));
    if (mounted) { setState(() => _isLoading = false); _fadeCtrl.forward(); }
  }

  Future<void> _loadOne(_LevelMeta m) async {
    try {
      final t = (await rootBundle.loadString(m.assetPath)).trim();
      _loadedContent[m.level] = t.isNotEmpty ? t : 'Decryption failed: Codex entry missing.';
    } catch (_) {
      _loadedContent[m.level] = 'Decryption failed: Codex entry missing.';
    }
  }

  @override
  void dispose() { _fadeCtrl.dispose(); _navCtrl.dispose(); super.dispose(); }

  void _select(int level) {
    _fadeCtrl.reverse().then((_) async {
      if (!mounted) return;
      setState(() => _selectedLevel = level);
      _fadeCtrl.forward();
      
      // Trigger On-Demand Conversation
      final engine = ref.read(tutorialEngineProvider);
      if (!engine.hasSeenCodexLevel(level)) {
         final script = TutorialScripts.getCodexScript(level);
         if (script.isNotEmpty) {
             await showGeneralDialog(
                 context: context,
                 barrierColor: Colors.black87,
                 pageBuilder: (ctx, anim1, anim2) => Scaffold(
                     backgroundColor: Colors.transparent, 
                     body: TutorialOverlayWidget(
                         dialogs: script, 
                         onComplete: () {
                           if (ctx.mounted) Navigator.of(ctx).pop();
                         }
                     )
                 ),
             );
             engine.markCodexLevelSeen(level);
         }
      }
    });
  }

  void _toggleNav() {
    setState(() => _navCollapsed = !_navCollapsed);
    _navCollapsed ? _navCtrl.reverse() : _navCtrl.forward();
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final stats   = ref.watch(userStatsProvider).valueOrNull;
    final isDev   = ref.watch(devModeProvider);
    // Use user's actual level, boss fight completion logic will handle unlocking
    final maxLvl  = isDev ? 6 : (stats?.currentLevel ?? 1);
    final size    = MediaQuery.of(context).size;
    final narrow  = size.width < 620;
    final meta    = _levels[_selectedLevel];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width  * 0.025,
        vertical:   size.height * 0.025,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width:  size.width  * 0.95,
          height: size.height * 0.95,
          decoration: BoxDecoration(
            color: const Color(0xFF080C13),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.25), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFF00D9FF).withOpacity(0.08), blurRadius: 60, spreadRadius: 4)],
          ),
          child: Column(children: [
            _header(context, isDev, narrow),
            Expanded(child: Stack(children: [
              // Content (slides right when nav open)
              AnimatedPadding(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                padding: EdgeInsets.only(left: (_navCollapsed || narrow) ? 0 : 210),
                child: _isLoading
                    ? _loading(meta.accent)
                    : FadeTransition(opacity: _fadeAnim, child: _content(meta, maxLvl)),
              ),
              // Nav rail overlay
              _navOverlay(maxLvl, narrow),
            ])),
          ]),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _header(BuildContext ctx, bool isDev, bool narrow) {
    final meta = _levels[_selectedLevel];
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0D1520), meta.accent.withOpacity(0.06), const Color(0xFF0D1520)],
          stops: const [0, 0.5, 1],
        ),
        border: Border(bottom: BorderSide(color: meta.accent.withOpacity(0.2), width: 1)),
      ),
      child: Row(children: [
        // Hamburger
        _iconBtn(_navCollapsed ? Icons.menu : Icons.menu_open, meta.accent, _toggleNav),
        const SizedBox(width: 10),
        const Icon(Icons.auto_stories_outlined, color: Color(0xFF00D9FF), size: 18),
        const SizedBox(width: 8),
        Text(
          narrow ? "CAPTAIN'S LOG" : "CAPTAIN'S LOG",
          style: GoogleFonts.orbitron(color: const Color(0xFF00D9FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        if (isDev) ...[
          _badge('DEV', Colors.amber, Icons.developer_mode),
          const SizedBox(width: 6), // Reduced spacing
        ],
        _badge('ONLINE', Colors.greenAccent, Icons.circle, iconSize: 8),
        const SizedBox(width: 8), // Reduced spacing
        _iconBtn(Icons.close, Colors.white38, () => Navigator.of(ctx).pop()),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );

  Widget _badge(String label, Color c, IconData icon, {double iconSize = 12}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
    decoration: BoxDecoration(
      color: c.withOpacity(0.08),
      border: Border.all(color: c.withOpacity(0.4)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: c, size: iconSize),
      const SizedBox(width: 4), // Reduced spacing
      Text(label, style: GoogleFonts.shareTechMono(color: c, fontSize: 9)), // Reduced font size
    ]),
  );

  // ── Nav overlay ────────────────────────────────────────────────
  Widget _navOverlay(int maxLvl, bool narrow) {
    return AnimatedBuilder(
      animation: _navCtrl,
      builder: (_, __) {
        const w = 210.0;
        return Positioned(
          top: 0, bottom: 0, left: (_navCtrl.value - 1) * w, width: w,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF060A10),
                border: Border(right: BorderSide(color: const Color(0xFF00D9FF).withOpacity(0.1))),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Row(children: [
                    Text('MISSION LEVELS', style: GoogleFonts.orbitron(color: Colors.white24, fontSize: 7, letterSpacing: 1.5)),
                  ]),
                ),
                Container(height: 1, color: Colors.white.withOpacity(0.06)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    children: _levels.map((l) => _navItem(l, maxLvl, narrow)).toList(),
                  ),
                ),
                Container(height: 1, color: Colors.white.withOpacity(0.04)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('U.G.F. OPERATIONS MANUAL v7.0',
                    style: GoogleFonts.shareTechMono(color: Colors.white12, fontSize: 6, letterSpacing: 0.6)),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _navItem(_LevelMeta m, int maxLvl, bool narrow) {
    final sel    = _selectedLevel == m.level;
    // Lock level if previous level's boss fight not completed (for levels > 0), unless in dev mode
    final engine = ref.read(tutorialEngineProvider);
    final isDev = ref.read(devModeProvider);
    final previousLevelBossCompleted = m.level <= 0 || engine.isBossFightCompleted(m.level - 1);
    final locked = m.level > maxLvl || (m.level > 0 && !previousLevelBossCompleted && !isDev);
    
    // Sub-level logic
    final completed = engine.getCompletedSubLevels(m.level);
    final raw = _loadedContent[m.level] ?? '';
    final subLevelTitles = raw.split('\n').where((line) {
      final trimmed = line.trim();
      return RegExp(r'^###?\s*\d+\.\d+\s+[A-Za-z]').hasMatch(trimmed);
    }).map((s) => s.trim()).toList();
    final allCompleted = subLevelTitles.isNotEmpty && completed.length >= subLevelTitles.length;
    final progress = subLevelTitles.isEmpty ? 0.0 : completed.length / subLevelTitles.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: locked ? null : () {
            _select(m.level);
            if (narrow && !_navCollapsed) _toggleNav();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? m.accent.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: sel ? m.accent : Colors.transparent, width: 3)),
            ),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: locked ? Colors.white.withOpacity(0.03) : m.accent.withOpacity(sel ? 0.18 : 0.06),
                    border: Border.all(color: locked ? Colors.white12 : m.accent.withOpacity(sel ? 0.6 : 0.18)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: locked
                      ? const Icon(Icons.lock, color: Colors.white24, size: 12)
                      : Center(child: Icon(m.icon, color: m.accent.withOpacity(sel ? 1 : 0.5), size: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.title,
                    style: GoogleFonts.orbitron(
                      color: locked ? Colors.white24 : sel ? m.accent : Colors.white54,
                      fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                    overflow: TextOverflow.ellipsis),
                  Text(locked ? 'LOCKED' : m.subtitle,
                    style: GoogleFonts.shareTechMono(
                      color: locked ? Colors.white12 : Colors.white30, fontSize: 7),
                    overflow: TextOverflow.ellipsis),
                ])),
              ]),
              // Enhanced progress bar that fills the button
              if (!locked && subLevelTitles.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: allCompleted ? const Color(0xFF4CAF50) : m.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text('${completed.length}/${subLevelTitles.length} completed',
                  style: GoogleFonts.shareTechMono(
                    color: allCompleted ? const Color(0xFF4CAF50) : Colors.white38,
                    fontSize: 7)),
              ],
            ]),
          ),
        ),
        
        // Boss fight button when all evaluations completed
        if (!locked && allCompleted) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => BossFightScreen(levelId: m.level))).then((_) {
                  setState((){}); // refresh UI bounds if we level up
                });
              },
              icon: const Icon(Icons.flash_on, size: 12),
              label: Text("BOSS FIGHT", style: GoogleFonts.shareTechMono(fontSize: 8, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.2),
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
        
        // Render sub-level progress and boss tile if selected
        if (sel && subLevelTitles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subLevelTitles.map((title) {
                final isDone = completed.contains(title);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(isDone ? Icons.check_circle : Icons.circle_outlined, size: 10, color: isDone ? m.accent : Colors.white24),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(title, style: GoogleFonts.shareTechMono(color: isDone ? m.accent : Colors.white54, fontSize: 8)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // Boss Encounter Tile
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 8, top: 4, bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: allCompleted ? Colors.redAccent.withOpacity(0.1) : Colors.white10.withOpacity(0.05),
                border: Border.all(color: allCompleted ? Colors.redAccent.withOpacity(0.5) : Colors.white24),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, size: 12, color: allCompleted ? Colors.redAccent : Colors.white24),
                  const SizedBox(width: 6),
                  Text(
                    allCompleted ? "BOSS ENCOUNTER" : "BOSS LOCKED",
                    style: GoogleFonts.orbitron(
                      color: allCompleted ? Colors.redAccent : Colors.white24,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Loading ─────────────────────────────────────────────────────
  Widget _loading(Color accent) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: accent, strokeWidth: 2)),
    const SizedBox(height: 14),
    Text('LOADING TRANSMISSION...', style: GoogleFonts.orbitron(color: accent.withOpacity(0.6), fontSize: 11, letterSpacing: 2)),
  ]));

  // ── Content area ────────────────────────────────────────────────
  Widget _content(_LevelMeta meta, int maxLvl) {
    final locked = meta.level > maxLvl;
    final raw    = _loadedContent[meta.level] ?? '';

    return CustomScrollView(slivers: [
      // Gradient title banner
      SliverToBoxAdapter(child: _levelBanner(meta, locked)),

      if (locked)
        SliverFillRemaining(child: Center(child: _lockScreen()))
      else if (raw.isEmpty)
        SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hourglass_empty_outlined, color: meta.accent.withOpacity(0.4), size: 40),
          const SizedBox(height: 12),
          Text('TRANSMISSION IN PROGRESS', style: GoogleFonts.orbitron(color: meta.accent.withOpacity(0.5), fontSize: 12, letterSpacing: 2)),
        ])))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList(delegate: SliverChildListDelegate(_parseContent(meta))),
        ),
    ]);
  }

  Widget _levelBanner(_LevelMeta meta, bool locked) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [meta.accent.withOpacity(0.12), Colors.transparent],
        ),
        border: Border(bottom: BorderSide(color: meta.accent.withOpacity(0.15))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: meta.accent.withOpacity(0.12),
              border: Border.all(color: meta.accent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(meta.icon, color: meta.accent, size: 13),
              const SizedBox(width: 6),
              Text('LEVEL ${meta.level}', style: GoogleFonts.orbitron(color: meta.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: locked ? Colors.white24 : meta.accent, shape: BoxShape.circle,
              boxShadow: locked ? [] : [BoxShadow(color: meta.accent, blurRadius: 6)]),
          ),
          const SizedBox(width: 6),
          Text(locked ? 'LOCKED' : 'ACTIVE', style: GoogleFonts.shareTechMono(color: locked ? Colors.white24 : meta.accent, fontSize: 10, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 10),
        Text(meta.title,
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.5)),
        const SizedBox(height: 4),
        Text(meta.subtitle.toUpperCase(),
          style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
      ]),
    );
  }

  Widget _lockScreen() => Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.lock_outline, color: Colors.white24, size: 52),
    const SizedBox(height: 16),
    Text('CLEARANCE REQUIRED', style: GoogleFonts.orbitron(color: Colors.white24, fontSize: 15, letterSpacing: 2)),
    const SizedBox(height: 8),
    Text('Complete your current level to unlock', style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 12)),
    const SizedBox(height: 4),
    Text('Enable DEV MODE to bypass lock', style: GoogleFonts.shareTechMono(color: Colors.amber.withOpacity(0.4), fontSize: 11)),
  ]);

  // ── Text parser ─────────────────────────────────────────────────
  List<Widget> _parseContent(_LevelMeta meta) {
    final raw = _loadedContent[meta.level] ?? '';
    final widgets = <Widget>[];
    final engine = ref.read(tutorialEngineProvider);
    final completed = engine.getCompletedSubLevels(meta.level);

    // Parse initial content
    widgets.addAll(_parseInnerContent(raw, meta.accent, meta));
    
    // Add boss fight button if all sub-levels completed
    final levelRaw = _loadedContent[meta.level] ?? '';
    final subLevelTitles = levelRaw.split('\n').where((line) {
      final trimmed = line.trim();
      return RegExp(r'^\d+\.\d+\s+[A-Za-z]').hasMatch(trimmed);
    }).map((s) => s.trim()).toList();
    final allCompleted = subLevelTitles.isNotEmpty && completed.length >= subLevelTitles.length;
    
    if (allCompleted) {
      widgets.add(const SizedBox(height: 20));
      widgets.add(_buildBossFightButton(meta.level, true));
    }

    return widgets;
  }

  Widget _cadetEvaluation(int level, List<String> completed, Color accent) {
    final raw = _loadedContent[level] ?? '';
    final subLevelTitles = raw.split('\n').where((line) {
      final trimmed = line.trim();
      return RegExp(r'^\d+\.\d+\s+[A-Za-z]').hasMatch(trimmed);
    }).map((s) => s.trim()).toList();
    final isCompleted = subLevelTitles.isNotEmpty && completed.length >= subLevelTitles.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isCompleted ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFF2196F3).withOpacity(0.1),
            isCompleted ? const Color(0xFF4CAF50).withOpacity(0.05) : const Color(0xFF2196F3).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: isCompleted ? const Color(0xFF4CAF50).withOpacity(0.3) : const Color(0xFF2196F3).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.verified : Icons.pending_actions,
                color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'CADET EVALUATION',
                style: GoogleFonts.orbitron(
                  color: isCompleted ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCompleted 
              ? '✓ Level $level completed successfully! Ready for next mission.'
              : '⚠ Complete all objectives to unlock next level and boss fight.',
            style: GoogleFonts.shareTechMono(
              color: Colors.white70,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PROGRESS: ${completed.length}/3 objectives completed',
                textAlign: TextAlign.center,
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF2196F3),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _parseInnerContent(String raw, Color accent, _LevelMeta meta) {
    final widgets = <Widget>[];
    final lines   = raw.split('\n');
    final buf     = StringBuffer();
    String? currentSectionTitle;
    int? currentSubLevelIndex;

    void flush() {
      final t = buf.toString().trim();
      if (t.isNotEmpty) widgets.add(_bodyBlock(t, accent));
      buf.clear();
      
      // Add evaluation button after section content if this was a sub-level
      if (currentSectionTitle != null && currentSubLevelIndex != null) {
        final engine = ref.read(tutorialEngineProvider);
        final completed = engine.getCompletedSubLevels(meta.level);
        final isSubLevelCompleted = completed.contains(currentSectionTitle);
        
        widgets.add(const SizedBox(height: 16));
        widgets.add(_buildCadetEvalButton(meta.level, currentSectionTitle ?? '', currentSubLevelIndex!, accent, isSubLevelCompleted));
        currentSectionTitle = null;
        currentSubLevelIndex = null;
      }
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) { flush(); continue; }

      // Callout lines (start with emoji)
      if (RegExp(r'^[🚀⚔️🏁🎓🟢🔴⚡🚨❌✅🧠🔧⚡🌌💡⚠️]').hasMatch(line)) {
        flush();
        widgets.add(_callout(line, accent));
        continue;
      }

      // Section headings
      final isSection = buf.toString().trim().isEmpty &&
          (RegExp(r'^\d+\.\d+\s').hasMatch(line) ||
           RegExp(r'^#+\s').hasMatch(line) ||
           RegExp(r'^LEVEL\s+\d+').hasMatch(line) ||
           (line.endsWith(':') && line.length < 60));
      if (isSection) { 
        flush(); 
        widgets.add(_section(line, accent));
        
        // Store section info to add evaluation button after content
        final sectionTitle = line.replaceAll(RegExp(r'^#+\s'), '').trim();
        if (sectionTitle.isNotEmpty) {
          final subLevelIndex = _getSubLevelIndex(sectionTitle);
          if (subLevelIndex != null) {
            currentSectionTitle = sectionTitle;
            currentSubLevelIndex = subLevelIndex;
          }
        }
        
        continue; 
      }

      buf.writeln(line);
    }
    flush();
    return widgets;
  }

  Widget _buildCadetEvalButton(int levelId, String subLevelTitle, int subLevelIndex, Color accent, bool isCompleted) {
    // Check if this evaluation was failed
    final engine = ref.read(tutorialEngineProvider);
    final failed = engine.getFailedSubLevels(levelId);
    final isFailed = failed.contains(subLevelTitle) && !isCompleted;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton.icon(
        onPressed: isCompleted ? null : () async {
          // Open Mini Quiz Sheet
          await showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (ctx) => MiniQuizSheetWrapper(levelId: levelId, subLevelTitle: subLevelTitle, subLevelIndex: subLevelIndex),
          );
          // Refresh state
          setState(() {});
        },
        icon: Icon(
          isCompleted ? Icons.check_circle : 
          isFailed ? Icons.error : 
          Icons.psychology, 
          color: isCompleted ? Colors.green : 
                 isFailed ? Colors.red : 
                 accent,
          size: 18
        ),
        label: Text(
          isCompleted ? "✓ PASSED" : 
          isFailed ? "✗ FAILED" : 
          "RUN EVALUATION",
          style: GoogleFonts.shareTechMono(
            fontWeight: FontWeight.bold, 
            letterSpacing: 0.5,
            fontSize: 11,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.green.withOpacity(0.2) : 
                         isFailed ? Colors.red.withOpacity(0.2) : 
                         accent.withOpacity(0.1),
          foregroundColor: isCompleted ? Colors.green : 
                         isFailed ? Colors.red : 
                         accent,
          side: BorderSide(
            color: isCompleted ? Colors.green.withOpacity(0.5) : 
                   isFailed ? Colors.red.withOpacity(0.5) : 
                   accent.withOpacity(0.5)
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildBossFightButton(int levelId, bool isUnlocked) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: InkWell(
        onTap: isUnlocked ? () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => BossFightScreen(levelId: levelId))).then((_) {
            setState((){}); // refresh UI bounds if we level up
          });
        } : () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete all CADET EVALUATIONS in this level first.')));
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isUnlocked ? Colors.redAccent.withOpacity(0.15) : Colors.white10.withOpacity(0.05),
            border: Border.all(color: isUnlocked ? Colors.redAccent : Colors.white24, width: 2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isUnlocked ? [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 20)] : [],
          ),
          child: Column(
            children: [
              Icon(Icons.security, size: 36, color: isUnlocked ? Colors.redAccent : Colors.white38),
              const SizedBox(height: 12),
              Text(
                isUnlocked ? "INITIATE BOSS FIGHT" : "BOSS ENCOUNTER LOCKED",
                style: GoogleFonts.orbitron(
                  color: isUnlocked ? Colors.redAccent : Colors.white38,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUnlocked ? "WARNING: POTENTIALLY FATAL TO FUEL RESERVES" : "Pass all diagnostics to unlock",
                style: GoogleFonts.shareTechMono(color: isUnlocked ? Colors.redAccent.withOpacity(0.7) : Colors.white24, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String text, Color accent) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Row(children: [
      Container(width: 3, height: 18, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Expanded(child: Text(text.replaceAll(RegExp(r'\s*:$'), ''),
        style: GoogleFonts.orbitron(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
    ]),
  );

  Widget _bodyBlock(String text, Color accent) {
    final lines = text.split('\n');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((l) => _bodyLine(l.trim(), accent)).toList()),
    );
  }

  Widget _bodyLine(String line, Color accent) {
    if (line.isEmpty) return const SizedBox(height: 4);

    // Key: Value pattern → key highlighted
    final kv = RegExp(r'^([^:]{1,50}):\s*(.+)$').firstMatch(line);
    if (kv != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: RichText(text: TextSpan(children: [
          TextSpan(text: '${kv.group(1)}: ', style: GoogleFonts.shareTechMono(color: accent.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold, height: 1.6)),
          TextSpan(text: kv.group(2)!, style: GoogleFonts.shareTechMono(color: Colors.white60, fontSize: 12, height: 1.6)),
        ])),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: MarkdownBody(
        data: line,
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12, height: 1.65),
          code: GoogleFonts.shareTechMono(color: accent, backgroundColor: Colors.black26, fontSize: 11),
          codeblockDecoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: accent.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  Widget _callout(String text, Color accent) {
    // Detect type for styling
    final isWarning = text.startsWith('🚨') || text.startsWith('⚠️') || text.startsWith('❌');
    final isSuccess = text.startsWith('✅') || text.startsWith('🟢') || text.startsWith('🏁');
    final isGoal    = text.startsWith('🚀') || text.startsWith('⚔️') || text.startsWith('🎓');

    Color bgColor = Colors.transparent;
    if (isWarning) bgColor = const Color(0xFFFF5252).withOpacity(0.1);
    if (isSuccess) bgColor = const Color(0xFF4CAF50).withOpacity(0.1);
    if (isGoal)    bgColor = const Color(0xFF2196F3).withOpacity(0.1);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: accent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 11, height: 1.4)),
    );
  }

  // Helper method to extract sub-level index from title
  int? _getSubLevelIndex(String sectionTitle) {
    final levelSections = {
      '0.0': 0, '0.1': 1, '0.2': 2, '0.3': 3, '0.4': 4, '0.5': 5, '0.6': 6,
      '1.0': 0, '1.1': 1, '1.2': 2, '1.3': 3, '1.4': 4, '1.5': 5, '1.6': 6, '1.7': 7, '1.8': 8,
      '2.0': 0, '2.1': 1, '2.2': 2, '2.3': 3, '2.4': 4, '2.5': 5, '2.6': 6, '2.7': 7, '2.8': 8,
      '3.0': 0, '3.1': 1, '3.2': 2, '3.3': 3, '3.4': 4, '3.5': 5, '3.6': 6,
      '4.0': 0, '4.1': 1, '4.2': 2, '4.3': 3, '4.4': 4, '4.5': 5, '4.6': 6,
      '5.0': 0, '5.1': 1, '5.2': 2, '5.3': 3, '5.4': 4, '5.5': 5, '5.6': 6,
      '6.0': 0, '6.1': 1, '6.2': 2, '6.3': 3, '6.4': 4, '6.5': 5, '6.6': 6,
    };
    
    for (final entry in levelSections.entries) {
      if (sectionTitle.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }
}
