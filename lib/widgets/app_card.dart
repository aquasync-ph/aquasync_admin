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
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(20);
    const Color brandPrimary = Color(0xFF0098DA);
    final borderColor = isHighlighted
        ? brandPrimary
        : (accentColor ?? brandPrimary.withValues(alpha: 0.30));

    final card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHighlighted
              ? [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)]
              : [backgroundColor ?? Colors.white, backgroundColor ?? Colors.white],
        ),
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 2.0 : 1.2,
        ),
        boxShadow: [
          if (isHighlighted)
            BoxShadow(
              color: brandPrimary.withValues(alpha: 0.28),
              blurRadius: 22,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            )
          else
            BoxShadow(
              color: const Color(0xFF0B1D2A).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
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

