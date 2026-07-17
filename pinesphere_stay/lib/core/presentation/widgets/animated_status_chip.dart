import 'package:flutter/material.dart';

class AnimatedStatusChip extends StatefulWidget {
  final String label;
  final Color baseColor;
  final bool isPulsating;
  final IconData? icon;

  const AnimatedStatusChip({
    super.key,
    required this.label,
    required this.baseColor,
    this.isPulsating = false,
    this.icon,
  });

  @override
  State<AnimatedStatusChip> createState() => _AnimatedStatusChipState();
}

class _AnimatedStatusChipState extends State<AnimatedStatusChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _opacityAnimation = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsating && !oldWidget.isPulsating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsating && oldWidget.isPulsating) {
      _controller.stop();
      _controller.value = 0; // reset
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isPulsating 
                ? widget.baseColor.withValues(alpha: _opacityAnimation.value)
                : widget.baseColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: widget.baseColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: widget.baseColor),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: widget.baseColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
