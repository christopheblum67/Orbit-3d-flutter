import 'package:flutter/material.dart';

class PlayerVideoViewport extends StatelessWidget {
  const PlayerVideoViewport({
    super.key,
    required this.aspectRatio,
    required this.child,
    this.cover = false,
  });

  final double aspectRatio;
  final Widget child;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    if (cover) {
      return ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: aspectRatio > 0 ? aspectRatio : 16 / 9,
              height: 1,
              child: child,
            ),
          ),
        ),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: child,
      ),
    );
  }
}
