import 'package:flutter/material.dart';

/// A modern, professional high-tech iOS-inspired summary KPI card component used across all admin dashboard pages.
class AppSummaryCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subText;
  final double? width;
  final VoidCallback? onTap;

  const AppSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor = const Color(0xFF0098DA),
    this.subText,
    this.width,
    this.onTap,
  });

  @override
  State<AppSummaryCard> createState() => _AppSummaryCardState();
}

class _AppSummaryCardState extends State<AppSummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final double cardPadding = (widget.width != null && widget.width! < 280) ? 16.0 : 20.0;
    final double iconBoxSize = (widget.width != null && widget.width! < 280) ? 50.0 : 58.0;

    // High-tech iOS typography & brand colors
    final Color primaryAccent = widget.accentColor;
    const Color darkText = Color(0xFF0B1D2A); // High-contrast navy black value
    const Color labelTextCol = Color(0xFF475569); // Clean slate header label

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: widget.width,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            // 30% Structural Glass Surface Color (Modern Elevated Canvas)
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [Colors.white, const Color(0xFFF0F9FF)]
                  : [Colors.white, const Color(0xFFFAFAFA)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isHovered
                  ? primaryAccent
                  : primaryAccent.withValues(alpha: 0.28),
              width: _isHovered ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryAccent.withValues(alpha: _isHovered ? 0.22 : 0.08),
                blurRadius: _isHovered ? 22 : 14,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
              if (_isHovered)
                BoxShadow(
                  color: primaryAccent.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Content: Title, Value & Subtext
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header / Title (Component Anatomy #1)
                    Row(
                      children: [
                        // Left Accent Bar (Visual Indicator)
                        Container(
                          width: 3.5,
                          height: 13,
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: primaryAccent.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            widget.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: labelTextCol,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Value / Count (Component Anatomy #2)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: darkText,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                    ),

                    // Optional SubText / Trend Indicator
                    if (widget.subText != null && widget.subText!.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryAccent.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.subText!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Icon Badge / Visual Indicator (Component Anatomy #3)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryAccent.withValues(alpha: _isHovered ? 0.25 : 0.14),
                      primaryAccent.withValues(alpha: _isHovered ? 0.38 : 0.22),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primaryAccent.withValues(alpha: _isHovered ? 0.70 : 0.40),
                    width: _isHovered ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: _isHovered ? 0.25 : 0.12),
                      blurRadius: _isHovered ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  color: primaryAccent,
                  size: (widget.width != null && widget.width! < 280) ? 25 : 29,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible wrapper for AppSummaryCard with required subText.
class KpiCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final String subText;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    required this.subText,
    required this.icon,
    this.accentColor = const Color(0xFF0098DA),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSummaryCard(
      width: width,
      label: label,
      value: value,
      subText: subText,
      icon: icon,
      accentColor: accentColor,
      onTap: onTap,
    );
  }
}
