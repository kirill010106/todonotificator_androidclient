import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../ui/theme/app_colors.dart';

class GraveyardScreen extends StatefulWidget {
  const GraveyardScreen({super.key});

  @override
  State<GraveyardScreen> createState() => _GraveyardScreenState();
}

class _GraveyardScreenState extends State<GraveyardScreen> {
  List<Task> _burnedTasks = [];
  Map<int, Category> _categories = {};
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBurnedTasks();
  }

  Future<void> _loadBurnedTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final repo = AppScope.of(context).tasks;
      final tasks = await repo.fetchTasks(filter: TaskFilter.burned);
      final categoriesResult = await repo.fetchCategories();
      
      final categoryMap = {
        for (final stat in categoriesResult) stat.category.id: stat.category,
      };

      if (mounted) {
        setState(() {
          _burnedTasks = tasks;
          _categories = categoryMap;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resurrectTask(Task task) async {
    final repo = AppScope.of(context).tasks;
    await repo.resurrectTask(task.id);
    if (!mounted) return;
    
    await _loadBurnedTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Задача "${task.title}" воскрешена как Hardcore!'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final repo = AppScope.of(context).tasks;
    await repo.deleteTask(task.id);
    if (!mounted) return;
    
    await _loadBurnedTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text('Кладбище задач', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _burnedTasks.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _burnedTasks.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = _burnedTasks[index];
                    final category = task.categoryId != null ? _categories[task.categoryId] : null;
                    return _BurnedTaskCard(
                      task: task,
                      category: category,
                      onResurrect: () => _resurrectTask(task),
                      onDelete: () => _deleteTask(task),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco_outlined, size: 64, color: AppColors.mutedText.withAlpha(100)),
          const SizedBox(height: 16),
          const Text(
            'На кладбище пусто.\nВаша продуктивность безупречна!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _BurnedTaskCard extends StatelessWidget {
  const _BurnedTaskCard({
    required this.task,
    this.category,
    required this.onResurrect,
    required this.onDelete,
  });

  final Task task;
  final Category? category;
  final VoidCallback onResurrect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
            ],
          ),
          if (category != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(category!.color).withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category!.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(category!.color),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Удалить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.mutedText,
                    side: const BorderSide(color: Color(0xFFE1E1E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onResurrect,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Воскресить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
