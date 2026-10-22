import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/enums/enums.dart';
import '../../data/models/coach_message.dart';
import '../../domain/coach/coach_reply.dart';
import '../practice_session/models/practice_models.dart';
import 'controllers/coach_controller.dart';

/// The on-device AI Coach chat screen featuring a modern AI messenger interface
/// (ChatGPT / Claude / Gemini style) with auto-resizing pill composer, starter cards,
/// selectable message text, and grounded practice actions.
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
          context.push('/practice');
        }
        break;
      case CoachActionType.openReport:
        context.push('/report');
        break;
      case CoachActionType.practiceMistakes:
        context.push('/mistakes');
        break;
      case CoachActionType.openStats:
        context.push('/stats');
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
            final colorScheme = Theme.of(context).colorScheme;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Report this answer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    Text(
                      'Help us improve Coach responses. What went wrong?',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks, saved on your phone.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(coachControllerProvider);

    ref.listen(coachControllerProvider, (_, __) {
      _scrollToBottom();
    });

    final isOnlyWelcome = state.messages.length <= 1;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Coach',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  'On-device practice assistant',
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
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
                    Icon(Icons.delete_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Clear chat'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // Messages List or Welcome Starter Cards
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: state.messages.length + (state.isLoading ? 1 : 0) + (isOnlyWelcome ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < state.messages.length) {
                    final msg = state.messages[index];
                    return _buildMessageItem(msg, colorScheme);
                  }

                  if (isOnlyWelcome && index == state.messages.length) {
                    return _buildStarterCards(colorScheme);
                  }

                  return _buildThinkingIndicator(colorScheme);
                },
              ),
            ),

            // Ready-made Question Chips Row (Fades away when text is entered)
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _hasText ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: _buildSuggestionsRow(state.suggestions, colorScheme),
              secondChild: const SizedBox.shrink(),
            ),

            // Modern Pill Composer
            _buildModernComposer(colorScheme),

            // Bottom Disclaimer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Text(
                'Coach answers come from your practice on this phone. It cannot answer general questions.',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarterCards(ColorScheme colorScheme) {
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
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Or tap a starter to begin:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.45,
            children: starters.map((s) {
              return Material(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _handleSend(s.title),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(s.icon, size: 20, color: colorScheme.primary),
                        const SizedBox(height: 6),
                        Text(
                          s.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(CoachMessage msg, ColorScheme colorScheme) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: SelectableText(
              msg.text,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onPrimaryContainer,
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
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: 17,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: SelectableText(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
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
                      return _buildActionButton(act, colorScheme);
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
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                        icon: Icon(
                          Icons.flag_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                        ),
                        label: Text(
                          'Report this answer',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
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

  Widget _buildActionButton(CoachAction action, ColorScheme colorScheme) {
    final isPrimary = action.type == CoachActionType.startPractice ||
        action.type == CoachActionType.practiceMistakes;

    if (isPrimary) {
      return FilledButton.icon(
        onPressed: () => _handleAction(action),
        style: FilledButton.styleFrom(
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
                : Icons.touch_app_rounded,
        size: 14,
      ),
      label: Text(
        action.label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildThinkingIndicator(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: 15,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Analyzing practice data...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow(List<String> suggestions, ColorScheme colorScheme) {
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.15),
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

  Widget _buildModernComposer(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask your coach anything about your practice',
                  hintStyle: TextStyle(fontSize: 13.5),
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
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.12),
                    foregroundColor: _hasText
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withValues(alpha: 0.38),
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
