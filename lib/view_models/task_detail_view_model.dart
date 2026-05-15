import 'dart:async';
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
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      if (isNew) {
        final categoriesResult = await _repository.fetchCategories();
        _task = Task(
          id: 0,
          title: '',
          isDone: false,
          isBurned: false,
          createdAt: DateTime.now(),
          note: '',
        );
        _items = const [];
        _categories = categoriesResult;
      } else {
        final taskResult = await _repository.getTask(taskId!);
        if (taskResult == null) {
          _hasError = true;
        } else {
          _task = taskResult;
          _items = await _repository.fetchTaskItems(taskResult.id);
          _categories = await _repository.fetchCategories();
        }
      }
      _isLoading = false;
    } catch (_) {
      _isLoading = false;
      _hasError = true;
    }
    notifyListeners();
  }

  void updateTitle(String title) {
    if (_task == null) return;
    _task = _task!.copyWith(title: title.trim());

    if (isNew) {
      notifyListeners();
      return;
    }

    _titleTimer?.cancel();
    _titleTimer = Timer(const Duration(milliseconds: 400), () async {
      await _repository.updateTaskTitle(taskId!, title.trim());
    });
    notifyListeners();
  }

  void updateNote(String noteStorage) {
    if (_task == null) return;
    _task = _task!.copyWith(note: noteStorage);

    if (isNew) {
      notifyListeners();
      return;
    }

    _noteTimer?.cancel();
    _noteTimer = Timer(const Duration(milliseconds: 400), () async {
      await _repository.updateTaskNote(taskId!, noteStorage);
    });
    notifyListeners();
  }

  Future<void> toggleTaskDone(bool isDone) async {
    if (_task == null) return;
    final nextBurned = isDone ? false : _task!.isBurned;
    _task = _task!.copyWith(isDone: isDone, isBurned: nextBurned);

    if (!isNew) {
      await _repository.setTaskDone(taskId!, isDone);
    }
    notifyListeners();
  }

  Future<void> addChecklistItem(String text) async {
    if (_task == null || text.trim().isEmpty) return;
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
      _items = [..._items, item];
    }
    notifyListeners();
  }

  Future<void> toggleItem(TaskItem item, bool isDone) async {
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
      _items = _items
          .map(
            (current) => current.id == item.id
                ? current.copyWith(isDone: isDone)
                : current,
          )
          .toList();
    }
    notifyListeners();
  }

  Future<void> deleteItem(TaskItem item) async {
    if (isNew) {
      _items = _items.where((current) => current.id != item.id).toList();
    } else {
      await _repository.deleteTaskItem(item.id);
      _items = _items.where((current) => current.id != item.id).toList();
    }
    notifyListeners();
  }

  Future<void> setCategory(int? categoryId) async {
    if (_task == null) return;
    _task = _task!.copyWith(setCategory: true, categoryId: categoryId);

    if (!isNew) {
      await _repository.setTaskCategory(taskId!, categoryId);
      _categories = await _repository.fetchCategories();
    }
    notifyListeners();
  }

  Future<Category> addCategory(String name, int color) async {
    final created = await _repository.addCategory(name: name, color: color);
    await setCategory(created.id);
    return created;
  }

  Future<void> setReminder(ReminderType? type, int? minutes) async {
    if (_task == null) return;
    _task = _task!.copyWith(
      setReminder: true,
      reminderType: type,
      reminderMinutes: minutes,
    );

    if (!isNew) {
      await _repository.setTaskReminder(taskId!, type, minutes);
    }
    notifyListeners();
  }

  Future<void> deleteTask() async {
    if (!isNew) {
      await _repository.deleteTask(taskId!);
    }
  }

  Future<int?> saveDraft() async {
    if (!isNew || _task == null) return null;

    _isSaving = true;
    notifyListeners();

    try {
      final created = await _repository.addTask(title: _task!.title);
      if (_task!.note != null && _task!.note!.isNotEmpty) {
        await _repository.updateTaskNote(created.id, _task!.note!);
      }
      if (_task!.categoryId != null) {
        await _repository.setTaskCategory(created.id, _task!.categoryId);
      }
      if (_task!.reminderType != null) {
        await _repository.setTaskReminder(
          created.id,
          _task!.reminderType,
          _task!.reminderMinutes,
        );
      }
      if (_task!.isDone) {
        await _repository.setTaskDone(created.id, true);
      }

      for (final item in _items) {
        final createdItem = await _repository.addTaskItem(
          taskId: created.id,
          text: item.text,
        );
        if (item.isDone) {
          await _repository.setTaskItemDone(createdItem.id, true);
        }
      }
      return created.id;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _titleTimer?.cancel();
    _noteTimer?.cancel();
    super.dispose();
  }
}
