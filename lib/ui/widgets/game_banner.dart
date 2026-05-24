import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GameBannerType {
  standardBurn,
  hardcoreDeath,
}

class GameBanner {
  GameBanner._();

  static void show(
    BuildContext context, {
    required String message,
    required GameBannerType type,
  }) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    bool removed = false;

    entry = OverlayEntry(
      builder: (_) => _GameBannerWidget(
        message: message,
        type: type,
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

class _GameBannerWidget extends StatefulWidget {
  const _GameBannerWidget({
    required this.message,
    required this.type,
    required this.onDone,
  });

  final String message;
  final GameBannerType type;
  final VoidCallback onDone;

  @override
  State<_GameBannerWidget> createState() => _GameBannerWidgetState();
}

class _GameBannerWidgetState extends State<_GameBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _opacity = _ctrl.drive(
      TweenSequence([
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 10,
        ),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 10,
        ),
      ]),
    );

    _slideY = _ctrl.drive(
      TweenSequence([
        TweenSequenceItem(
          tween: Tween(begin: -100.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 10,
        ),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 80),
        TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -100.0).chain(CurveTween(curve: Curves.easeIn)),
          weight: 10,
        ),
      ]),
    );

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.type == GameBannerType.hardcoreDeath
        ? const Color(0xFF2D0C0C)
        : AppColors.error;
    
    final accentColor = widget.type == GameBannerType.hardcoreDeath
        ? const Color(0xFFFF5722)
        : Colors.white;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideY.value),
            child: Opacity(
              opacity: _opacity.value,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: widget.type == GameBannerType.hardcoreDeath
                        ? Border.all(color: accentColor, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.type == GameBannerType.hardcoreDeath
                            ? Icons.warning_amber_rounded
                            : Icons.local_fire_department,
                        color: accentColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
