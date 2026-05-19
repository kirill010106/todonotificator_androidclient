import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class TasksViewModel extends ChangeNotifier {
  TasksViewModel(this._repository);

  final TaskRepository _repository;

  List<Task> _tasks = const [];
  Map<int, Category> _categories = const {};
  List<CategoryStats> _categoryStats = const [];
  bool _isLoading = false;
  String? _errorMessage;
  TaskFilter _filter = TaskFilter.all;
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isDisposed = false;

  List<Task> get tasks => _tasks;
  Map<int, Category> get categories => _categories;
  List<CategoryStats> get categoryStats => _categoryStats;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  TaskFilter get filter => _filter;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  Future<void> loadTasks({bool isInitial = false}) async {
    if (_isDisposed) return;
    
    if (isInitial) {
      _isLoading = true;
      _errorMessage = null;
      _safeNotify();
    }

    try {
      var tasksResult = await _repository.fetchTasks(
        filter: _filter,
        query: _searchQuery.isEmpty ? null : _searchQuery,
      );
      if (_isDisposed) return;

      if (_selectedCategoryId != null) {
        tasksResult = tasksResult
            .where((t) => t.categoryId == _selectedCategoryId)
            .toList();
      }

      final categoriesResult = await _repository.fetchCategories();
      if (_isDisposed) return;

      _categoryStats = categoriesResult;
      _categories = {
        for (final stat in categoriesResult) stat.category.id: stat.category,
      };
      _tasks = tasksResult;
      _isLoading = false;
    } catch (e) {
      if (_isDisposed) return;
      _isLoading = false;
      if (isInitial) {
        _errorMessage = 'Не удалось загрузить задачи.';
      }
    }
    _safeNotify();
  }

  void setFilter(TaskFilter filter) {
    if (_filter == filter || _isDisposed) return;
    _filter = filter;
    loadTasks();
  }

  void setSelectedCategoryId(int? categoryId) {
    if (_selectedCategoryId == categoryId || _isDisposed) return;
    _selectedCategoryId = categoryId;
    loadTasks();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query || _isDisposed) return;
    _searchQuery = query;
    loadTasks();
  }

  Future<void> toggleTaskDone(int id, bool isDone) async {
    if (_isDisposed) return;
    try {
      await _repository.setTaskDone(id, isDone);
      await loadTasks();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Не удалось обновить статус задачи.';
        _safeNotify();
      }
    }
  }

  Future<void> resurrectTask(int id) async {
    if (_isDisposed) return;
    try {
      await _repository.resurrectTask(id);
      await loadTasks();
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'Не удалось воскресить задачу.';
        _safeNotify();
      }
    }
  }

  Category? getCategoryForTask(Task task) {
    if (task.categoryId == null) return null;
    return _categories[task.categoryId!];
  }

  @override
  void dispose() {
    _isDisposed = true;
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
