import 'package:flutter/material.dart';

/// Fade + slight slide-up entry animation. Drop into a list and pass an
/// incrementing [index] — each child enters slightly later than the previous,
/// producing a staggered cascade. The animation runs once on first build.
class StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration stepDelay;
  final Duration duration;
  final double slideFrom;

  const StaggeredFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 60),
    this.stepDelay = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 380),
    this.slideFrom = 14,
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideFrom / 100),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = widget.baseDelay + widget.stepDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
