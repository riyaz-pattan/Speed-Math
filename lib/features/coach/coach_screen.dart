import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import 'package:speed_math_with_ai/core/widgets/app_toast.dart';
import 'package:speed_math_with_ai/core/widgets/screen_header.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../data/models/coach_message.dart';
import '../../domain/coach/coach_reply.dart';
import '../practice_session/models/practice_models.dart';
import '../practice_setup/practice_setup_screen.dart';
import '../report/report_screen.dart';
import '../stats/stats_screen.dart';
import 'controllers/coach_controller.dart';

/// The on-device AI Coach chat screen featuring a modern AI messenger interface
/// with auto-resizing pill composer, starter cards, selectable message text,
/// and grounded practice actions.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coachControllerProvider.notifier).refreshContext();
    });
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? presetText]) {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (presetText == null) {
      _textController.clear();
      setState(() => _hasText = false);
    }

    ref.read(coachControllerProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _handleAction(CoachAction action) {
    switch (action.type) {
      case CoachActionType.startPractice:
        if (action.payload is PracticeConfig) {
          context.push('/practice/session', extra: action.payload);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PracticeSetupScreen(
                initialTopic:
                    action.payload is Topic ? action.payload as Topic : null,
              ),
            ),
          );
        }
        break;
      case CoachActionType.openReport:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReportScreen()),
        );
        break;
      case CoachActionType.practiceMistakes:
        context.push('/mistakes');
        break;
      case CoachActionType.openStats:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StatsScreen()),
        );
        break;
      case CoachActionType.selectTopic:
        if (action.payload is Topic) {
          _handleSend((action.payload as Topic).displayName);
        }
        break;
      case CoachActionType.suggestQuestion:
        if (action.payload is String) {
          _handleSend(action.payload as String);
        }
        break;
      case CoachActionType.openLearn:
        if (action.payload is String && (action.payload as String).isNotEmpty) {
          context.push('/learn/${action.payload}');
        } else {
          context.push('/learn');
        }
        break;
    }
  }

  Future<void> _showReportDialog(CoachMessage message) async {
    final reasons = [
      'Wrong numbers',
      'Not helpful',
      'Offensive',
      'Other',
    ];
    String selectedReason = reasons.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Report this answer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              content: RadioGroup<String>(
                groupValue: selectedReason,
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedReason = val);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help us improve Coach responses. What went wrong?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...reasons.map((r) {
                      return RadioListTile<String>(
                        title: Text(r, style: const TextStyle(fontSize: 14)),
                        value: r,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      await ref.read(coachControllerProvider.notifier).reportAnswer(
            message: message,
            reason: selectedReason,
          );
      if (mounted) {
        AppToast.show(
          context,
          message: 'Thanks, saved on your phone.',
          type: AppToastType.success,
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppToast.show(
      context,
      message: 'Copied to clipboard',
      type: AppToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coachControllerProvider);

    ref.listen(coachControllerProvider, (_, __) {
      _scrollToBottom();
    });

    final isOnlyWelcome = state.messages.length <= 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.canvasBackground,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              ScreenHeader(
                title: 'Adaptive Coach',
                subtitle: 'On-device practice assistant',
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'clear') {
                    ref.read(coachControllerProvider.notifier).clearChat();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorColor),
                        SizedBox(width: 8),
                        Text('Clear chat', style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: state.messages.length + (state.isLoading ? 1 : 0) + (isOnlyWelcome ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < state.messages.length) {
                  final msg = state.messages[index];
                  return _buildMessageItem(msg);
                }

                if (isOnlyWelcome && index == state.messages.length) {
                  return _buildStarterCards();
                }

                return _buildThinkingIndicator();
              },
            ),
          ),

          // Ready-made Question Chips Row
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _hasText ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildSuggestionsRow(state.suggestions),
            secondChild: const SizedBox.shrink(),
          ),

          // Modern Pill Composer & Bottom Disclaimer with SafeArea
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModernComposer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    'Coach answers come from your practice on this phone. It cannot answer general questions.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textTertiary.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildStarterCards() {
    final starters = [
      (
        icon: Icons.track_changes_rounded,
        title: 'Where should I focus?',
        subtitle: 'Find your weakest operations & next drill',
      ),
      (
        icon: Icons.calendar_today_rounded,
        title: 'Make me a plan for today',
        subtitle: 'Get a structured ~15 minute daily workout',
      ),
      (
        icon: Icons.trending_up_rounded,
        title: 'Am I improving?',
        subtitle: 'Compare speed & accuracy vs last week',
      ),
      (
        icon: Icons.lightbulb_outline_rounded,
        title: 'Give me a tip',
        subtitle: 'Learn mental math calculation shortcuts',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Or tap a starter to begin:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: starters.map((s) {
              return TactileCard(
                onTap: () => _handleSend(s.title),
                padding: const EdgeInsets.all(12),
                borderRadius: AppTheme.radiusMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(s.icon, size: 18, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(CoachMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SelectableText(
              msg.text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    // Coach message
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TactileCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  borderRadius: AppTheme.radiusLg,
                  child: SelectableText(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),

                // Interactive Action Buttons
                if (msg.actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: msg.actions.map((act) {
                      return _buildActionButton(act);
                    }).toList(),
                  ),
                ],

                // Action Bar under Coach message: Copy + Report this answer
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        tooltip: 'Copy',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        color: AppTheme.textTertiary,
                        onPressed: () => _copyToClipboard(msg.text),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => _showReportDialog(msg),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(
                          Icons.flag_outlined,
                          size: 13,
                          color: AppTheme.textTertiary,
                        ),
                        label: const Text(
                          'Report this answer',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(CoachAction action) {
    final isPrimary = action.type == CoachActionType.startPractice ||
        action.type == CoachActionType.practiceMistakes;

    if (isPrimary) {
      return FilledButton.icon(
        onPressed: () => _handleAction(action),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(
          action.type == CoachActionType.practiceMistakes
              ? Icons.repeat_rounded
              : Icons.play_arrow_rounded,
          size: 16,
        ),
        label: Text(
          action.label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _handleAction(action),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        side: const BorderSide(color: AppTheme.primaryColor),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(
        action.type == CoachActionType.openReport
            ? Icons.insights_rounded
            : action.type == CoachActionType.openStats
                ? Icons.bar_chart_rounded
                : action.type == CoachActionType.openLearn
                    ? Icons.menu_book_rounded
                    : Icons.touch_app_rounded,
        size: 14,
      ),
      label: Text(
        action.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Analyzing practice data...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow(List<String> suggestions) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: suggestions.map((q) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  q,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                backgroundColor: AppTheme.surfaceCard,
                side: const BorderSide(
                  color: AppTheme.borderLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => _handleSend(q),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModernComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.borderLight,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ask your coach anything about your practice',
                  hintStyle: TextStyle(fontSize: 13.5, color: AppTheme.textTertiary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: AnimatedScale(
                scale: _hasText ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 150),
                child: IconButton.filled(
                  onPressed: _hasText ? () => _handleSend() : null,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: _hasText
                        ? AppTheme.primaryColor
                        : AppTheme.surfaceSecondary,
                    foregroundColor: _hasText
                        ? Colors.white
                        : AppTheme.textTertiary,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
