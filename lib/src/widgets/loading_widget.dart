import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Loading indicator widget
class LoadingWidget extends StatelessWidget {
  final LoadingType type;
  final Widget? customWidget;

  const LoadingWidget({
    Key? key,
    required this.type,
    this.customWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case LoadingType.spinner:
        return const Center(
          child: CircularProgressIndicator(),
        );

      case LoadingType.shimmer:
        return const ShimmerLoading();

      case LoadingType.custom:
        return customWidget ?? const Center(child: CircularProgressIndicator());
    }
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({Key? key}) : super(key: key);

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
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
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}