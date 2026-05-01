import 'package:flutter/material.dart';

/// A subtle fade + scale + slide transition. Replaces MaterialPageRoute for
/// in-app navigation that should feel premium rather than platform-generic.
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  FadeThroughRoute({required this.builder, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (ctx, _, _) => builder(ctx),
          transitionsBuilder: (_, animation, secondary, child) {
            final fadeIn = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
            );
            final scaleIn = Tween<double>(begin: 0.97, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
            final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(parent: secondary, curve: Curves.easeInCubic),
            );
            return FadeTransition(
              opacity: fadeOut,
              child: FadeTransition(
                opacity: fadeIn,
                child: ScaleTransition(scale: scaleIn, child: child),
              ),
            );
          },
        );
}
