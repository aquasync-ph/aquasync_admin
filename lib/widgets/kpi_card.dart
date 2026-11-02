import 'package:flutter/material.dart';

/// A modern, premium high-tech glassmorphic summary KPI card component used across all admin dashboard pages.
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
    final double cardPadding = (widget.width != null && widget.width! < 300) ? 16.0 : 20.0;
    // Significantly larger high-tech icon container as requested
    final double iconBoxSize = (widget.width != null && widget.width! < 300) ? 52.0 : 60.0;
    const Color brandPrimary = Color(0xFF0098DA);
    const Color brandGlow = Color(0xFF38BDF8);
    const Color darkText = Color(0xFF0B1D2A);
    const Color subTextCol = Color(0xFF1B4965);

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? [Colors.white, const Color(0xFFF0F9FF)]
                  : [Colors.white, Colors.white],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isHovered ? brandPrimary : brandPrimary.withValues(alpha: 0.30),
              width: _isHovered ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: brandPrimary.withValues(alpha: _isHovered ? 0.22 : 0.08),
                blurRadius: _isHovered ? 20 : 12,
                offset: Offset(0, _isHovered ? 6 : 3),
              ),
              if (_isHovered)
                BoxShadow(
                  color: brandGlow.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 12,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: subTextCol,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: darkText,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    if (widget.subText != null && widget.subText!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: brandPrimary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: brandPrimary.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.subText!,
                              style: const TextStyle(
                                fontSize: 11,
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
              // Enhanced high-tech larger icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brandPrimary.withValues(alpha: _isHovered ? 0.22 : 0.14),
                      brandPrimary.withValues(alpha: _isHovered ? 0.35 : 0.20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: brandPrimary.withValues(alpha: _isHovered ? 0.6 : 0.35),
                    width: _isHovered ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brandPrimary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  color: brandPrimary,
                  // Larger, striking icon size
                  size: (widget.width != null && widget.width! < 300) ? 26 : 30,
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

