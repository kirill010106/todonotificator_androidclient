import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_colors.dart';
import '../task_detail_screen.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => TasksTabState();
}

class TasksTabState extends State<TasksTab> {
  final _searchController = TextEditingController();

  TaskFilter _filter = TaskFilter.all;
  List<Task> _tasks = const [];
  Map<int, Category> _categories = const {};
  bool _isLoading = true;
  bool _didLoad = false;
  bool _hasError = false;
  String? _errorMessage;

  late TaskRepository _repo;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = AppScope.of(context).tasks;
    if (!_didLoad) {
      _didLoad = true;
      _loadTasks();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final query = _searchController.text;
      final filter = _filter;
      
      final tasksResult = await _repo.fetchTasks(
        filter: filter,
        query: query,
      );
      final categoriesResult = await _repo.fetchCategories();

      if (!mounted) {
        return;
      }

      final categoryMap = {
        for (final stat in categoriesResult) stat.category.id: stat.category,
      };

      setState(() {
        _tasks = tasksResult;
        _categories = categoryMap;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Не удалось загрузить задачи.';
      });
    }
  }

  Future<void> reloadTasks() => _loadTasks();

  Future<void> openAddTask() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TaskDetailScreen()));
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadTasks(),
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFE6EAE7),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Все', TaskFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('Не сделано', TaskFilter.active),
                const SizedBox(width: 8),
                _buildFilterChip('Сделано', TaskFilter.completed),
                const SizedBox(width: 8),
                _buildFilterChip('Сгорело', TaskFilter.burned),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? _buildErrorState(theme)
                : _tasks.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final category = task.categoryId != null
                          ? _categories[task.categoryId!]
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TaskTile(
                          task: task,
                          category: category,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(taskId: task.id),
                              ),
                            );
                            await _loadTasks();
                          },
                          onChanged: (value) async {
                            final audio = AppScope.of(context).audio;
                            await _repo.setTaskDone(task.id, value);
                            if (value) {
                              audio.playEffect(AudioEffect.taskComplete);
                            }
                            await _loadTasks();
                          },
                          onResurrect: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await _repo.resurrectTask(task.id);
                            if (!mounted) return;
                            await _loadTasks();
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Задача "${task.title}" воскрешена как Hardcore!'),
                                  backgroundColor: const Color(0xFFFF5722),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                    itemCount: _tasks.length,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TaskFilter filter) {
    final isSelected = _filter == filter;
    final isBurnedFilter = filter == TaskFilter.burned;

    Color selectedColor = AppColors.primary;
    Color borderColor = const Color(0xFFCDD5CF);
    
    if (isBurnedFilter) {
      if (isSelected) {
        selectedColor = AppColors.error;
      }
      borderColor = isSelected ? AppColors.error : AppColors.error.withAlpha(100);
    } else if (isSelected) {
      borderColor = AppColors.primary;
    }

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = filter;
          _isLoading = true;
        });
        _loadTasks();
      },
      selectedColor: selectedColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isBurnedFilter ? AppColors.error : AppColors.mutedText),
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: borderColor,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Готовы к новым свершениям?\nПервая задача самая важная!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
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
                _errorMessage ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadTasks,
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
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    this.category,
    required this.onChanged,
    required this.onTap,
    this.onResurrect,
  });

  final Task task;
  final Category? category;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTap;
  final VoidCallback? onResurrect;

  @override
  Widget build(BuildContext context) {
    final isBurned = task.isBurned && !task.isDone;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      onTap: onTap,
      title: Row(
        children: [
          if (task.isHardcore) ...[
            const Icon(
              Icons.local_fire_department,
              size: 16,
              color: Color(0xFFFF5722),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                color: task.isDone
                    ? AppColors.mutedText
                    : isBurned
                    ? AppColors.error
                    : task.isHardcore
                    ? const Color(0xFFFF5722)
                    : Colors.black87,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                fontWeight: task.isHardcore ? FontWeight.w700 : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBurned) ...[
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: AppColors.error,
                ),
                SizedBox(width: 4),
                Text(
                  'Сгорела',
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          ],
          if (task.isHardcore && !task.isDone) ...[
            const SizedBox(height: 4),
            const Text(
              'Hardcore: x1.5 XP',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFFFF5722),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (category != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(category!.color).withAlpha(26),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                category!.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(category!.color),
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: isBurned && onResurrect != null
          ? IconButton(
              onPressed: onResurrect,
              icon: const Icon(Icons.auto_fix_high, color: Color(0xFFFF5722)),
              tooltip: 'Воскресить',
            )
          : Checkbox(
              value: task.isDone,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                onChanged(value);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              activeColor: task.isHardcore ? const Color(0xFFFF5722) : AppColors.primary,
              side: BorderSide(
                color: isBurned
                    ? AppColors.error
                    : task.isHardcore
                    ? const Color(0xFFFF5722)
                    : const Color(0xFFCDD5CF),
              ),
            ),
    );
  }
}
