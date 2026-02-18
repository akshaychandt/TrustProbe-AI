import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trustprobe_ai/models/scan_result.dart';
import 'package:trustprobe_ai/services/ai_service.dart';

/// ResultCard - Displays the analysis result with animations
class ResultCard extends StatefulWidget {
  final ScanResult result;

  const ResultCard({super.key, required this.result});

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRiskColor() => switch (widget.result.riskScore) {
    <= 30 => const Color(0xFF00d4aa),
    <= 70 => const Color(0xFFffb700),
    _ => const Color(0xFFff4757),
  };

  IconData _getClassificationIcon() => switch (widget.result.classification) {
    'Safe' => Icons.verified_user,
    'Suspicious' => Icons.warning_amber,
    'Malicious' => Icons.dangerous,
    _ => Icons.help_outline,
  };

  /// Parse AI analysis from stored formatted string
  AiAnalysisResult? get _aiAnalysis =>
      AiAnalysisResult.fromFormattedString(widget.result.aiAnalysis);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _getRiskColor().withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getRiskColor().withValues(alpha: 0.2),
                blurRadius: 30,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // URL Section with gradient background
              _buildUrlSection(),

              const SizedBox(height: 28),

              // Risk Score - Prominent display
              _buildRiskScore(),

              const SizedBox(height: 24),

              // Classification Badge
              _buildClassificationBadge(),

              const SizedBox(height: 28),

              // Detailed Explanation (Heuristic)
              _buildDetailedExplanation(),

              // AI Insights Section (only if AI analysis is available)
              if (_aiAnalysis != null) ...[
                const SizedBox(height: 28),
                _buildAiInsightsSection(_aiAnalysis!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRiskColor().withValues(alpha: 0.15),
            _getRiskColor().withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getRiskColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getRiskColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.link, color: _getRiskColor(), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyzed URL',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.result.url,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskScore() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Risk Assessment',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRiskColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getRiskColor().withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                widget.result.riskLevel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _getRiskColor(),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress bar with animation
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widget.result.riskScore / 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getRiskColor().withValues(alpha: 0.7),
                    _getRiskColor(),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _getRiskColor().withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.result.riskScore}%',
              style: GoogleFonts.poppins(
                fontSize: 36,
                color: _getRiskColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Risk Score',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassificationBadge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getRiskColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getRiskColor().withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getRiskColor().withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getClassificationIcon(),
              color: _getRiskColor(),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classification',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.result.classification.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: _getRiskColor(),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedExplanation() {
    // Parse the reason to extract individual factors
    final reasons = widget.result.reason.split('. ');
    final breakdown = widget.result.scoreBreakdown;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Color(0xFF00f2fe), size: 22),
              const SizedBox(width: 10),
              Text(
                'Detailed Analysis',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Display each reason as a bullet point
          ...reasons.where((r) => r.trim().isNotEmpty).map((reason) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Color(0xFF00f2fe),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      reason.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Recommendation
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getRiskColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getRiskColor().withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  widget.result.classification == 'Safe'
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: _getRiskColor(),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getRecommendation(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Score Breakdown Dropdown
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildScoreBreakdownDropdown(breakdown),
          ],
        ],
      ),
    );
  }

  /// Expandable dropdown showing each analysis check and its score
  Widget _buildScoreBreakdownDropdown(Map<String, int> breakdown) =>
      _ScoreBreakdownDropdown(breakdown: breakdown, riskColor: _getRiskColor());

  String _getRecommendation() => switch (widget.result.classification) {
    'Safe' => '✓ This URL appears safe to visit based on our analysis.',
    'Suspicious' =>
      '⚠ Exercise caution. This URL shows some suspicious characteristics.',
    'Malicious' =>
      '⛔ Do not visit this URL. High likelihood of phishing or malicious content.',
    _ => 'Unable to determine safety level.',
  };

  /// Build the AI Insights section with LLM-generated analysis
  Widget _buildAiInsightsSection(AiAnalysisResult aiResult) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7c3aed).withValues(alpha: 0.15),
            Color(0xFF2563eb).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF7c3aed).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7c3aed), Color(0xFF2563eb)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF7c3aed).withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI-Powered Insights',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(
                    aiResult.confidenceLevel,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getConfidenceColor(
                      aiResult.confidenceLevel,
                    ).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '${aiResult.confidenceLevel.toUpperCase()} CONFIDENCE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _getConfidenceColor(aiResult.confidenceLevel),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Threat Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              aiResult.threatSummary,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Risk Factors
          if (aiResult.riskFactors.isNotEmpty) ...[
            Text(
              'Key Risk Factors',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            ...aiResult.riskFactors.map((factor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color(0xFF7c3aed).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFFa78bfa),
                        size: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        factor,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // AI Recommendation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRiskColor().withValues(alpha: 0.15),
                  _getRiskColor().withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getRiskColor().withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFfbbf24),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    aiResult.recommendation,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // "Powered by AI" footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF7c3aed).withValues(alpha: 0.5),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Powered by Llama 3.3 — Open Source AI',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(String level) => switch (level.toLowerCase()) {
    'high' => const Color(0xFF00d4aa),
    'medium' => const Color(0xFFffb700),
    'low' => const Color(0xFFff4757),
    _ => const Color(0xFFffb700),
  };
}

/// Expandable dropdown widget that shows individual analysis scores
class _ScoreBreakdownDropdown extends StatefulWidget {
  final Map<String, int> breakdown;
  final Color riskColor;

  const _ScoreBreakdownDropdown({
    required this.breakdown,
    required this.riskColor,
  });

  @override
  State<_ScoreBreakdownDropdown> createState() =>
      _ScoreBreakdownDropdownState();
}

class _ScoreBreakdownDropdownState extends State<_ScoreBreakdownDropdown>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  Color _getScoreColor(int score) => switch (score) {
    < 0 => const Color(0xFF00d4aa),
    0 => const Color(0xFF00d4aa),
    <= 20 => const Color(0xFFffb700),
    _ => const Color(0xFFff4757),
  };

  IconData _getScoreIcon(int score) =>
      score <= 0 ? Icons.check_circle : Icons.warning_amber_rounded;

  @override
  Widget build(BuildContext context) {
    // Sort: flagged checks first (score > 0), then passed checks
    final sortedEntries = widget.breakdown.entries.toList()
      ..sort((a, b) {
        if (a.value > 0 && b.value <= 0) return -1;
        if (a.value <= 0 && b.value > 0) return 1;
        return b.value.compareTo(a.value);
      });

    final flaggedCount = sortedEntries.where((e) => e.value > 0).length;

    return Column(
      children: [
        // Expandable Header
        InkWell(
          onTap: _toggleExpand,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00f2fe).withValues(alpha: 0.08),
                  Color(0xFF4facfe).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF00f2fe).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFF00f2fe),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Score Breakdown',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Flagged count badge
                if (flaggedCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFff4757).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$flaggedCount flagged',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Color(0xFFff4757),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable Content
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: sortedEntries.map((entry) {
                final name = entry.key;
                final score = entry.value;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Pass/Fail icon
                      Icon(
                        _getScoreIcon(score),
                        color: _getScoreColor(score),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      // Check name
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: score > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      // Score badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getScoreColor(score).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          score < 0
                              ? '$score pts'
                              : score == 0
                              ? 'Pass'
                              : '+$score pts',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: _getScoreColor(score),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
