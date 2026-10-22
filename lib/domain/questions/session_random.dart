import 'dart:math';

import '../../core/enums/enums.dart';

/// Utility for creating seeded [Random] instances for practice sessions.
///
/// Each session starts with a fresh seed (from current time).
/// Each topic derives its own seed so different topics don't produce
/// the same operand sequences even with the same session seed.
class SessionRandom {
  /// Creates a fresh session seed from the current time.
  static int newSessionSeed() => DateTime.now().microsecondsSinceEpoch;

  /// Derives a per-topic [Random] from a session seed.
  ///
  /// Combines the session seed with the topic's index to ensure
  /// different topics produce different sequences.
  static Random forTopic(int sessionSeed, Topic topic) {
    // Mix session seed with topic index using a simple hash
    final topicSeed = sessionSeed ^ (topic.index * 0x9E3779B9 + 0x5A17);
    return Random(topicSeed);
  }
}
