import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_math_with_ai/app/theme.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/core/widgets/app_segmented_control.dart';
import 'package:speed_math_with_ai/core/widgets/question_text_widget.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';
import 'package:speed_math_with_ai/domain/questions/question_generator_registry.dart';

/// Hidden diagnostic gallery screen showing rendered sample questions for all 16 topics x 3 difficulties.
///
/// Supports interactive preview at 320, 360, and 411 dp card widths, and 1.0x or 1.3x text scales.
/// Highlights in red if any question falls back to plain-text rendering.
class QuestionGalleryScreen extends StatefulWidget {
  const QuestionGalleryScreen({super.key});

  @override
  State<QuestionGalleryScreen> createState() => _QuestionGalleryScreenState();
}

class _QuestionGalleryScreenState extends State<QuestionGalleryScreen> {
  double _cardWidth = 360.0;
  double _textScale = 1.0;
  late final Map<String, List<Question>> _samples;

  @override
  void initState() {
    super.initState();
    QuestionTextWidget.trackFallbacks = true;
    QuestionTextWidget.fallbackQuestions.clear();
    _generateAllSamples();
  }

  @override
  void dispose() {
    QuestionTextWidget.trackFallbacks = false;
    super.dispose();
  }

  void _generateAllSamples() {
    _samples = {};
    for (final topic in Topic.standardTopics) {
      final gen = QuestionGeneratorRegistry.getGenerator(topic);
      for (final diff in [Difficulty.easy, Difficulty.medium, Difficulty.hard]) {
        final key = '${topic.name}_${diff.name}';
        final list = <Question>[];
        for (int i = 0; i < 3; i++) {
          final q = gen.generateUnique(
            difficulty: diff,
            random: Random(topic.index * 100 + diff.index * 10 + i + 1),
          );
          list.add(q);
        }
        _samples[key] = list;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(_textScale),
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Question Gallery',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/settings');
                }
              },
            ),
          ),
        body: Column(
          children: [
            // Controls header: Width and Text Scale
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Card Width:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppSegmentedControl<double>(
                          selectedValue: _cardWidth,
                          items: const [
                            AppSegmentedItem(value: 320.0, label: '320 dp'),
                            AppSegmentedItem(value: 360.0, label: '360 dp'),
                            AppSegmentedItem(value: 411.0, label: '411 dp'),
                          ],
                          onValueChanged: (val) => setState(() => _cardWidth = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Text Scale:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppSegmentedControl<double>(
                          selectedValue: _textScale,
                          items: const [
                            AppSegmentedItem(value: 1.0, label: '1.0x'),
                            AppSegmentedItem(value: 1.3, label: '1.3x'),
                          ],
                          onValueChanged: (val) => setState(() => _textScale = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Gallery List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: Topic.standardTopics.length,
                itemBuilder: (context, tIndex) {
                  final topic = Topic.standardTopics[tIndex];
                  final topicColor = AppTheme.getTopicColor(topic);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: topicColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                topic.symbol,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: topicColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              topic.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: topicColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final diff in [Difficulty.easy, Difficulty.medium, Difficulty.hard]) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Text(
                            diff.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        ...?_samples['${topic.name}_${diff.name}']?.map((q) {
                          final usedFallback = QuestionTextWidget.fallbackQuestions
                              .contains(q.displayText.trim());

                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                width: _cardWidth,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: usedFallback
                                        ? Colors.red
                                        : topicColor.withValues(alpha: 0.3),
                                    width: usedFallback ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (usedFallback)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'FALLBACK USED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    QuestionTextWidget(text: q.displayText),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      const Divider(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
