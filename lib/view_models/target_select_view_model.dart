import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class TargetSelectViewModel extends ChangeNotifier {
  TargetSelectViewModel({
    required SettingsRepository settingsRepository,
    String? initialId,
  })  : _settingsRepository = settingsRepository,
        _selectedId = initialId;

  final SettingsRepository _settingsRepository;

  static const List<TargetOption> options = [
    TargetOption(
      id: 'easy',
      title: 'ЛЕГКИЙ',
      subtitle: 'Цель дня на выбор',
      tasks: 1,
      intervals: 2,
    ),
    TargetOption(
      id: 'tone',
      title: 'В ТОНУСЕ',
      subtitle: 'Цель дня на выбор',
      tasks: 2,
      intervals: 4,
    ),
    TargetOption(
      id: 'burn',
      title: 'ПРОЖАРКА',
      subtitle: 'Цель дня на выбор',
      tasks: 3,
      intervals: 8,
    ),
  ];

  String? _selectedId;
  String? get selectedId => _selectedId;

  void select(String id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  Future<void> save() async {
    if (_selectedId == null) return;
    await _settingsRepository.setSelectedTarget(_selectedId!);
  }

  String taskWord(int count) {
    if (count == 1) return 'задача';
    if (count >= 2 && count <= 4) return 'задачи';
    return 'задач';
  }

  String intervalWord(int count) {
    if (count == 1) return 'интервал';
    if (count >= 2 && count <= 4) return 'интервала';
    return 'интервалов';
  }
}
