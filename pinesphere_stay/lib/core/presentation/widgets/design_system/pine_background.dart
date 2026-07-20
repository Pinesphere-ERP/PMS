import 'package:flutter/material.dart';

/// A reusable background widget featuring the aesthetic abstract shapes
/// used in the PineStay app's Login and Dashboard screens.
class PineBackground extends StatelessWidget {
  final Widget child;
  final bool showBottomShapes;
  final Color backgroundColor;

  const PineBackground({
    super.key,
    required this.child,
    this.showBottomShapes = true,
    this.backgroundColor = const Color(0xFFF5F7F5), // Light gray/green BG
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF4b7b4d); 
    const Color darkGreen = Color(0xFF325333); 
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.height,
      color: backgroundColor,
      child: Stack(
        children: [
          // Top-left abstract shape
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: darkGreen.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(60),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          
          // Top-right abstract shape
          Positioned(
            top: -20,
            right: -40,
            child: Container(
              width: 150,
              height: 100,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
          ),

          if (showBottomShapes) ...[
            // Bottom-right abstract shape
            Positioned(
              bottom: -50,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(70),
                ),
              ),
            ),
            // Bottom-left abstract shape
            Positioned(
              bottom: 20,
              left: -40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
          ],
          
          // Foreground Content
          Positioned.fill(
            child: child,
          ),
        ],
      ),
    );
  }
}
