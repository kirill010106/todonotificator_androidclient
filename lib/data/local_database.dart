import 'dart:convert';
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
      version: 7,
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
          'is_hardcore INTEGER NOT NULL DEFAULT 0, '
          'created_at INTEGER NOT NULL, '
          'xp_awarded INTEGER NOT NULL DEFAULT 0'
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
          'position INTEGER NOT NULL DEFAULT 0, '
          'xp_awarded INTEGER NOT NULL DEFAULT 0'
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
        await db.execute(
          'CREATE TABLE daily_stats ('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'user_id INTEGER NOT NULL, '
          'date TEXT NOT NULL, '
          'pomodoros INTEGER NOT NULL DEFAULT 0, '
          'focus_seconds INTEGER NOT NULL DEFAULT 0, '
          'UNIQUE(user_id, date)'
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
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN is_hardcore INTEGER '
            'NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN xp_awarded INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE task_items ADD COLUMN xp_awarded INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 7) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS daily_stats ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'user_id INTEGER NOT NULL, '
            'date TEXT NOT NULL, '
            'pomodoros INTEGER NOT NULL DEFAULT 0, '
            'focus_seconds INTEGER NOT NULL DEFAULT 0, '
            'UNIQUE(user_id, date)'
            ')',
          );
        }
      },
    );
  }

  /// Exports all data (except users and session settings) to a JSON string.
  Future<String> exportData() async {
    final db = await database;
    final Map<String, dynamic> export = {};

    const tables = [
      'tasks',
      'categories',
      'task_items',
      'user_xp',
      'achievements',
      'settings',
    ];

    for (final table in tables) {
      final rows = await db.query(table);
      // For settings, we might want to exclude current_user_id to avoid login state confusion on import
      if (table == 'settings') {
        export[table] = rows.where((r) => r['key'] != 'current_user_id').toList();
      } else {
        export[table] = rows;
      }
    }

    return jsonEncode(export);
  }

  /// Wipes current data and imports from a JSON string.
  /// Uses a transaction to ensure atomicity.
  Future<void> importData(String jsonString) async {
    final db = await database;
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await db.transaction((txn) async {
      // 1. Wipe existing data
      await txn.delete('tasks');
      await txn.delete('categories');
      await txn.delete('task_items');
      await txn.delete('user_xp');
      await txn.delete('achievements');
      // We don't wipe 'settings' completely to keep current user ID, 
      // but we will update other keys if present.

      // 2. Insert new data
      for (final entry in data.entries) {
        final table = entry.key;
        final rows = entry.value as List;

        for (final row in rows) {
          final rowMap = Map<String, dynamic>.from(row as Map);
          if (table == 'settings') {
            await txn.insert(
              table,
              rowMap,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            await txn.insert(table, rowMap);
          }
        }
      }
    });
  }
}
