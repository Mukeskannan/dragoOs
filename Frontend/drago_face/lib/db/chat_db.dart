import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message_model.dart';

class ChatDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'drago_chat.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT,
            isUser INTEGER,
            time TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertMessage(MessageModel msg) async {
    final db = await database;

    await db.insert('messages', {
      'text': msg.text,
      'isUser': msg.isUser ? 1 : 0,
      'time': msg.time.toIso8601String(),
    });
  }

  static Future<List<MessageModel>> getMessages() async {
    final db = await database;

    final result = await db.query('messages', orderBy: 'id ASC');

    return result.map((e) {
      return MessageModel(
        text: e['text'] as String,
        isUser: (e['isUser'] as int) == 1,
        time: DateTime.parse(e['time'] as String),
      );
    }).toList();
  }
}