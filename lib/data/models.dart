import 'dart:convert';

class User {
  final int id;
  final String nickname;
  final String email;

  const User({required this.id, required this.nickname, required this.email});

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
  final bool isHardcore;
  final DateTime createdAt;
  final String? note;
  final int? categoryId;
  final ReminderType? reminderType;
  final int? reminderMinutes;
  final bool xpAwarded;

  const Task({
    required this.id,
    required this.title,
    required this.isDone,
    required this.isBurned,
    required this.isHardcore,
    required this.createdAt,
    this.note,
    this.categoryId,
    this.reminderType,
    this.reminderMinutes,
    this.xpAwarded = false,
  });

  factory Task.fromMap(Map<String, Object?> map) {
    final reminderValue = map['reminder_type'] as String?;

    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      isDone: (map['is_done'] as int) == 1,
      isBurned: ((map['is_burned'] as int?) ?? 0) == 1,
      isHardcore: ((map['is_hardcore'] as int?) ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      note: map['note'] as String?,
      categoryId: map['category_id'] as int?,
      reminderType: reminderTypeFromString(reminderValue),
      reminderMinutes: map['reminder_minutes'] as int?,
      xpAwarded: (map['xp_awarded'] as int? ?? 0) == 1,
    );
  }

  Task copyWith({
    String? title,
    bool? isDone,
    bool? isBurned,
    bool? isHardcore,
    DateTime? createdAt,
    String? note,
    int? categoryId,
    bool setCategory = false,
    ReminderType? reminderType,
    int? reminderMinutes,
    bool setReminder = false,
    bool? xpAwarded,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      isBurned: isBurned ?? this.isBurned,
      isHardcore: isHardcore ?? this.isHardcore,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      categoryId: setCategory ? categoryId : this.categoryId,
      reminderType: setReminder ? reminderType : this.reminderType,
      reminderMinutes: setReminder ? reminderMinutes : this.reminderMinutes,
      xpAwarded: xpAwarded ?? this.xpAwarded,
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
  final bool xpAwarded;

  const TaskItem({
    required this.id,
    required this.taskId,
    required this.text,
    required this.isDone,
    required this.position,
    this.xpAwarded = false,
  });

  factory TaskItem.fromMap(Map<String, Object?> map) {
    return TaskItem(
      id: map['id'] as int,
      taskId: map['task_id'] as int,
      text: map['text'] as String,
      isDone: (map['is_done'] as int) == 1,
      position: (map['position'] as int?) ?? 0,
      xpAwarded: (map['xp_awarded'] as int? ?? 0) == 1,
    );
  }

  TaskItem copyWith({
    int? taskId,
    String? text,
    bool? isDone,
    int? position,
    bool? xpAwarded,
  }) {
    return TaskItem(
      id: id,
      taskId: taskId ?? this.taskId,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
      xpAwarded: xpAwarded ?? this.xpAwarded,
    );
  }
}

class Category {
  final int id;
  final String name;
  final int color;

  const Category({required this.id, required this.name, required this.color});
}

class CategoryStats {
  final Category category;
  final int taskCount;

  const CategoryStats({required this.category, required this.taskCount});
}

enum ReminderType { once, daily, weekly, custom }

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

enum TaskFilter { all, active, completed, burned }

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

// ---------------------------------------------------------------------------
// Gamification
// ---------------------------------------------------------------------------

enum XpEvent {
  pomodoroComplete(10),
  taskComplete(25),
  taskAdded(2),
  taskBurned(-5),
  taskItemDone(5),
  streakBonus(15),
  achievementUnlock(0); // reward stored in Achievement itself

  const XpEvent(this.xpDelta);
  final int xpDelta;
}

class UserProgress {
  final int totalXp;
  final int level;
  final int xpInCurrentLevel;
  final int xpForNextLevel;
  final int streakDays;

  const UserProgress({
    required this.totalXp,
    required this.level,
    required this.xpInCurrentLevel,
    required this.xpForNextLevel,
    required this.streakDays,
  });

  double get progressFraction =>
      xpForNextLevel == 0 ? 1.0 : xpInCurrentLevel / xpForNextLevel;

  /// Derives level/progress from a flat [totalXp] value.
  static UserProgress fromTotalXp(int totalXp, {int streakDays = 0}) {
    int remaining = totalXp;
    int level = 1;
    while (true) {
      final needed = 100 * level * level;
      if (remaining < needed) break;
      remaining -= needed;
      level++;
    }
    final xpForNext = 100 * level * level;
    return UserProgress(
      totalXp: totalXp,
      level: level,
      xpInCurrentLevel: remaining,
      xpForNextLevel: xpForNext,
      streakDays: streakDays,
    );
  }

  UserProgress copyWith({
    int? totalXp,
    int? streakDays,
  }) {
    final base = totalXp ?? this.totalXp;
    final derived = UserProgress.fromTotalXp(base, streakDays: streakDays ?? this.streakDays);
    return derived;
  }
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

class DailyStats {
  final int userId;
  final String date; // YYYY-MM-DD
  final int pomodoros;
  final int focusSeconds;

  const DailyStats({
    required this.userId,
    required this.date,
    required this.pomodoros,
    required this.focusSeconds,
  });

  factory DailyStats.fromMap(Map<String, Object?> map) {
    return DailyStats(
      userId: map['user_id'] as int,
      date: map['date'] as String,
      pomodoros: map['pomodoros'] as int,
      focusSeconds: map['focus_seconds'] as int,
    );
  }

  DailyStats copyWith({
    int? pomodoros,
    int? focusSeconds,
  }) {
    return DailyStats(
      userId: userId,
      date: date,
      pomodoros: pomodoros ?? this.pomodoros,
      focusSeconds: focusSeconds ?? this.focusSeconds,
    );
  }
}

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji
  final int xpReward;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
  });
}

class Achievement {
  final AchievementDefinition definition;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.definition,
    required this.isUnlocked,
    this.unlockedAt,
  });

  String get id => definition.id;
  String get title => definition.title;
  String get description => definition.description;
  String get icon => definition.icon;
  int get xpReward => definition.xpReward;
}
