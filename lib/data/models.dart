import 'dart:convert';

class User {
  final int id;
  final String nickname;
  final String email;

  const User({
    required this.id,
    required this.nickname,
    required this.email,
  });

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int,
      nickname: map['nickname'] as String,
      email: map['email'] as String,
    );
  }
}

class Task {
  final int id;
  final String title;
  final bool isDone;
  final bool isBurned;
  final DateTime createdAt;
  final String? note;
  final int? categoryId;
  final ReminderType? reminderType;
  final int? reminderMinutes;

  const Task({
    required this.id,
    required this.title,
    required this.isDone,
    required this.isBurned,
    required this.createdAt,
    this.note,
    this.categoryId,
    this.reminderType,
    this.reminderMinutes,
  });

  factory Task.fromMap(Map<String, Object?> map) {
    final reminderValue = map['reminder_type'] as String?;

    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      isDone: (map['is_done'] as int) == 1,
      isBurned: ((map['is_burned'] as int?) ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
      note: map['note'] as String?,
      categoryId: map['category_id'] as int?,
      reminderType: reminderTypeFromString(reminderValue),
      reminderMinutes: map['reminder_minutes'] as int?,
    );
  }

  Task copyWith({
    String? title,
    bool? isDone,
    bool? isBurned,
    DateTime? createdAt,
    String? note,
    int? categoryId,
    bool setCategory = false,
    ReminderType? reminderType,
    int? reminderMinutes,
    bool setReminder = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      isBurned: isBurned ?? this.isBurned,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      categoryId: setCategory ? categoryId : this.categoryId,
      reminderType: setReminder ? reminderType : this.reminderType,
      reminderMinutes: setReminder ? reminderMinutes : this.reminderMinutes,
    );
  }
}

String extractPlainNote(String? raw) {
  if (raw == null || raw.isEmpty) {
    return '';
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic> && decoded['text'] is String) {
      return decoded['text'] as String;
    }
  } catch (_) {
    // Keep raw as plain text.
  }
  return raw;
}

class TaskItem {
  final int id;
  final int taskId;
  final String text;
  final bool isDone;
  final int position;

  const TaskItem({
    required this.id,
    required this.taskId,
    required this.text,
    required this.isDone,
    required this.position,
  });

  factory TaskItem.fromMap(Map<String, Object?> map) {
    return TaskItem(
      id: map['id'] as int,
      taskId: map['task_id'] as int,
      text: map['text'] as String,
      isDone: (map['is_done'] as int) == 1,
      position: (map['position'] as int?) ?? 0,
    );
  }

  TaskItem copyWith({
    int? taskId,
    String? text,
    bool? isDone,
    int? position,
  }) {
    return TaskItem(
      id: id,
      taskId: taskId ?? this.taskId,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
    );
  }
}

class Category {
  final int id;
  final String name;
  final int color;

  const Category({
    required this.id,
    required this.name,
    required this.color,
  });
}

class CategoryStats {
  final Category category;
  final int taskCount;

  const CategoryStats({
    required this.category,
    required this.taskCount,
  });
}

enum ReminderType {
  once,
  daily,
  weekly,
  custom,
}

ReminderType? reminderTypeFromString(String? value) {
  if (value == null) {
    return null;
  }
  for (final type in ReminderType.values) {
    if (type.name == value) {
      return type;
    }
  }
  return null;
}

enum TaskFilter {
  all,
  active,
  completed,
}

class TargetOption {
  final String id;
  final String title;
  final String subtitle;
  final int tasks;
  final int intervals;

  const TargetOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.intervals,
  });
}

enum AuthFailure {
  emailExists,
  nicknameExists,
  invalidCredentials,
  wrongPassword,
  serverError,
}

class AuthResult {
  final User? user;
  final AuthFailure? failure;

  const AuthResult._({this.user, this.failure});

  factory AuthResult.success(User user) {
    return AuthResult._(user: user);
  }

  factory AuthResult.failure(AuthFailure failure) {
    return AuthResult._(failure: failure);
  }

  bool get isSuccess => user != null;
}
