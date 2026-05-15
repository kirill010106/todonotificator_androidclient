import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class TasksViewModel extends ChangeNotifier {
  TasksViewModel(this._repository);

  final TaskRepository _repository;

  List<Task> _tasks = const [];
  Map<int, Category> _categories = const {};
  bool _isLoading = false;
  String? _errorMessage;
  TaskFilter _filter = TaskFilter.all;
  String _searchQuery = '';

  List<Task> get tasks => _tasks;
  Map<int, Category> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  TaskFilter get filter => _filter;
  String get searchQuery => _searchQuery;

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tasksResult = await _repository.fetchTasks(
        filter: _filter,
        query: _searchQuery.isEmpty ? null : _searchQuery,
      );
      final categoriesResult = await _repository.fetchCategories();

      _categories = {
        for (final stat in categoriesResult) stat.category.id: stat.category,
      };
      _tasks = tasksResult;
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Не удалось загрузить задачи.';
    }
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    loadTasks();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadTasks();
  }

  Future<void> toggleTaskDone(int id, bool isDone) async {
    try {
      await _repository.setTaskDone(id, isDone);
      await loadTasks();
    } catch (e) {
      _errorMessage = 'Не удалось обновить статус задачи.';
      notifyListeners();
    }
  }

  Category? getCategoryForTask(Task task) {
    if (task.categoryId == null) return null;
    return _categories[task.categoryId!];
  }
}
