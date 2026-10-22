import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/coach/coach_constants.dart';
import '../db/database_helper.dart';
import '../models/coach_message.dart';

/// Repository managing chat history and user feedback reports for the on-device AI Coach.
class CoachRepository {
  final DatabaseHelper _dbHelper;

  CoachRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Retrieves preserved chat history in chronological order, capped at [limit].
  Future<List<CoachMessage>> getMessages({int limit = CoachConstants.maxChatHistory}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableCoachMessages,
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map((r) => CoachMessage.fromMap(r)).toList();
  }

  /// Saves a message turn and enforces the 100-message storage ceiling.
  Future<int> insertMessage(CoachMessage message) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      DatabaseHelper.tableCoachMessages,
      message.toMap(),
    );

    // Prune messages older than the top 100
    await db.rawDelete('''
      DELETE FROM ${DatabaseHelper.tableCoachMessages}
      WHERE id NOT IN (
        SELECT id FROM ${DatabaseHelper.tableCoachMessages}
        ORDER BY created_at DESC
        LIMIT ${CoachConstants.maxChatHistory}
      )
    ''');

    return id;
  }

  /// Clears all chat history from local SQLite storage.
  Future<void> clearMessages() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableCoachMessages);
  }

  /// Stores a local feedback report when the user flags a coach response.
  Future<int> saveReport({
    required String userMessage,
    required String coachReply,
    required String reason,
  }) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseHelper.tableCoachReports,
      {
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'user_message': userMessage,
        'coach_reply': coachReply,
        'reason': reason,
      },
    );
  }
}

/// Riverpod provider for the coach repository.
final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepository();
});
