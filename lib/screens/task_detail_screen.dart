import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../services/audio_service.dart';
import '../ui/theme/app_colors.dart';
import '../ui/widgets/rich_note_controller.dart';
import '../view_models/task_detail_view_model.dart';
import 'category_management_screen.dart';

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

  late final TaskDetailViewModel _vm;
  bool _didInitVm = false;
  bool _seededControllers = false;
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
    if (!_didInitVm) {
      _didInitVm = true;
      _vm = TaskDetailViewModel(
        AppScope.of(context).tasks,
        widget.taskId,
      );
      _vm.addListener(_onVmChanged);
      _vm.load();
      if (_isNew) {
        _mode = _NoteScreenMode.editing;
      }
    }
  }

  void _onVmChanged() {
    if (!mounted) return;
    
    if (_vm.task != null && !_seededControllers) {
      _seededControllers = true;
      _titleController.text = _vm.task!.title;
      _noteController.loadFromStorage(_vm.task!.note ?? '');
    }
    
    setState(() {});
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
    // Update local state in VM then perform full save
    _vm.updateTitle(_titleController.text);
    _vm.updateNote(_noteController.toStorage());
    await _vm.save();
    
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
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _onTitleChanged(String value) {
    _vm.updateTitle(value);
  }

  void _onNoteChanged(String value) {
    _vm.updateNote(_noteController.toStorage());
  }

  Future<void> _resurrectTask() async {
    final task = _vm.task;
    if (task == null) return;
    
    await _vm.resurrectTask();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Задача "${task.title}" воскрешена как Hardcore!'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  Future<void> _toggleTaskDone(bool value) async {
    final task = _vm.task;
    if (task == null) return;

    await _vm.toggleTaskDone(value);
    
    if (!mounted) return;
    
    if (value) {
      AppScope.of(context).audio.playEffect(AudioEffect.taskComplete);
    }
  }

  Future<void> _addChecklistItem() async {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;
    
    await _vm.addChecklistItem(text);
    _itemController.clear();
  }

  Future<void> _toggleItem(TaskItem item, bool value) async {
    await _vm.toggleItem(item, value);
  }

  Future<void> _deleteItem(TaskItem item) async {
    await _vm.deleteItem(item);
  }

  Future<void> _confirmDeleteTask() async {
    if (_isNew) {
      Navigator.of(context).pop();
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

    if (confirmed != true) return;

    await _vm.deleteTask();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _openCategorySheet() async {
    final task = _vm.task;
    if (task == null) return;

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
                  for (final entry in _vm.categories)
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
                  const SizedBox(height: 12),
                  const Divider(),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop(); // Close sheet first
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CategoryManagementScreen(),
                        ),
                      );
                      // Refresh VM categories after returning
                      await _vm.load();
                    },
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Управление категориями'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;

    if (result == null) return;

    if (result is _CategoryCreateRequest) {
      await _vm.addCategory(result.name, result.color);
      return;
    }

    final selectedId = result is _CategoryClearRequest ? null : result as int?;
    await _vm.setCategory(selectedId);
  }

  Future<void> _openReminderSheet() async {
    final task = _vm.task;
    if (task == null) return;

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

    if (!mounted || selection == null) return;

    await _vm.setReminder(selection.type, selection.minutes);
  }

  Future<void> _startTimerFromNote() async {
    if (_vm.isSaving) return;
    
    final current = _vm.task;
    if (current == null) return;
    
    if (current.isDone) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача уже выполнена.')),
        );
      }
      return;
    }

    int? finalId = _vm.taskId;
    if (_isNew) {
      _vm.updateTitle(_titleController.text);
      _vm.updateNote(_noteController.toStorage());
      finalId = await _vm.saveDraft();
      if (finalId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите название заметки.')),
        );
        return;
      }
    } else {
      _vm.updateTitle(_titleController.text);
      _vm.updateNote(_noteController.toStorage());
      await _vm.save(); // Atomic save for existing task
    }

    if (!mounted) return;

    final services = AppScope.of(context);
    services.timer.startForTask(finalId!);
    services.navigation.setTab(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleBack() async {
    if (_vm.isSaving) return;

    try {
      if (_isNew) {
        _vm.updateTitle(_titleController.text);
        _vm.updateNote(_noteController.toStorage());
        await _vm.saveDraft();
      } else {
        _vm.updateTitle(_titleController.text);
        _vm.updateNote(_noteController.toStorage());
        await _vm.save(); // Perform full atomic save before popping
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      // In a real app, you might want to show an error or confirm exit without saving
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
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
    final l10n = AppLocalizations.of(context)!;
    final isDone = _vm.task?.isDone ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
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
          title: Text(l10n.appNote),
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
        body: _vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _vm.hasError || _vm.task == null
            ? _buildErrorState(theme)
            : _buildContent(theme, _vm.task!),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, Task task) {
    final l10n = AppLocalizations.of(context)!;
    Category? category;
    for (final entry in _vm.categories) {
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
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.taskTitleHint,
                hintStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (task.isBurned) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE3E3),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFF4B2B2)),
                    ),
                    child: Text(
                      l10n.taskBurnedStatus,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _resurrectTask,
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: Text(l10n.resurrect),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF5722),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final categoryButton = OutlinedButton.icon(
                  onPressed: _openCategorySheet,
                  icon: Icon(
                    category == null ? Icons.bookmark_border : Icons.bookmark,
                    size: 18,
                    color: category == null
                        ? AppColors.mutedText
                        : Color(category.color),
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          category?.name ?? l10n.category,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                            child: Row(
                              children: [
                                Flexible(child: categoryButton),
                                const SizedBox(width: 8),
                                Flexible(child: reminderButton),
                              ],
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
                      child: Row(
                        children: [
                          Flexible(child: categoryButton),
                          const SizedBox(width: 8),
                          Flexible(child: reminderButton),
                        ],
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
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.noteHint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.checklist,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in _vm.items)
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
                        hintText: l10n.addChecklistItem,
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
    final l10n = AppLocalizations.of(context)!;
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
                l10n.loadErrorTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.taskLoadError,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _vm.load,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: const StadiumBorder(),
                ),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDone) {
    switch (_mode) {
      case _NoteScreenMode.editing:
        return FloatingActionButton(
          heroTag: 'fab_save',
          onPressed: _vm.isSaving
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
    final l10n = AppLocalizations.of(context)!;
    if (task.reminderType == null || task.reminderMinutes == null) {
      return l10n.reminder;
    }
    return '${_reminderTypeLabel(task.reminderType!)} • '
        '${_formatMinutes(task.reminderMinutes!)}';
  }

  String _reminderTypeLabel(ReminderType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case ReminderType.once:
        return l10n.once;
      case ReminderType.daily:
        return l10n.daily;
      case ReminderType.weekly:
        return l10n.weekly;
      case ReminderType.custom:
        return l10n.custom;
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.notesCount(count!),
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
