import 'package:sqflite/sqflite.dart';

import 'package:novawallet/core/money/kobo.dart';

/// A NovaSave goal.
///
/// Amounts are whole kobo and progress is integer arithmetic, so a goal can
/// never show 101% from a rounding error.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    required this.targetDate,
    required this.createdAt,
  });

  final String id;
  final String name;
  final Kobo target;

  /// What the phone believes is saved, including contributions that are still
  /// queued. The server is the authority; this is what the user sees now.
  final Kobo saved;

  final DateTime targetDate;
  final DateTime createdAt;

  int get percent => saved.percentOf(target);

  Kobo get remaining {
    final left = target - saved;
    return left.isNegative ? Kobo.zero : left;
  }

  bool get isComplete => saved >= target;

  static Goal fromRow(Map<String, Object?> row) => Goal(
    id: row['id'] as String,
    name: row['name'] as String,
    target: Kobo(row['target_kobo'] as int),
    saved: Kobo(row['saved_kobo'] as int),
    targetDate: DateTime.fromMillisecondsSinceEpoch(row['target_date'] as int),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );
}

/// Reads and writes the `goals` table.
///
/// Like [OutboxStore] this is deliberately dumb: it records what the phone
/// knows. Whether a contribution has actually reached NovaPay is the outbox's
/// business, not this table's.
class GoalStore {
  GoalStore(this._db);

  final Database _db;

  static const _table = 'goals';

  Future<List<Goal>> all() async {
    final rows = await _db.query(_table, orderBy: 'created_at ASC');
    return rows.map(Goal.fromRow).toList();
  }

  Future<Goal?> byId(String id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Goal.fromRow(rows.first);
  }

  /// Summed in kobo, never as a double.
  Future<Kobo> totalSaved() async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(saved_kobo), 0) AS total FROM $_table',
    );
    return Kobo((rows.first['total'] as int?) ?? 0);
  }

  Future<Goal> create({
    required String id,
    required String name,
    required Kobo target,
    required DateTime targetDate,
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    final goal = Goal(
      id: id,
      name: name,
      target: target,
      saved: Kobo.zero,
      targetDate: targetDate,
      createdAt: now,
    );

    await _db.insert(_table, {
      'id': goal.id,
      'name': goal.name,
      'target_kobo': goal.target.value,
      'saved_kobo': 0,
      'target_date': targetDate.millisecondsSinceEpoch,
      'created_at': now.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return goal;
  }

  /// Credits the goal locally, the moment the user contributes.
  ///
  /// This happens whether or not the network is there: the contribution is
  /// already durable in the outbox, so showing it immediately is honest. If the
  /// server later rejects it, [debit] puts it back.
  Future<void> credit(String goalId, Kobo amount) async {
    await _db.rawUpdate(
      'UPDATE $_table SET saved_kobo = saved_kobo + ? WHERE id = ?',
      [amount.value, goalId],
    );
  }

  /// Reverses a credit when the server refuses the contribution.
  Future<void> debit(String goalId, Kobo amount) async {
    await _db.rawUpdate(
      'UPDATE $_table SET saved_kobo = MAX(saved_kobo - ?, 0) WHERE id = ?',
      [amount.value, goalId],
    );
  }

  /// The three goals from the design, so the app has something to show on a
  /// first run. Only ever runs when the table is empty.
  Future<void> seedIfEmpty() async {
    final existing = await _db.query(_table, limit: 1);
    if (existing.isNotEmpty) return;

    await create(
      id: 'rent-2027',
      name: 'Rent 2027',
      target: Kobo.fromNaira(600000),
      targetDate: DateTime(2027, 1, 31),
      createdAt: DateTime(2026, 6, 1),
    );
    await credit('rent-2027', Kobo.fromNaira(285000));

    await create(
      id: 'new-laptop',
      name: 'New laptop',
      target: Kobo.fromNaira(450000),
      targetDate: DateTime(2026, 11, 30),
      createdAt: DateTime(2026, 7, 12),
    );
    await credit('new-laptop', Kobo.fromNaira(97500));

    await create(
      id: 'emergency-fund',
      name: 'Emergency fund',
      target: Kobo.fromNaira(200000),
      targetDate: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 8, 3),
    );
    await credit('emergency-fund', Kobo.fromNaira(30000));
  }
}
