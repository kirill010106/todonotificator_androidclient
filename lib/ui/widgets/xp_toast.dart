import 'package:flutter/material.dart';

/// Lightweight floating XP indicator.
///
/// Shows a pill-shaped label ("+10 XP" / "−5 XP") that slides upward
/// and fades out over 1.4 s. Uses [Overlay] so it is non-blocking and
/// appears on top of any content.
///
/// Usage:
/// ```dart
/// XpToast.show(context, delta: 10);
/// ```
class XpToast {
  XpToast._();

  static void show(BuildContext context, {required int delta}) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    bool removed = false;

    entry = OverlayEntry(
      builder: (_) => _XpToastWidget(
        delta: delta,
        onDone: () {
          if (!removed) {
            removed = true;
            entry.remove();
          }
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _XpToastWidget extends StatefulWidget {
  const _XpToastWidget({required this.delta, required this.onDone});

  final int delta;
  final VoidCallback onDone;

  @override
  State<_XpToastWidget> createState() => _XpToastWidgetState();
}

class _XpToastWidgetState extends State<_XpToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _slideY; // 0 → -40 px (upward)

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _opacity = TweenSequence([
      // fade in
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      // hold
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      // fade out
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_ctrl);

    _slideY = Tween(begin: 0.0, end: -44.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.delta >= 0;
    final label = isPositive ? '+${widget.delta} XP' : '${widget.delta} XP';
    final color =
        isPositive ? const Color(0xFF176A57) : const Color(0xFFE25C5C);
    final bgColor = isPositive
        ? const Color(0xFFE6F3EE)
        : const Color(0xFFFDEAEA);

    return Positioned(
      // Appears near the top-center of the screen (below status bar)
      top: MediaQuery.of(context).padding.top + 72,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _slideY.value),
            child: Opacity(
              opacity: _opacity.value,
              child: Center(
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: color.withAlpha(80),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
