import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The app's local storage.
///
/// Two separate databases on purpose:
///
/// * [openClient] is the phone's own data — wallet, goals and the outbox of
///   actions waiting to go out.
/// * [openServer] stands in for NovaPay's backend. Keeping it in its own file
///   makes the boundary honest: the client cannot read or repair the server's
///   record of what it has already processed.
abstract final class AppDatabase {
  static const clientFile = 'novapay_client.db';
  static const serverFile = 'novapay_server.db';

  /// Outbox row states.
  static const statusPending = 'pending';
  static const statusInFlight = 'in_flight';
  static const statusSucceeded = 'succeeded';
  static const statusFailed = 'failed';

  /// Queued action kinds.
  static const typeTransfer = 'transfer';
  static const typeContribution = 'contribution';

  static Future<Database> openClient({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    return f.openDatabase(
      path ?? p.join(await f.getDatabasesPath(), clientFile),
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: _enableForeignKeys,
        onCreate: _createClient,
      ),
    );
  }

  static Future<Database> openServer({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    return f.openDatabase(
      path ?? p.join(await f.getDatabasesPath(), serverFile),
      options: OpenDatabaseOptions(version: 1, onCreate: _createServer),
    );
  }

  static Future<void> _enableForeignKeys(Database db) =>
      db.execute('PRAGMA foreign_keys = ON');

  static Future<void> _createClient(Database db, int version) async {
    // Everything the user queued. A row lives here from the moment they tap
    // Send until the server has confirmed it, so it survives the app closing.
    await db.execute('''
      CREATE TABLE outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idempotency_key TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    // Oldest first, and only the rows sync cares about.
    await db.execute(
      'CREATE INDEX idx_outbox_status_created ON outbox (status, created_at)',
    );

    await db.execute('''
      CREATE TABLE wallet (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        balance_kobo INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        counterparty TEXT NOT NULL,
        detail TEXT,
        amount_kobo INTEGER NOT NULL,
        incoming INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_transactions_created ON transactions (created_at DESC)',
    );

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_kobo INTEGER NOT NULL,
        saved_kobo INTEGER NOT NULL DEFAULT 0,
        target_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createServer(Database db, int version) async {
    // The server's record of every request it has already handled, keyed by the
    // idempotency key the client generated. A replayed request finds its row
    // here and gets the original answer back instead of being processed twice.
    await db.execute('''
      CREATE TABLE processed_requests (
        idempotency_key TEXT PRIMARY KEY,
        outcome TEXT NOT NULL,
        reference TEXT,
        reason TEXT,
        amount_kobo INTEGER NOT NULL,
        processed_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE account (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        balance_kobo INTEGER NOT NULL,
        sent_today_kobo INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
