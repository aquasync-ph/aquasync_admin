import 'package:flutter/material.dart';

/// A modern, unified glassmorphic summary card component used across all admin dashboard pages.
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
    this.accentColor = const Color(0xFF38BDF8),
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
    final double cardPadding = (widget.width != null && widget.width! < 300) ? 14.0 : 16.0;
    final double iconBoxSize = (widget.width != null && widget.width! < 300) ? 40.0 : 44.0;
    const Color brandPrimary = Color(0xFF0098DA);
    const Color darkText = Color(0xFF0B1D2A);
    const Color subTextCol = Color(0xFF1B4965);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: widget.width,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered ? brandPrimary : brandPrimary.withValues(alpha: 0.35),
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: brandPrimary.withValues(alpha: _isHovered ? 0.18 : 0.08),
                blurRadius: _isHovered ? 16 : 10,
                offset: Offset(0, _isHovered ? 5 : 3),
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
                    Text(
                      widget.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subTextCol,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    if (widget.subText != null && widget.subText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: brandPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.subText!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF5A5E63),
                                fontWeight: FontWeight.w500,
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
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: brandPrimary.withValues(alpha: 0.30),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.icon,
                  color: brandPrimary,
                  size: (widget.width != null && widget.width! < 300) ? 20 : 22,
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
    this.accentColor = const Color(0xFF38BDF8),
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
      accentColor: const Color(0xFF38BDF8),
      onTap: onTap,
    );
  }
}
