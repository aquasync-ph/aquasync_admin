import 'package:flutter/material.dart';

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final Color? accentColor;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.isHighlighted = false,
    this.onTap,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);
    final borderColor = isHighlighted
        ? const Color(0xFF0098DA)
        : (accentColor ?? const Color(0xFF0098DA).withValues(alpha: 0.30));

    final card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFE6F3FA)
            : (backgroundColor ?? Colors.white),
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isHighlighted)
            const BoxShadow(
              color: Color(0x330098DA),
              blurRadius: 16,
              spreadRadius: 1,
            )
          else
            const BoxShadow(
              color: Color(0x140B1D2A),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius as BorderRadius?,
        child: card,
      );
    }

    return card;
  }
}
