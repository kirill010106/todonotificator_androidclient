import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class CategoryManagementViewModel extends ChangeNotifier {
  CategoryManagementViewModel(this._repository);

  final TaskRepository _repository;

  List<CategoryStats> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  List<CategoryStats> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repository.fetchCategories();
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Не удалось загрузить категории.';
    }
    notifyListeners();
  }

  Future<void> addCategory(String name, int color) async {
    try {
      await _repository.addCategory(name: name, color: color);
      await load();
    } catch (e) {
      _errorMessage = 'Не удалось добавить категорию.';
      notifyListeners();
    }
  }

  Future<void> updateCategory(int id, {String? name, int? color}) async {
    try {
      await _repository.updateCategory(id: id, name: name, color: color);
      await load();
    } catch (e) {
      _errorMessage = 'Не удалось обновить категорию.';
      notifyListeners();
    }
  }

  Future<void> deleteCategory(int id, {int? migrateToId}) async {
    try {
      await _repository.deleteCategory(id, migrateToId: migrateToId);
      await load();
    } catch (e) {
      _errorMessage = 'Не удалось удалить категорию.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
