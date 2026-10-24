// lib/features/learn/engine/whiteboard_player.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import 'lesson_data.dart';
import 'whiteboard_painter.dart';

/// Animated whiteboard player with Back / Play-Pause / Next controls.
class WhiteboardPlayer extends StatefulWidget {
  const WhiteboardPlayer({
    super.key,
    required this.steps,
    required this.canvasHeight,
    this.onFinished,
  });

  final List<LessonStep> steps;
  final double canvasHeight;
  final VoidCallback? onFinished;

  @override
  State<WhiteboardPlayer> createState() => WhiteboardPlayerState();
}

class WhiteboardPlayerState extends State<WhiteboardPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _currentStep = 0;
  bool _isPlaying = false;
  double _speed = 1.0;

  static const List<double> _speeds = [0.75, 1.0, 1.5];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener(_onAnimStatus);
    _playCurrentStep();
  }

  void _playCurrentStep() {
    if (!mounted) return;
    final disableAnim = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnim) {
      _controller.value = 1.0;
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    _controller.duration = Duration(milliseconds: (1800 / _speed).round());
    _controller.forward(from: 0);
    setState(() => _isPlaying = true);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _goNext() {
    HapticFeedback.selectionClick();
    if (_currentStep < widget.steps.length - 1) {
      setState(() => _currentStep++);
      _playCurrentStep();
    } else {
      widget.onFinished?.call();
    }
  }

  void _goBack() {
    HapticFeedback.selectionClick();
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isPlaying = false;
      });
      _controller.value = 1.0;
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _controller.stop();
      setState(() => _isPlaying = false);
    } else {
      if (_controller.value >= 1.0) {
        _controller.forward(from: 0);
      } else {
        _controller.forward();
      }
      setState(() => _isPlaying = true);
    }
  }

  void _cycleSpeed() {
    final idx = _speeds.indexOf(_speed);
    setState(() {
      _speed = _speeds[(idx + 1) % _speeds.length];
      if (_isPlaying) {
        _controller.duration = Duration(milliseconds: (1800 / _speed).round());
      }
    });
  }

  int get currentStep => _currentStep;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == widget.steps.length - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Canvas
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return LayoutBuilder(builder: (context, constraints) {
                final scale = constraints.maxWidth / 360.0;
                final canvasH = widget.canvasHeight * scale;
                return Container(
                  width: constraints.maxWidth,
                  height: canvasH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    painter: WhiteboardPainter(
                      steps: widget.steps,
                      currentStepIndex: _currentStep,
                      stepProgress: _controller.value,
                      disableAnimations:
                          MediaQuery.maybeOf(context)?.disableAnimations ?? false,
                    ),
                    size: Size(constraints.maxWidth, canvasH),
                  ),
                );
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.steps.length, (i) {
            final active = i == _currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryColor : AppTheme.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: 10),

        // Caption
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            widget.steps.isNotEmpty ? widget.steps[_currentStep].caption : '',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 12),

        // Controls row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CtrlBtn(icon: Icons.skip_previous_rounded, onTap: isFirst ? null : _goBack),
            const SizedBox(width: 8),
            _CtrlBtn(
              icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onTap: _togglePlay,
              primary: true,
            ),
            const SizedBox(width: 8),
            _CtrlBtn(
              icon: isLast ? Icons.check_rounded : Icons.skip_next_rounded,
              onTap: _goNext,
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: _cycleSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_speed}x',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({required this.icon, required this.onTap, this.primary = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: disabled
              ? AppTheme.borderLight
              : primary
                  ? AppTheme.primaryColor
                  : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: (!primary && !disabled)
              ? Border.all(color: AppTheme.borderLight)
              : null,
          boxShadow: (primary && !disabled) ? AppTheme.cardShadow : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color: disabled
              ? AppTheme.textSecondary.withValues(alpha: 0.4)
              : primary
                  ? Colors.white
                  : AppTheme.textPrimary,
        ),
      ),
    );
  }
}
