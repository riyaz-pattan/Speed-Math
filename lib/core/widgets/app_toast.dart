import 'dart:async';
import 'package:flutter/material.dart';

/// Semantic types of toasts displaying distinct soft accent icons.
enum AppToastType {
  success,
  info,
  warning,
  error;

  IconData get icon {
    switch (this) {
      case AppToastType.success:
        return Icons.check_circle_rounded;
      case AppToastType.info:
        return Icons.info_rounded;
      case AppToastType.warning:
        return Icons.warning_rounded;
      case AppToastType.error:
        return Icons.error_rounded;
    }
  }

  Color get iconColor {
    switch (this) {
      case AppToastType.success:
        return const Color(0xFF4ADE80); // soft green
      case AppToastType.info:
        return const Color(0xFF60A5FA); // soft blue
      case AppToastType.warning:
        return const Color(0xFFFBBF24); // soft amber
      case AppToastType.error:
        return const Color(0xFFF87171); // soft red
    }
  }
}

/// Minimal, beautiful, overlay-based toast system anchored at the top of the screen.
///
/// Ensures touches pass through completely to screens underneath while allowing
/// tap or swipe-up dismissals and interactive action buttons.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static _AppToastWidgetState? _currentState;

  /// Shows an overlay toast at the top of [context].
  ///
  /// Automatically replaces any existing toast.
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.of(context);

    // If an existing toast is active, smoothly animate it out or replace it
    if (_currentEntry != null) {
      _currentEntry?.remove();
      _currentEntry = null;
      _currentState = null;
    }

    final effectiveDuration = duration ??
        (actionLabel != null
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 2500));

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _AppToastWidget(
          message: message,
          type: type,
          actionLabel: actionLabel,
          onAction: onAction,
          duration: effectiveDuration,
          onDismissed: () {
            if (_currentEntry == entry) {
              _currentEntry?.remove();
              _currentEntry = null;
              _currentState = null;
            }
          },
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Manually dismisses active toast immediately.
  static void dismiss() {
    _currentState?.dismiss();
  }
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppToastWidget({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppToast._currentState = this;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      dismiss();
    });
  }

  void dismiss() {
    _timer?.cancel();
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    if (AppToast._currentState == this) {
      AppToast._currentState = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: false,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: dismiss,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! < -3) {
                    dismiss();
                  }
                },
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.type.icon,
                              color: widget.type.iconColor,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (widget.actionLabel != null) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  dismiss();
                                  widget.onAction?.call();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.actionLabel!,
                                    style: const TextStyle(
                                      color: Color(0xFF93C5FD), // soft sky blue
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
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
