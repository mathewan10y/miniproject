import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/stock_analysis_service.dart';
import '../domain/models/market_asset.dart';

// ─── Color Palette (matches TradingPage) ─────────────────────────────────────

const _panelBg = Color(0xFF131722);
const _panelBorder = Color(0xFF1E222D);
const _darkBg = Color(0xFF0B0E14);
const _cyan = Color(0xFF2962FF);
const _green = Color(0xFF26A69A);
const _red = Color(0xFFEF5350);
const _amber = Color(0xFFFFA726);

// ─── Entry Point ─────────────────────────────────────────────────────────────

/// Call this to open the AI analysis bottom sheet for [asset].
void showStockAnalysisOverlay(BuildContext context, MarketAsset asset) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StockAnalysisSheet(asset: asset),
  );
}

// ─── Sheet Widget ─────────────────────────────────────────────────────────────

class _StockAnalysisSheet extends StatefulWidget {
  final MarketAsset asset;
  const _StockAnalysisSheet({required this.asset});

  @override
  State<_StockAnalysisSheet> createState() => _StockAnalysisSheetState();
}

class _StockAnalysisSheetState extends State<_StockAnalysisSheet> {
  StockAnalysisResult? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final service = StockAnalysisService();
      final result = await service.analyze(widget.asset.symbol);
      if (mounted) {
        setState(() {
          _result = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _panelBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(top: BorderSide(color: _panelBorder, width: 1)),
          ),
          child: Column(
            children: [
              // ── Drag handle
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Header bar
              _buildHeader(),

              // ── Divider
              Container(height: 1, color: _panelBorder),

              // ── Body
              Expanded(
                child:
                    _loading
                        ? _buildLoader()
                        : _error != null
                        ? _buildError()
                        : _buildResult(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    Color ratingColor = _amber;
    String ratingLabel = 'Analyzing…';
    if (_result != null) {
      ratingLabel = _result!.rating;
      if (_result!.rating == 'Bullish') {
        ratingColor = _green;
      } else if (_result!.rating == 'Bearish') {
        ratingColor = _red;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Scan icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _cyan.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.analytics_outlined, color: _cyan, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Fundamental Analysis',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                widget.asset.symbol,
                style: GoogleFonts.shareTechMono(color: _cyan, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          // Rating badge (visible only when result is ready)
          if (_result != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ratingColor.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ratingColor.withAlpha(100)),
              ),
              child: Text(
                ratingLabel,
                style: GoogleFonts.inter(
                  color: ratingColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Loading State ────────────────────────────────────────────────────────

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: _cyan,
              strokeWidth: 2.5,
              backgroundColor: _cyan.withAlpha(20),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Running AI Analysis…',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Consulting Gemini on ${widget.asset.symbol} fundamentals',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── Error State ──────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Analysis Failed',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Retry', style: GoogleFonts.inter(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Result State ─────────────────────────────────────────────────────────

  Widget _buildResult(ScrollController scrollController) {
    final r = _result!;
    final scoreColor =
        r.score >= 7
            ? _green
            : r.score >= 4
            ? _amber
            : _red;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Score gauge
        _buildScoreCard(r.score, scoreColor),
        const SizedBox(height: 12),

        // Summary
        _buildSection(
          icon: Icons.summarize_outlined,
          iconColor: _cyan,
          title: 'Summary',
          child: Text(
            r.summary,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Strengths
        if (r.strengths.isNotEmpty) ...[
          _buildSection(
            icon: Icons.trending_up,
            iconColor: _green,
            title: 'Strengths',
            child: _buildBulletList(r.strengths, _green),
          ),
          const SizedBox(height: 10),
        ],

        // Weaknesses
        if (r.weaknesses.isNotEmpty) ...[
          _buildSection(
            icon: Icons.trending_down,
            iconColor: _red,
            title: 'Weaknesses',
            child: _buildBulletList(r.weaknesses, _red),
          ),
          const SizedBox(height: 10),
        ],

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _amber.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _amber.withAlpha(40)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: _amber, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI-generated analysis. Not financial advice. Use simulated metrics for educational purposes only.',
                  style: GoogleFonts.inter(
                    color: _amber.withAlpha(200),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(int score, Color scoreColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Fundamental Score',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$score / 10',
                style: GoogleFonts.inter(
                  color: scoreColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 10,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _darkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 15),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items, Color bulletColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bulletColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
