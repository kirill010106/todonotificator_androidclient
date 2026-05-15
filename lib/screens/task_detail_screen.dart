import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../ui/theme/app_colors.dart';
import '../ui/widgets/rich_note_controller.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, this.taskId});

  final int? taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

enum _NoteScreenMode { view, actions, editing }

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _noteController = RichNoteController();
  final _itemController = TextEditingController();

  Timer? _titleTimer;
  Timer? _noteTimer;

  Task? _task;
  List<TaskItem> _items = const [];
  List<CategoryStats> _categories = const [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _didLoad = false;
  bool _seededControllers = false;
  bool _isSaving = false;
  int _draftItemSeed = -1;
  _NoteScreenMode _mode = _NoteScreenMode.view;

  bool get _isNew => widget.taskId == null;
  bool get _isEditing => _isNew || _mode == _NoteScreenMode.editing;

  late final AnimationController _menuController;
  late final Animation<double> _menuAnimation;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _load();
    }
  }

  void _enterEditingMode() {
    if (_isNew) {
      return;
    }
    setState(() {
      _mode = _NoteScreenMode.editing;
    });
  }

  void _openActionsMenu() {
    if (_isNew) {
      _enterEditingMode();
      return;
    }
    setState(() {
      _mode = _NoteScreenMode.actions;
    });
    _menuController.forward(from: 0.0);
  }

  Future<void> _leaveEditingMode() async {
    if (_isNew) {
      await _handleBack();
      return;
    }
    await _persistExistingEdits();
    if (!mounted) {
      return;
    }
    setState(() {
      _mode = _NoteScreenMode.view;
    });
  }

  void _closeActionsMenu() {
    if (_isNew) {
      return;
    }
    _menuController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _mode = _NoteScreenMode.view;
        });
      }
    });
  }

  @override
  void dispose() {
    _menuController.dispose();
    _titleTimer?.cancel();
    _noteTimer?.cancel();
    _titleController.dispose();
    _noteController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (_isNew) {
      try {
        final categories = await AppScope.of(context).tasks.fetchCategories();
        if (!mounted) {
          return;
        }
        final draft = Task(
          id: 0,
          title: '',
          isDone: false,
          isBurned: false,
          createdAt: DateTime.now(),
          note: '',
          categoryId: null,
          reminderType: null,
          reminderMinutes: null,
        );
        setState(() {
          _task = draft;
          _items = const [];
          _categories = categories;
          _isLoading = false;
          _mode = _NoteScreenMode.editing;
        });
        if (!_seededControllers) {
          _seededControllers = true;
          _titleController.text = '';
          _noteController.loadFromStorage('');
        }
        return;
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }
    }

    try {
      final repo = AppScope.of(context).tasks;
      final task = await repo.getTask(widget.taskId!);
      if (task == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final items = await repo.fetchTaskItems(task.id);
      final categories = await repo.fetchCategories();

      if (!mounted) {
        return;
      }

      setState(() {
        _task = task;
        _items = items;
        _categories = categories;
        _isLoading = false;
        _mode = _NoteScreenMode.view;
      });

      if (!_seededControllers) {
        _seededControllers = true;
        _titleController.text = task.title;
        _noteController.loadFromStorage(task.note);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _onTitleChanged(String value) {
    _titleTimer?.cancel();
    _titleTimer = Timer(const Duration(milliseconds: 400), () async {
      final task = _task;
      if (task == null) {
        return;
      }
      if (_isNew) {
        if (!mounted) {
          return;
        }
        setState(() {
          _task = _copyTask(task, title: value.trim());
        });
        return;
      }

      await AppScope.of(context).tasks.updateTaskTitle(task.id, value.trim());
      if (!mounted) {
        return;
      }
      setState(() {
        _task = _copyTask(task, title: value.trim());
      });
    });
  }

  void _onNoteChanged(String value) {
    _noteTimer?.cancel();
    _noteTimer = Timer(const Duration(milliseconds: 400), () async {
      final task = _task;
      if (task == null) {
        return;
      }
      final storage = _noteController.toStorage();
      if (_isNew) {
        if (!mounted) {
          return;
        }
        setState(() {
          _task = _copyTask(task, note: storage);
        });
        return;
      }

      await AppScope.of(context).tasks.updateTaskNote(task.id, storage);
      if (!mounted) {
        return;
      }
      setState(() {
        _task = _copyTask(task, note: storage);
      });
    });
  }

  Future<void> _toggleTaskDone(bool value) async {
    final task = _task;
    if (task == null) {
      return;
    }
    final nextBurned = value ? false : task.isBurned;
    if (_isNew) {
      setState(() {
        _task = _copyTask(task, isDone: value, isBurned: nextBurned);
      });
      return;
    }

    await AppScope.of(context).tasks.setTaskDone(task.id, value);
    if (!mounted) {
      return;
    }
    setState(() {
      _task = _copyTask(task, isDone: value, isBurned: nextBurned);
    });
  }

  Future<void> _addChecklistItem() async {
    final text = _itemController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final task = _task;
    if (task == null) {
      return;
    }

    if (_isNew) {
      final item = TaskItem(
        id: _draftItemSeed--,
        taskId: 0,
        text: text,
        isDone: false,
        position: _items.length,
      );
      setState(() {
        _items = [..._items, item];
      });
      _itemController.clear();
      return;
    }

    final item = await AppScope.of(
      context,
    ).tasks.addTaskItem(taskId: task.id, text: text);

    if (!mounted) {
      return;
    }

    setState(() {
      _items = [..._items, item];
    });
    _itemController.clear();
  }

  Future<void> _toggleItem(TaskItem item, bool value) async {
    if (_isNew) {
      setState(() {
        _items = _items
            .map(
              (current) => current.id == item.id
                  ? TaskItem(
                      id: current.id,
                      taskId: current.taskId,
                      text: current.text,
                      isDone: value,
                      position: current.position,
                    )
                  : current,
            )
            .toList();
      });
      return;
    }

    await AppScope.of(context).tasks.setTaskItemDone(item.id, value);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = _items
          .map(
            (current) => current.id == item.id
                ? TaskItem(
                    id: current.id,
                    taskId: current.taskId,
                    text: current.text,
                    isDone: value,
                    position: current.position,
                  )
                : current,
          )
          .toList();
    });
  }

  Future<void> _deleteItem(TaskItem item) async {
    if (_isNew) {
      setState(() {
        _items = _items.where((current) => current.id != item.id).toList();
      });
      return;
    }

    await AppScope.of(context).tasks.deleteTaskItem(item.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = _items.where((current) => current.id != item.id).toList();
    });
  }

  Future<void> _confirmDeleteTask() async {
    final task = _task;
    if (task == null) {
      return;
    }
    final repo = AppScope.of(context).tasks;
    final navigator = Navigator.of(context);
    if (_isNew) {
      navigator.pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить заметку?'),
          content: const Text('Это действие нельзя отменить.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await repo.deleteTask(task.id);
    if (!mounted) {
      return;
    }
    navigator.pop();
  }

  Future<void> _openCategorySheet() async {
    final task = _task;
    if (task == null) {
      return;
    }

    final categories = await AppScope.of(context).tasks.fetchCategories();
    if (!mounted) {
      return;
    }

    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final nameController = TextEditingController();
        int selectedColor = _palette.first;
        int? currentSelection = task.categoryId;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Выбор категории',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Новая категория',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Название',
                      filled: true,
                      fillColor: const Color(0xFFF3F5F4),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _palette
                        .map(
                          (color) => GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color
                                      ? Colors.black87
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        return;
                      }
                      Navigator.of(context).pop(
                        _CategoryCreateRequest(
                          name: nameController.text.trim(),
                          color: selectedColor,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('+ Добавить'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Существующие',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _CategoryTile(
                    title: 'Без категории',
                    color: AppColors.mutedText,
                    count: null,
                    selected: currentSelection == null,
                    onTap: () {
                      setSheetState(() {
                        currentSelection = null;
                      });
                      Navigator.of(context).pop(const _CategoryClearRequest());
                    },
                  ),
                  const SizedBox(height: 8),
                  for (final entry in categories)
                    _CategoryTile(
                      title: entry.category.name,
                      color: Color(entry.category.color),
                      count: entry.taskCount,
                      selected: currentSelection == entry.category.id,
                      onTap: () {
                        setSheetState(() {
                          currentSelection = entry.category.id;
                        });
                        Navigator.of(context).pop(entry.category.id);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    final repo = AppScope.of(context).tasks;

    if (result is _CategoryCreateRequest) {
      final created = await repo.addCategory(
        name: result.name,
        color: result.color,
      );
      final updatedCategories = await repo.fetchCategories();
      if (!mounted) {
        return;
      }
      if (_isNew) {
        setState(() {
          _categories = updatedCategories;
          _task = _copyTask(task, setCategory: true, categoryId: created.id);
        });
        return;
      }
      await repo.setTaskCategory(task.id, created.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = updatedCategories;
        _task = _copyTask(task, setCategory: true, categoryId: created.id);
      });
      return;
    }

    final selectedId = result is _CategoryClearRequest ? null : result as int?;
    if (_isNew) {
      setState(() {
        _task = _copyTask(task, setCategory: true, categoryId: selectedId);
      });
      return;
    }

    await repo.setTaskCategory(task.id, selectedId);
    final updatedCategories = await repo.fetchCategories();
    if (!mounted) {
      return;
    }
    setState(() {
      _categories = updatedCategories;
      _task = _copyTask(task, setCategory: true, categoryId: selectedId);
    });
  }

  Future<void> _openReminderSheet() async {
    final task = _task;
    if (task == null) {
      return;
    }

    final selection = await showModalBottomSheet<_ReminderSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        ReminderType? selectedType = task.reminderType;
        int selectedMinutes = task.reminderMinutes ?? 9 * 60;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Добавить напоминание',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Частота',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ReminderOption(
                    title: 'Один раз',
                    value: ReminderType.once,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setSheetState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  _ReminderOption(
                    title: 'Каждый день',
                    value: ReminderType.daily,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setSheetState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  _ReminderOption(
                    title: 'Каждую неделю',
                    value: ReminderType.weekly,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setSheetState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  _ReminderOption(
                    title: 'Настроить...',
                    value: ReminderType.custom,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setSheetState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Время',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: selectedMinutes ~/ 60,
                          minute: selectedMinutes % 60,
                        ),
                      );
                      if (time == null) {
                        return;
                      }
                      setSheetState(() {
                        selectedMinutes = time.hour * 60 + time.minute;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      side: const BorderSide(color: Color(0xFFCDD5CF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 8),
                        Text(_formatMinutes(selectedMinutes)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        const _ReminderSelection(type: null, minutes: null),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mutedText,
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: Color(0xFFCDD5CF)),
                    ),
                    child: const Text('Без напоминания'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        _ReminderSelection(
                          type: selectedType,
                          minutes: selectedType == null
                              ? null
                              : selectedMinutes,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Готово'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    if (_isNew) {
      setState(() {
        _task = _copyTask(
          task,
          setReminder: true,
          reminderType: selection.type,
          reminderMinutes: selection.minutes,
        );
      });
      return;
    }

    await AppScope.of(
      context,
    ).tasks.setTaskReminder(task.id, selection.type, selection.minutes);

    if (!mounted) {
      return;
    }

    setState(() {
      _task = _copyTask(
        task,
        setReminder: true,
        reminderType: selection.type,
        reminderMinutes: selection.minutes,
      );
    });
  }

  Future<void> _startTimerFromNote() async {
    if (_isSaving) {
      return;
    }
    final current = _task;
    if (current == null) {
      return;
    }
    if (current.isDone) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Задача уже выполнена.')));
      }
      return;
    }

    Task? task = current;
    if (_isNew) {
      final created = await _createTaskIfNeeded();
      if (created == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите название заметки.')),
        );
        return;
      }
      task = created;
    } else {
      await _persistExistingEdits();
    }

    if (!mounted) {
      return;
    }
    if (task.isDone) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Задача уже выполнена.')));
      }
      return;
    }

    final services = AppScope.of(context);
    services.timer.startForTask(task.id);
    services.navigation.setTab(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleBack() async {
    if (_isSaving) {
      return;
    }
    _isSaving = true;

    try {
      if (_isNew) {
        await _createTaskIfNeeded();
      } else {
        await _persistExistingEdits();
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        _isSaving = false;
      }
    }
  }

  Future<void> _persistExistingEdits() async {
    _titleTimer?.cancel();
    _noteTimer?.cancel();

    final task = _task;
    if (task == null) {
      return;
    }

    final repo = AppScope.of(context).tasks;
    await repo.updateTaskTitle(task.id, _titleController.text.trim());
    await repo.updateTaskNote(task.id, _noteController.toStorage());
  }

  Future<Task?> _createTaskIfNeeded() async {
    _titleTimer?.cancel();
    _noteTimer?.cancel();
    final titleInput = _titleController.text.trim();
    final noteStorage = _noteController.toStorage();
    final notePlain = _noteController.toPlainText().trim();

    // If neither title nor note provided, do nothing.
    if (titleInput.isEmpty && notePlain.isEmpty) {
      return null;
    }

    final repo = AppScope.of(context).tasks;

    // If title is empty but note exists, generate a numbered "Без названия" title.
    String title = titleInput;
    if (title.isEmpty && notePlain.isNotEmpty) {
      const base = 'Без названия';
      final existing = await repo.fetchTasks(query: base);
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

    final created = await repo.addTask(title: title);

    if (notePlain.isNotEmpty) {
      await repo.updateTaskNote(created.id, noteStorage);
    }

    final task = _task;
    if (task != null) {
      if (task.isDone) {
        await repo.setTaskDone(created.id, true);
      }
      if (task.isBurned) {
        await repo.setTaskBurned(created.id, true);
      }
      if (task.categoryId != null) {
        await repo.setTaskCategory(created.id, task.categoryId);
      }
      if (task.reminderType != null) {
        await repo.setTaskReminder(
          created.id,
          task.reminderType,
          task.reminderMinutes,
        );
      }
    }

    for (final item in _items) {
      final text = item.text.trim();
      if (text.isEmpty) {
        continue;
      }
      final createdItem = await repo.addTaskItem(
        taskId: created.id,
        text: text,
      );
      if (item.isDone) {
        await repo.setTaskItemDone(createdItem.id, true);
      }
    }

    if (mounted) {
      setState(() {
        _task = _copyTask(
          created,
          note: noteStorage,
          isDone: _task?.isDone,
          isBurned: _task?.isBurned,
          setCategory: true,
          categoryId: _task?.categoryId,
          setReminder: true,
          reminderType: _task?.reminderType,
          reminderMinutes: _task?.reminderMinutes,
        );
      });
    }
    return created;
  }

  void _wrapSelection(String prefix, String suffix, {int? cursorOffset}) {
    final controller = _noteController;
    final selection = controller.selection;
    if (!selection.isValid) {
      return;
    }
    final text = controller.text;
    final start = selection.start;
    final end = selection.end;
    final selected = start >= 0 && end >= 0 && end > start
        ? text.substring(start, end)
        : '';
    final replacement = '$prefix$selected$suffix';
    final newText = text.replaceRange(start, end, replacement);
    final cursor = start + (cursorOffset ?? prefix.length);

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selected.isEmpty ? cursor : start + replacement.length,
      ),
    );
    _onNoteChanged(controller.text);
  }

  void _insertLinePrefix(String prefix) {
    final controller = _noteController;
    final selection = controller.selection;
    if (!selection.isValid) {
      return;
    }
    final text = controller.text;
    final start = selection.start;
    final end = selection.end;

    final lineStart = text.lastIndexOf('\n', start <= 0 ? 0 : start - 1) + 1;
    final lineEndIndex = text.indexOf('\n', end);
    final lineEnd = lineEndIndex == -1 ? text.length : lineEndIndex;

    final block = text.substring(lineStart, lineEnd);
    final lines = block.split('\n');
    final newBlock = lines.map((line) => '$prefix$line').join('\n');

    final newText = text.replaceRange(lineStart, lineEnd, newBlock);
    final delta = newBlock.length - block.length;
    final newCursor = (selection.isCollapsed ? start : end) + delta;

    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    _onNoteChanged(controller.text);
  }

  void _insertLink() {
    _noteController.addLink('https://');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = _task?.isDone ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAF7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text('Заметка'),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: _confirmDeleteTask,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 8),
          child: _buildFloatingActionButton(isDone),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError || _task == null
            ? _buildErrorState(theme)
            : _buildContent(theme, _task!),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Task task) {
    Category? category;
    for (final entry in _categories) {
      if (entry.category.id == task.categoryId) {
        category = entry.category;
        break;
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              onChanged: _onTitleChanged,
              readOnly: !_isEditing,
              showCursor: _isEditing,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              // need to make hint color same as text color with some opacity to prevent weird jump when user starts typing
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Название задачи',
                hintStyle: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (task.isBurned) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3E3),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFF4B2B2)),
                  ),
                  child: const Text(
                    'Сгоревшая задача',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final categoryButton = OutlinedButton.icon(
                  onPressed: _openCategorySheet,
                  icon: Icon(
                    Icons.bookmark_border,
                    size: 18,
                    color: category == null
                        ? AppColors.mutedText
                        : AppColors.primaryDark,
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (category != null)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Color(category.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        category?.name ?? 'Категория',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: category == null
                        ? AppColors.mutedText
                        : AppColors.primaryDark,
                    side: BorderSide(
                      color: category == null
                          ? const Color(0xFFCDD5CF)
                          : AppColors.primaryDark,
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );

                final reminderButton = OutlinedButton.icon(
                  onPressed: _openReminderSheet,
                  icon: Icon(
                    Icons.access_time,
                    size: 18,
                    color: task.reminderType == null
                        ? AppColors.mutedText
                        : AppColors.primaryDark,
                  ),
                  label: Text(
                    _reminderLabel(task),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: task.reminderType == null
                        ? AppColors.mutedText
                        : AppColors.primaryDark,
                    side: BorderSide(
                      color: task.reminderType == null
                          ? const Color(0xFFCDD5CF)
                          : AppColors.primaryDark,
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                );

                if (constraints.maxWidth < 340) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [categoryButton, reminderButton],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.scale(
                            scale: 1.3,
                            alignment: Alignment.center,
                            child: Checkbox(
                              value: task.isDone,
                              onChanged: (value) {
                                if (value == null) return;
                                _toggleTaskDone(value);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              activeColor: AppColors.primaryDark,
                              side: const BorderSide(color: Color(0xFFCDD5CF)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [categoryButton, reminderButton],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 1.3,
                      alignment: Alignment.center,
                      child: Checkbox(
                        value: task.isDone,
                        onChanged: (value) {
                          if (value == null) return;
                          _toggleTaskDone(value);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        activeColor: AppColors.primaryDark,
                        side: const BorderSide(color: Color(0xFFCDD5CF)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (_isEditing) ...[
              Row(
                children: [
                  _ToolbarIcon(
                    icon: Icons.format_bold,
                    onPressed: _noteController.toggleBold,
                  ),
                  _ToolbarIcon(
                    icon: Icons.format_italic,
                    onPressed: _noteController.toggleItalic,
                  ),
                  _ToolbarIcon(
                    icon: Icons.format_list_bulleted,
                    onPressed: () => _insertLinePrefix('• '),
                  ),
                  _ToolbarIcon(
                    icon: Icons.checklist_rounded,
                    onPressed: () => _insertLinePrefix('✓ '),
                  ),
                  _ToolbarIcon(icon: Icons.link, onPressed: _insertLink),
                ],
              ),
              const Divider(height: 24),
            ] else ...[
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _noteController,
              onChanged: _onNoteChanged,
              readOnly: !_isEditing,
              showCursor: _isEditing,
              maxLines: null,
              minLines: 4,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: Colors.black87,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Дополнительные мысли можно записывать здесь...',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Чеклист',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in _items)
              _ChecklistTile(
                item: item,
                editable: _isEditing,
                onChanged: (value) => _toggleItem(item, value),
                onDelete: () => _deleteItem(item),
              ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      onSubmitted: (_) => _addChecklistItem(),
                      decoration: InputDecoration(
                        hintText: 'Добавить пункт',
                        filled: true,
                        fillColor: const Color(0xFFF3F5F4),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addChecklistItem,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFE4ECE8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ошибка загрузки',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Не удалось открыть заметку. Попробуйте еще раз.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Повторить попытку'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Task _copyTask(
    Task base, {
    String? title,
    String? note,
    bool? isDone,
    bool? isBurned,
    int? categoryId,
    bool setCategory = false,
    ReminderType? reminderType,
    int? reminderMinutes,
    bool setReminder = false,
  }) {
    return Task(
      id: base.id,
      title: title ?? base.title,
      isDone: isDone ?? base.isDone,
      isBurned: isBurned ?? base.isBurned,
      createdAt: base.createdAt,
      note: note ?? base.note,
      categoryId: setCategory ? categoryId : base.categoryId,
      reminderType: setReminder ? reminderType : base.reminderType,
      reminderMinutes: setReminder ? reminderMinutes : base.reminderMinutes,
    );
  }

  Widget _buildFloatingActionButton(bool isDone) {
    switch (_mode) {
      case _NoteScreenMode.editing:
        return FloatingActionButton(
          heroTag: 'fab_save',
          onPressed: _isSaving
              ? null
              : () async {
                  await _leaveEditingMode();
                },
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.check),
        );
      case _NoteScreenMode.actions:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(120 * (1 - _menuAnimation.value), 0),
                  child: Opacity(
                    opacity: _menuAnimation.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: FloatingActionButton.small(
                heroTag: 'fab_start',
                onPressed: isDone ? null : _startTimerFromNote,
                backgroundColor: isDone
                    ? const Color(0xFFE4ECE8)
                    : Colors.white,
                foregroundColor: isDone
                    ? AppColors.mutedText
                    : AppColors.primaryDark,
                shape: const CircleBorder(),
                child: const Icon(Icons.play_arrow_rounded),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(70 * (1 - _menuAnimation.value), 0),
                  child: Opacity(
                    opacity: _menuAnimation.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: FloatingActionButton.small(
                heroTag: 'fab_edit',
                onPressed: _enterEditingMode,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                shape: const CircleBorder(),
                child: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              heroTag: 'fab_actions',
              onPressed: _closeActionsMenu,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              shape: const CircleBorder(),
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _menuAnimation,
              ),
            ),
          ],
        );
      case _NoteScreenMode.view:
      default:
        return FloatingActionButton(
          heroTag: 'fab_actions',
          onPressed: _openActionsMenu,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryDark,
          shape: const CircleBorder(),
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _menuAnimation,
          ),
        );
    }
  }

  String _reminderLabel(Task task) {
    if (task.reminderType == null || task.reminderMinutes == null) {
      return 'Напомнить';
    }
    return '${_reminderTypeLabel(task.reminderType!)} • '
        '${_formatMinutes(task.reminderMinutes!)}';
  }

  String _reminderTypeLabel(ReminderType type) {
    switch (type) {
      case ReminderType.once:
        return 'Один раз';
      case ReminderType.daily:
        return 'Каждый день';
      case ReminderType.weekly:
        return 'Каждую неделю';
      case ReminderType.custom:
        return 'Настроить';
    }
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final h = hours.toString().padLeft(2, '0');
    final m = mins.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: AppColors.mutedText,
      constraints: const BoxConstraints(minWidth: 36),
      padding: EdgeInsets.zero,
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.item,
    required this.onChanged,
    required this.onDelete,
    this.editable = true,
  });

  final TaskItem item;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: item.isDone,
          onChanged: editable
              ? (value) {
                  if (value == null) return;
                  onChanged(value);
                }
              : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          activeColor: AppColors.primaryDark,
          side: const BorderSide(color: Color(0xFFCDD5CF)),
        ),
        Expanded(
          child: Text(
            item.text,
            style: TextStyle(
              fontSize: 14,
              color: item.isDone ? AppColors.mutedText : Colors.black87,
              decoration: item.isDone ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        if (editable)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.mutedText,
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.color,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final Color color;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EAE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count заметок',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primaryDark : AppColors.mutedText,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderOption extends StatelessWidget {
  const _ReminderOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final ReminderType value;
  final ReminderType? groupValue;
  final ValueChanged<ReminderType> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryDark : const Color(0xFFCDD5CF),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primaryDark : AppColors.mutedText,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _ReminderSelection {
  const _ReminderSelection({required this.type, required this.minutes});

  final ReminderType? type;
  final int? minutes;
}

class _CategoryCreateRequest {
  const _CategoryCreateRequest({required this.name, required this.color});

  final String name;
  final int color;
}

class _CategoryClearRequest {
  const _CategoryClearRequest();
}

const List<int> _palette = [
  0xFF176A57,
  0xFF1D8F6D,
  0xFFF5B400,
  0xFFE25C5C,
  0xFF4D7CFF,
  0xFF8B6DFF,
];
