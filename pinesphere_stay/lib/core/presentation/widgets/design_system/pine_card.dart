import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class PineCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool isGlass;
  final double elevation;

  const PineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor,
    this.isGlass = false,
    this.elevation = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isGlass
            ? (backgroundColor ?? AppColors.surface).withValues(alpha: 0.6)
            : (backgroundColor ?? AppColors.surface),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: elevation,
            offset: Offset(0, elevation * 0.4),
          )
        ],
        border: Border.all(
          color: isGlass 
              ? Colors.white.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: child,
    );

    if (isGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: cardContent,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: cardContent,
      ),
    );
  }
}
