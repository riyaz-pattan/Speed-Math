import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/enums.dart';
import '../../../data/models/coach_message.dart';
import '../../../data/repositories/coach_repository.dart';
import '../../../data/repositories/mistake_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/skill_repository.dart';
import '../../../domain/adaptive/skill_rating.dart';
import '../../../domain/coach/coach_constants.dart';
import '../../../domain/coach/coach_context.dart';
import '../../../domain/coach/coach_engine.dart';

/// State of the Coach chat screen.
class CoachState {
  final List<CoachMessage> messages;
  final bool isLoading;
  final List<String> suggestions;
  final CoachContext? context;

  const CoachState({
    this.messages = const [],
    this.isLoading = false,
    this.suggestions = CoachConstants.readyMadeQuestions,
    this.context,
  });

  CoachState copyWith({
    List<CoachMessage>? messages,
    bool? isLoading,
    List<String>? suggestions,
    CoachContext? context,
  }) {
    return CoachState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      suggestions: suggestions ?? this.suggestions,
      context: context ?? this.context,
    );
  }
}

/// State notifier managing conversation flow, on-device AI Coach execution,
/// local persistence, and feedback reporting.
class CoachController extends StateNotifier<CoachState> {
  final Ref _ref;
  final CoachEngine _coachEngine;
  bool _initialized = false;

  CoachController(this._ref, {CoachEngine? engine})
      : _coachEngine = engine ?? CoachEngine(),
        super(const CoachState()) {
    _init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    state = state.copyWith(isLoading: true);

    await _coachEngine.initialize(assetLoader: rootBundle.loadString);
    final repo = _ref.read(coachRepositoryProvider);
    final savedMessages = await repo.getMessages();

    final coachContext = await _buildCoachContext();

    if (savedMessages.isEmpty) {
      final welcomeMsg = CoachMessage(
        role: 'coach',
        text: 'Hey! I am your Coach. Ask me anything about your practice, speed, weak spots, or plans.',
        actions: const [],
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await repo.insertMessage(welcomeMsg);
      state = state.copyWith(
        messages: [welcomeMsg],
        isLoading: false,
        suggestions: CoachConstants.readyMadeQuestions,
        context: coachContext,
      );
    } else {
      state = state.copyWith(
        messages: savedMessages,
        isLoading: false,
        suggestions: CoachConstants.readyMadeQuestions,
        context: coachContext,
      );
    }
  }

  /// Sends a user message, executes intent classification, and generates an on-device reply.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final repo = _ref.read(coachRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    final userMessage = CoachMessage(
      role: 'user',
      text: trimmed,
      actions: const [],
      createdAt: now,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    await repo.insertMessage(userMessage);

    // Ensure context is up to date
    CoachContext currentContext = state.context ?? await _buildCoachContext();

    final reply = await _coachEngine.processMessage(trimmed, currentContext);

    final coachMessage = CoachMessage(
      role: 'coach',
      text: reply.text,
      actions: reply.actions,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await repo.insertMessage(coachMessage);

    final nextSuggestions = reply.suggestions.isNotEmpty
        ? reply.suggestions
        : CoachConstants.readyMadeQuestions;

    state = state.copyWith(
      messages: [...state.messages, coachMessage],
      isLoading: false,
      suggestions: nextSuggestions,
      context: currentContext,
    );
  }

  /// Saves a user feedback report about a specific coach reply.
  Future<void> reportAnswer({
    required CoachMessage message,
    required String reason,
  }) async {
    final repo = _ref.read(coachRepositoryProvider);

    // Find the preceding user message if available
    String userQuery = '';
    final idx = state.messages.indexOf(message);
    if (idx > 0 && state.messages[idx - 1].isUser) {
      userQuery = state.messages[idx - 1].text;
    }

    await repo.saveReport(
      userMessage: userQuery,
      coachReply: message.text,
      reason: reason,
    );
  }

  /// Clears chat history and inserts a fresh welcome greeting.
  Future<void> clearChat() async {
    final repo = _ref.read(coachRepositoryProvider);
    await repo.clearMessages();
    _coachEngine.resetContext();

    final welcomeMsg = CoachMessage(
      role: 'coach',
      text: 'Hey! I am your Coach. Ask me anything about your practice, speed, weak spots, or plans.',
      actions: const [],
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await repo.insertMessage(welcomeMsg);

    state = state.copyWith(
      messages: [welcomeMsg],
      suggestions: CoachConstants.readyMadeQuestions,
    );
  }

  Future<CoachContext> _buildCoachContext() async {
    final analyzer = _ref.read(reportAnalyzerProvider);
    final reportData = await analyzer.generateReport();

    final planGen = _ref.read(todaysPlanGeneratorProvider);
    final todayPlan = await planGen.getTodayPlan(reportData);

    final sessionRepo = _ref.read(sessionRepositoryProvider);
    final recentSessions = await sessionRepo.getRecentSessions(20);

    final mistakeRepo = _ref.read(mistakeRepositoryProvider);
    final mistakeCount = await mistakeRepo.getMistakeCount();
    final mistakes = await mistakeRepo.getMistakesForPractice(limit: 50);

    final skillRepo = _ref.read(skillRepositoryProvider);
    final allRatings = await skillRepo.getAllRatings();
    final skillMap = <Topic, Map<Difficulty, SkillRating>>{};
    for (final r in allRatings) {
      skillMap.putIfAbsent(r.topic, () => {})[r.difficulty] = r;
    }

    return CoachContext(
      reportData: reportData,
      todayPlan: todayPlan,
      recentSessions: recentSessions,
      mistakeCount: mistakeCount,
      mistakes: mistakes,
      skillRatings: skillMap,
    );
  }

  /// Refreshes in-memory CoachContext with latest practice, report, and mistake data.
  Future<void> refreshContext() async {
    final newContext = await _buildCoachContext();
    state = state.copyWith(context: newContext);
  }
}

/// Riverpod provider for the [CoachController].
final coachControllerProvider =
    StateNotifierProvider<CoachController, CoachState>((ref) {
  final controller = CoachController(ref);
  // Listen to practice data changes and refresh coach context
  ref.listen(dataRevisionProvider, (_, __) {
    controller.refreshContext();
  });
  return controller;
});
