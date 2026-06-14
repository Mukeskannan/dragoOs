import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message_model.dart';

class ChatDB {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'drago_chat.db');

    return openDatabase(
      path,
      version: 2,   // bump version to trigger onUpgrade
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        text    TEXT    NOT NULL,
        isUser  INTEGER NOT NULL,
        time    TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE memory (
        key   TEXT PRIMARY KEY,   -- unique key; UPSERT replaces it
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old memory table (had no PRIMARY KEY on key) and recreate
      await db.execute('DROP TABLE IF EXISTS memory');
      await db.execute('''
        CREATE TABLE memory (
          key        TEXT PRIMARY KEY,
          value      TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  static Future<void> insertMessage(MessageModel msg) async {
    final db = await database;
    await db.insert('messages', {
      'text':   msg.text,
      'isUser': msg.isUser ? 1 : 0,
      'time':   msg.time.toIso8601String(),
    });
  }

  static Future<List<MessageModel>> getMessages() async {
    final db = await database;
    final rows = await db.query('messages', orderBy: 'id ASC');
    return rows.map((r) => MessageModel(
      text:   r['text']   as String,
      isUser: (r['isUser'] as int) == 1,
      time:   DateTime.parse(r['time'] as String),
    )).toList();
  }

  // ── Memory ────────────────────────────────────────────────────────────────

  /// Upsert: insert or replace if key already exists
  static Future<void> saveMemory(String key, String value) async {
    final db = await database;
    await db.insert(
      'memory',
      {
        'key':        key.toLowerCase().trim(),
        'value':      value.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,  // ← THE FIX
    );
    print('[Memory] saved: $key = $value');
  }

  static Future<String?> getMemory(String key) async {
    final db = await database;
    final rows = await db.query(
      'memory',
      where: 'key = ?',
      whereArgs: [key.toLowerCase().trim()],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first['value'] as String : null;
  }

  static Future<Map<String, String>> getAllMemory() async {
    final db = await database;
    final rows = await db.query('memory', orderBy: 'updated_at DESC');
    return {
      for (final r in rows)
        r['key'] as String: r['value'] as String,
    };
  }

  /// Build the memory context string to inject into prompts
  static Future<String?> buildMemoryContext() async {
    final memory = await getAllMemory();
    if (memory.isEmpty) return null;

    return memory.entries
        .map((e) => '- ${e.key}: ${e.value}')
        .join('\n');
  }
}