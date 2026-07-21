import 'package:flutter/material.dart';

/// Shimmer skeleton loading card for list items.
/// Usage: replace any list tile with ShimmerCard() during loading state.
class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A shimmer list with N placeholder items.
class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final double spacing;

  const ShimmerList({
    super.key,
    this.count = 5,
    this.itemHeight = 80,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      itemBuilder: (_, _) => ShimmerCard(height: itemHeight),
    );
  }
}
