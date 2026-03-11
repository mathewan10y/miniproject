import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../user_stats_provider.dart';

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
      _loadedContent[m.level] = t.isNotEmpty ? t : '';
    } catch (_) { _loadedContent[m.level] = ''; }
  }

  @override
  void dispose() { _fadeCtrl.dispose(); _navCtrl.dispose(); super.dispose(); }

  void _select(int level) {
    _fadeCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _selectedLevel = level);
      _fadeCtrl.forward();
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
          narrow ? "CAPTAIN'S LOG" : "CAPTAIN'S LOG  ·  U.G.F. OPERATIONS MANUAL",
          style: GoogleFonts.orbitron(color: const Color(0xFF00D9FF), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const Spacer(),
        if (isDev) ...[
          _badge('DEV', Colors.amber, Icons.developer_mode),
          const SizedBox(width: 8),
        ],
        _badge('ONLINE', Colors.greenAccent, Icons.circle, iconSize: 8),
        const SizedBox(width: 10),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(0.08),
      border: Border.all(color: c.withOpacity(0.4)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: c, size: iconSize),
      const SizedBox(width: 5),
      Text(label, style: GoogleFonts.shareTechMono(color: c, fontSize: 10)),
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
                    Text('MISSION LEVELS', style: GoogleFonts.orbitron(color: Colors.white24, fontSize: 8, letterSpacing: 2)),
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
                    style: GoogleFonts.shareTechMono(color: Colors.white12, fontSize: 7, letterSpacing: 0.8)),
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
    final locked = m.level > maxLvl;
    return GestureDetector(
      onTap: locked ? null : () {
        _select(m.level);
        if (narrow && !_navCollapsed) _toggleNav();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? m.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: sel ? m.accent : Colors.transparent, width: 3)),
        ),
        child: Row(children: [
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
                fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis),
            Text(locked ? 'LOCKED' : m.subtitle,
              style: GoogleFonts.shareTechMono(
                color: locked ? Colors.white12 : Colors.white30, fontSize: 8),
              overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
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
          sliver: SliverList(delegate: SliverChildListDelegate(_parseContent(raw, meta.accent))),
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
  List<Widget> _parseContent(String raw, Color accent) {
    final widgets = <Widget>[];
    final lines   = raw.split('\n');
    final buf     = StringBuffer();

    void flush() {
      final t = buf.toString().trim();
      if (t.isNotEmpty) widgets.add(_bodyBlock(t, accent));
      buf.clear();
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
           RegExp(r'^LEVEL\s+\d+').hasMatch(line) ||
           (line.endsWith(':') && line.length < 60));
      if (isSection) { flush(); widgets.add(_section(line, accent)); continue; }

      buf.writeln(line);
    }
    flush();
    return widgets;
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
      child: Text(line, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12, height: 1.65)),
    );
  }

  Widget _callout(String text, Color accent) {
    // Detect type for styling
    final isWarning = text.startsWith('🚨') || text.startsWith('⚠️') || text.startsWith('❌');
    final isSuccess = text.startsWith('✅') || text.startsWith('🟢') || text.startsWith('🏁');
    final isGoal    = text.startsWith('🚀') || text.startsWith('⚔️') || text.startsWith('🎓');
    final color = isWarning ? Colors.redAccent
        : isSuccess ? Colors.greenAccent
        : isGoal    ? accent
        : accent;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Text(text, style: GoogleFonts.shareTechMono(color: color.withOpacity(0.9), fontSize: 12, height: 1.6, fontWeight: FontWeight.bold)),
    );
  }
}
