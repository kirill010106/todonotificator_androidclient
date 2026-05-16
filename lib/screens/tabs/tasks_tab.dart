import 'package:flutter/material.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';
import '../../ui/theme/app_colors.dart';
import '../../view_models/tasks_view_model.dart';
import '../task_detail_screen.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => TasksTabState();
}

class TasksTabState extends State<TasksTab> {
  final _searchController = TextEditingController();

  TasksViewModel? _vm;
  bool _didInitVm = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitVm) {
      _didInitVm = true;
      _vm = TasksViewModel(AppScope.of(context).tasks);
      _vm!.addListener(_onVmChanged);
      _vm!.loadTasks(isInitial: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vm?.removeListener(_onVmChanged);
    super.dispose();
  }

  void _onVmChanged() {
    if (mounted) setState(() {});
  }

  Future<void> reloadTasks() async {
    await _vm?.loadTasks();
  }

  Future<void> openAddTask() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TaskDetailScreen()));
    await _vm?.loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final vm = _vm;

    if (vm == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => vm.setSearchQuery(value),
              decoration: InputDecoration(
                hintText: l10n.searchHint,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1E6E2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _buildFilterChip(l10n.filterAll, TaskFilter.all),
                      const SizedBox(width: 4),
                      _buildFilterChip(l10n.filterNotDone, TaskFilter.active),
                      const SizedBox(width: 4),
                      _buildFilterChip(l10n.filterDone, TaskFilter.completed),
                      const SizedBox(width: 4),
                      _buildFilterChip(l10n.filterBurned, TaskFilter.burned),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (vm.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: _buildHybridCategoryChips(l10n, vm),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.hasError
                ? _buildErrorState(theme, vm)
                : vm.tasks.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final task = vm.tasks[index];
                      final category = vm.getCategoryForTask(task);
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
                            await vm.loadTasks();
                          },
                          onChanged: (value) async {
                            final audio = AppScope.of(context).audio;
                            await vm.toggleTaskDone(task.id, value);
                            if (value) {
                              audio.playEffect(AudioEffect.taskComplete);
                            }
                          },
                          onResurrect: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await vm.resurrectTask(task.id);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(l10n.taskResurrected(task.title)),
                                  backgroundColor: const Color(0xFFFF5722),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                    itemCount: vm.tasks.length,
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHybridCategoryChips(AppLocalizations l10n, TasksViewModel vm) {
    const maxVisible = 3;
    final allStats = vm.categoryStats;
    final selectedId = vm.selectedCategoryId;

    // 1. Always start with "All Categories"
    final chips = <Widget>[
      _buildCategoryChip(l10n.allCategories, null),
    ];

    // 2. Identify categories to show
    final List<Category> visibleCategories = [];

    // Always include selected category if it's not "All"
    if (selectedId != null) {
      final selectedCat = vm.categories[selectedId];
      if (selectedCat != null) {
        visibleCategories.add(selectedCat);
      }
    }

    // Fill remaining slots with most popular (by task count), excluding selected
    final remainingCount = maxVisible - visibleCategories.length;
    if (remainingCount > 0) {
      final popular = allStats
          .where((s) => s.category.id != selectedId)
          .toList()
        ..sort((a, b) => b.taskCount.compareTo(a.taskCount));

      for (var i = 0; i < remainingCount && i < popular.length; i++) {
        visibleCategories.add(popular[i].category);
      }
    }

    // 3. Render visible category chips
    for (final cat in visibleCategories) {
      chips.add(const SizedBox(width: 4));
      chips.add(_buildCategoryChip(cat.name, cat.id, color: Color(cat.color)));
    }

    // 4. Add "More..." if there are more categories
    if (allStats.length > visibleCategories.length + (selectedId == null ? 0 : 0)) {
      // Actually if total categories > visible categories shown (excluding All)
      if (allStats.length > visibleCategories.length) {
         chips.add(const SizedBox(width: 4));
         chips.add(
           ActionChip(
             label: Text(l10n.more),
             onPressed: () => _showAllCategoriesSheet(l10n, vm),
             backgroundColor: Colors.white,
             side: const BorderSide(color: Color(0xFFCDD5CF)),
             labelStyle: const TextStyle(
               color: AppColors.mutedText,
               fontSize: 12,
               fontWeight: FontWeight.w600,
             ),
             padding: const EdgeInsets.symmetric(horizontal: 4),
           ),
         );
      }
    }

    return chips;
  }

  void _showAllCategoriesSheet(AppLocalizations l10n, TasksViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.allCategories,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip(l10n.allCategories, null),
                  for (final stat in vm.categoryStats)
                    _buildCategoryChip(
                      stat.category.name,
                      stat.category.id,
                      color: Color(stat.category.color),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, int? categoryId, {Color? color}) {
    final vm = _vm!;
    final isSelected = vm.selectedCategoryId == categoryId;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) {
        vm.setSelectedCategoryId(categoryId);
      },
      selectedColor: color ?? AppColors.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: isSelected ? (color ?? AppColors.primary) : const Color(0xFFCDD5CF),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFilterChip(String label, TaskFilter filter) {
    final vm = _vm!;
    final isSelected = vm.filter == filter;
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
      showCheckmark: false,
      onSelected: (_) {
        vm.setFilter(filter);
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.emptyTasks,
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

  Widget _buildErrorState(ThemeData theme, TasksViewModel vm) {
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
                vm.errorMessage ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: vm.loadTasks,
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
    final l10n = AppLocalizations.of(context)!;
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
              children: [
                const Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.burned,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          ],
          if (task.isHardcore && !task.isDone) ...[
            const SizedBox(height: 4),
            Text(
              l10n.taskHardcoreBonus,
              style: const TextStyle(
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
