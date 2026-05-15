import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    final path = p.join(root, 'pomodoro_todo.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE users ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'nickname TEXT NOT NULL UNIQUE, '
          'email TEXT NOT NULL UNIQUE, '
          'password TEXT NOT NULL'
          ')',
        );
        await db.execute(
          'CREATE TABLE tasks ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'user_id INTEGER, '
          'title TEXT NOT NULL, '
          'note TEXT, '
          'category_id INTEGER, '
          'reminder_type TEXT, '
          'reminder_minutes INTEGER, '
          'is_done INTEGER NOT NULL DEFAULT 0, '
          'is_burned INTEGER NOT NULL DEFAULT 0, '
          'created_at INTEGER NOT NULL'
          ')',
        );
        await db.execute(
          'CREATE TABLE categories ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'user_id INTEGER, '
          'name TEXT NOT NULL, '
          'color INTEGER NOT NULL'
          ')',
        );
        await db.execute(
          'CREATE TABLE task_items ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'task_id INTEGER NOT NULL, '
          'text TEXT NOT NULL, '
          'is_done INTEGER NOT NULL DEFAULT 0, '
          'position INTEGER NOT NULL DEFAULT 0'
          ')',
        );
        await db.execute(
          'CREATE TABLE settings ('
          'key TEXT PRIMARY KEY, '
          'value TEXT'
          ')',
        );
        await db.execute(
          'CREATE TABLE user_xp ('
          'user_id INTEGER PRIMARY KEY, '
          'total_xp INTEGER NOT NULL DEFAULT 0, '
          'streak_days INTEGER NOT NULL DEFAULT 0, '
          'last_active_date TEXT'
          ')',
        );
        await db.execute(
          'CREATE TABLE achievements ('
          'id TEXT NOT NULL, '
          'user_id INTEGER NOT NULL, '
          'unlocked_at INTEGER NOT NULL, '
          'PRIMARY KEY (id, user_id)'
          ')',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN note TEXT');
          await db.execute('ALTER TABLE tasks ADD COLUMN category_id INTEGER');
          await db.execute('ALTER TABLE tasks ADD COLUMN reminder_type TEXT');
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN reminder_minutes INTEGER',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS categories ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'user_id INTEGER, '
            'name TEXT NOT NULL, '
            'color INTEGER NOT NULL'
            ')',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS task_items ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'task_id INTEGER NOT NULL, '
            'text TEXT NOT NULL, '
            'is_done INTEGER NOT NULL DEFAULT 0, '
            'position INTEGER NOT NULL DEFAULT 0'
            ')',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN is_burned INTEGER '
            'NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS user_xp ('
            'user_id INTEGER PRIMARY KEY, '
            'total_xp INTEGER NOT NULL DEFAULT 0, '
            'streak_days INTEGER NOT NULL DEFAULT 0, '
            'last_active_date TEXT'
            ')',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS achievements ('
            'id TEXT NOT NULL, '
            'user_id INTEGER NOT NULL, '
            'unlocked_at INTEGER NOT NULL, '
            'PRIMARY KEY (id, user_id)'
            ')',
          );
        }
      },
    );
  }
}
