import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textWidthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Delay the start of the animation to let the user see the static logo first
    // Fade in text and scale down logo in the second phase
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _textWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeInOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 3.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeInOutCubic),
      ),
    );

    // Ensure the native splash is removed ONLY after the first frame of our Flutter splash is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      // Start the animation
      _controller.forward().then((_) {
        // After animation completes, delay slightly and navigate
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            context.go('/dashboard');
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.lato(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      color: AppColors.onPrimary,
      letterSpacing: 1.5,
    );

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // "PineSt"
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerRight,
                        widthFactor: _textWidthAnimation.value,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Text('PineSt', style: textStyle),
                        ),
                      ),
                    ),
                    
                    // Logo replacing 'A'
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Image.asset(
                        'assets/logo.png',
                        height: 52, // Matched roughly to font size 48
                        width: 52,
                      ),
                    ),
                    
                    // "y"
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _textWidthAnimation.value,
                        child: Opacity(
                          opacity: _opacityAnimation.value,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2.0),
                            child: Text('y', style: textStyle),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
