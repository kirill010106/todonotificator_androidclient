import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class TaskDetailViewModel extends ChangeNotifier {
  TaskDetailViewModel(this._repository, this.taskId);

  final TaskRepository _repository;
  final int? taskId;

  Task? _task;
  List<TaskItem> _items = const [];
  List<CategoryStats> _categories = const [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;
  int _draftItemSeed = -1;
  bool _isDisposed = false;

  Timer? _titleTimer;
  Timer? _noteTimer;

  Task? get task => _task;
  List<TaskItem> get items => _items;
  List<CategoryStats> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isSaving => _isSaving;
  bool get isNew => taskId == null;

  Future<void> load() async {
    if (_isDisposed) return;
    _isLoading = true;
    _hasError = false;
    _safeNotify();

    try {
      if (isNew) {
        final categoriesResult = await _repository.fetchCategories();
        if (_isDisposed) return;
        _task = Task(
          id: 0,
          title: '',
          isDone: false,
          isBurned: false,
          isHardcore: false,
          createdAt: DateTime.now(),
          note: '',
        );
        _items = const [];
        _categories = categoriesResult;
      } else {
        final taskResult = await _repository.getTask(taskId!);
        if (_isDisposed) return;
        if (taskResult == null) {
          _hasError = true;
        } else {
          _task = taskResult;
          _items = await _repository.fetchTaskItems(taskResult.id);
          if (_isDisposed) return;
          _categories = await _repository.fetchCategories();
        }
      }
      if (_isDisposed) return;
      _isLoading = false;
    } catch (_) {
      if (_isDisposed) return;
      _isLoading = false;
      _hasError = true;
    }
    _safeNotify();
  }

  void updateTitle(String title) {
    if (_task == null || _isDisposed) return;
    _task = _task!.copyWith(title: title.trim());

    if (isNew) {
      _safeNotify();
      return;
    }

    _titleTimer?.cancel();
    _titleTimer = Timer(const Duration(milliseconds: 400), () async {
      if (_isDisposed) return;
      await _repository.updateTaskTitle(taskId!, title.trim());
    });
    _safeNotify();
  }

  void updateNote(String noteStorage) {
    if (_task == null || _isDisposed) return;
    _task = _task!.copyWith(note: noteStorage);

    if (isNew) {
      _safeNotify();
      return;
    }

    _noteTimer?.cancel();
    _noteTimer = Timer(const Duration(milliseconds: 400), () async {
      if (_isDisposed) return;
      await _repository.updateTaskNote(taskId!, noteStorage);
    });
    _safeNotify();
  }

  Future<void> resurrectTask() async {
    if (_task == null || _isDisposed) return;
    await _repository.resurrectTask(_task!.id);
    await load();
  }

  Future<void> toggleTaskDone(bool isDone) async {
    if (_task == null || _isDisposed) return;
    final nextBurned = isDone ? false : _task!.isBurned;
    _task = _task!.copyWith(isDone: isDone, isBurned: nextBurned);

    if (!isNew) {
      await _repository.setTaskDone(taskId!, isDone);
    }
    _safeNotify();
  }

  Future<void> addChecklistItem(String text) async {
    if (_task == null || text.trim().isEmpty || _isDisposed) return;
    final trimmedText = text.trim();

    if (isNew) {
      final item = TaskItem(
        id: _draftItemSeed--,
        taskId: 0,
        text: trimmedText,
        isDone: false,
        position: _items.length,
      );
      _items = [..._items, item];
    } else {
      final item = await _repository.addTaskItem(
        taskId: _task!.id,
        text: trimmedText,
      );
      if (_isDisposed) return;
      _items = [..._items, item];
    }
    _safeNotify();
  }

  Future<void> toggleItem(TaskItem item, bool isDone) async {
    if (_isDisposed) return;
    if (isNew) {
      _items = _items
          .map(
            (current) => current.id == item.id
                ? current.copyWith(isDone: isDone)
                : current,
          )
          .toList();
    } else {
      await _repository.setTaskItemDone(item.id, isDone);
      if (_isDisposed) return;
      _items = _items
          .map(
            (current) => current.id == item.id
                ? current.copyWith(isDone: isDone)
                : current,
          )
          .toList();
    }
    _safeNotify();
  }

  Future<void> deleteItem(TaskItem item) async {
    if (_isDisposed) return;
    if (isNew) {
      _items = _items.where((current) => current.id != item.id).toList();
    } else {
      await _repository.deleteTaskItem(item.id);
      if (_isDisposed) return;
      _items = _items.where((current) => current.id != item.id).toList();
    }
    _safeNotify();
  }

  Future<void> setCategory(int? categoryId) async {
    if (_task == null || _isDisposed) return;
    _task = _task!.copyWith(setCategory: true, categoryId: categoryId);

    if (!isNew) {
      await _repository.setTaskCategory(taskId!, categoryId);
      if (_isDisposed) return;
      _categories = await _repository.fetchCategories();
    }
    _safeNotify();
  }

  Future<Category> addCategory(String name, int color) async {
    final created = await _repository.addCategory(name: name, color: color);
    await setCategory(created.id);
    return created;
  }

  Future<void> setReminder(ReminderType? type, int? minutes) async {
    if (_task == null || _isDisposed) return;
    _task = _task!.copyWith(
      setReminder: true,
      reminderType: type,
      reminderMinutes: minutes,
    );

    if (!isNew) {
      await _repository.setTaskReminder(taskId!, type, minutes);
    }
    _safeNotify();
  }

  Future<void> deleteTask() async {
    if (!isNew && !_isDisposed) {
      await _repository.deleteTask(taskId!);
    }
  }

  /// Cancels any pending autosave timers and performs an immediate save of all fields.
  /// Uses [saveTaskFull] to ensure the operation is atomic.
  Future<void> save() async {
    if (_task == null || _isDisposed) return;
    
    _titleTimer?.cancel();
    _noteTimer?.cancel();

    _isSaving = true;
    _safeNotify();

    try {
      await _repository.saveTaskFull(
        id: isNew ? null : taskId,
        title: _task!.title,
        note: _task!.note,
        categoryId: _task!.categoryId,
        reminderType: _task!.reminderType,
        reminderMinutes: _task!.reminderMinutes,
        isDone: _task!.isDone,
        isBurned: _task!.isBurned,
        isHardcore: _task!.isHardcore,
        items: _items,
      );
    } finally {
      if (!_isDisposed) {
        _isSaving = false;
        _safeNotify();
      }
    }
  }

  Future<int?> saveDraft() async {
    if (!isNew || _task == null || _isDisposed) return null;

    final notePlain = extractPlainNote(_task!.note).trim();
    final titleInput = _task!.title.trim();

    if (titleInput.isEmpty && notePlain.isEmpty && _items.isEmpty) {
      return null;
    }

    _isSaving = true;
    _safeNotify();

    try {
      // If title is empty but content exists, generate a numbered "Без названия" title.
      String title = titleInput;
      if (title.isEmpty) {
        const base = 'Без названия';
        final existing = await _repository.fetchTasks(query: base);
        if (_isDisposed) return null;
        var maxNum = 0;
        final re = RegExp(r'^Без названия(?:\s(\d+))?$');
        for (final t in existing) {
          final m = re.firstMatch(t.title);
          if (m != null) {
            final g = m.group(1);
            if (g == null) {
              maxNum = max(maxNum, 1);
            } else {
              final n = int.tryParse(g) ?? 0;
              maxNum = max(maxNum, n);
            }
          }
        }
        if (maxNum == 0) {
          title = base;
        } else {
          title = '$base ${maxNum + 1}';
        }
      }

      final createdId = await _repository.saveTaskFull(
        title: title,
        note: _task!.note,
        categoryId: _task!.categoryId,
        reminderType: _task!.reminderType,
        reminderMinutes: _task!.reminderMinutes,
        isDone: _task!.isDone,
        isBurned: _task!.isBurned,
        isHardcore: _task!.isHardcore,
        items: _items,
      );
      
      return createdId;
    } finally {
      if (!_isDisposed) {
        _isSaving = false;
        _safeNotify();
      }
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _titleTimer?.cancel();
    _noteTimer?.cancel();
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
