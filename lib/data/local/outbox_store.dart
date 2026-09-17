import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:novawallet/data/local/app_database.dart';

/// One action the user asked for, waiting to reach NovaPay.
///
/// A row is written *before* any network call and only cleared once the server
/// has answered, so closing the app — or losing power — cannot lose it.
class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.idempotencyKey,
    required this.type,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.lastError,
  });

  final int id;

  /// Generated once, when the user taps Send. Reused on every retry, which is
  /// what lets the server recognise a replay.
  final String idempotencyKey;

  /// [AppDatabase.typeTransfer] or [AppDatabase.typeContribution].
  final String type;

  final Map<String, Object?> payload;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;

  bool get isPending => status == AppDatabase.statusPending;
  bool get isInFlight => status == AppDatabase.statusInFlight;
  bool get isFailed => status == AppDatabase.statusFailed;

  /// Still owed to the server: never sent, or sent without a confirmed answer.
  bool get needsSending => isPending || isInFlight;

  static OutboxItem fromRow(Map<String, Object?> row) => OutboxItem(
    id: row['id'] as int,
    idempotencyKey: row['idempotency_key'] as String,
    type: row['type'] as String,
    payload: jsonDecode(row['payload'] as String) as Map<String, Object?>,
    status: row['status'] as String,
    attempts: row['attempts'] as int,
    lastError: row['last_error'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
  );
}

/// Reads and writes the outbox table. Deliberately dumb: it records state, and
/// the sync engine decides what to do about it.
class OutboxStore {
  OutboxStore(this._db);

  final Database _db;

  static const _table = 'outbox';

  /// Queues an action. Throws if this idempotency key is already queued, which
  /// would mean the caller generated it more than once for the same attempt.
  Future<OutboxItem> enqueue({
    required String idempotencyKey,
    required String type,
    required Map<String, Object?> payload,
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    final id = await _db.insert(_table, {
      'idempotency_key': idempotencyKey,
      'type': type,
      'payload': jsonEncode(payload),
      'status': AppDatabase.statusPending,
      'attempts': 0,
      'created_at': now.millisecondsSinceEpoch,
    });

    return OutboxItem(
      id: id,
      idempotencyKey: idempotencyKey,
      type: type,
      payload: payload,
      status: AppDatabase.statusPending,
      attempts: 0,
      createdAt: now,
    );
  }

  /// Everything still owed to the server, oldest first.
  ///
  /// Includes `in_flight` rows on purpose: if the app died after sending but
  /// before the answer arrived, the action must be sent again with the same key.
  /// The server recognises the key and replies with the original outcome rather
  /// than processing it twice.
  Future<List<OutboxItem>> itemsToSend() async {
    final rows = await _db.query(
      _table,
      where: 'status IN (?, ?)',
      whereArgs: [AppDatabase.statusPending, AppDatabase.statusInFlight],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(OutboxItem.fromRow).toList();
  }

  Future<List<OutboxItem>> all() async {
    final rows = await _db.query(_table, orderBy: 'created_at DESC, id DESC');
    return rows.map(OutboxItem.fromRow).toList();
  }

  Future<OutboxItem?> byId(int id) async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : OutboxItem.fromRow(rows.first);
  }

  /// About to call the server. Counts the attempt so a row that keeps failing
  /// is visible rather than silently spinning.
  Future<void> markInFlight(int id) async {
    await _db.rawUpdate(
      'UPDATE $_table SET status = ?, attempts = attempts + 1 WHERE id = ?',
      [AppDatabase.statusInFlight, id],
    );
  }

  /// The server confirmed it.
  Future<void> markSucceeded(int id) => _setStatus(
    id,
    AppDatabase.statusSucceeded,
  );

  /// The server refused it. Final: never retried automatically.
  Future<void> markFailed(int id, String reason) =>
      _setStatus(id, AppDatabase.statusFailed, error: reason);

  /// The request never got an answer. Back in the queue for the next attempt.
  Future<void> revertToPending(int id, {String? error}) =>
      _setStatus(id, AppDatabase.statusPending, error: error);

  Future<void> _setStatus(int id, String status, {String? error}) async {
    await _db.update(
      _table,
      {'status': status, 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countWithStatus(String status) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_table WHERE status = ?',
      [status],
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
