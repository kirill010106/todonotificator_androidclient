import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../ui/theme/app_colors.dart';
import 'home_screen.dart';

class TargetSelectScreen extends StatefulWidget {
  const TargetSelectScreen({
    super.key,
    this.isChanging = false,
    this.initialId,
  });

  final bool isChanging;
  final String? initialId;

  @override
  State<TargetSelectScreen> createState() => _TargetSelectScreenState();
}

class _TargetSelectScreenState extends State<TargetSelectScreen> {
  static const List<TargetOption> _options = [
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

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialId;
  }

  Future<void> _startDay() async {
    final selected = _selectedId;
    if (selected == null) {
      return;
    }

    await AppScope.of(context).settings.setSelectedTarget(selected);

    if (!mounted) {
      return;
    }

    if (widget.isChanging) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isChanging
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: widget.isChanging ? 8 : 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!widget.isChanging) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Помодоро ТуДу',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    widget.isChanging ? 'Изменить цель дня' : 'Выберите цель дня',
                    style: widget.isChanging
                        ? theme.textTheme.headlineMedium
                        : theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  for (final option in _options) ...[
                    _buildOptionCard(theme, option),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: _selectedId == null ? null : _startDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: const Color(0xFFE1E6E2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      widget.isChanging ? 'Сохранить' : 'Погнали!',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(ThemeData theme, TargetOption option) {
    final isSelected = _selectedId == option.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedId = option.id;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardSelected : AppColors.cardFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            _bullet('${option.tasks} ${_taskWord(option.tasks)}'),
            const SizedBox(height: 4),
            _bullet('${option.intervals} ${_intervalWord(option.intervals)}'),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Row(
      children: [
        const Text('• ', style: TextStyle(color: AppColors.mutedText)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _taskWord(int count) {
    if (count == 1) {
      return 'задача';
    }
    if (count >= 2 && count <= 4) {
      return 'задачи';
    }
    return 'задач';
  }

  String _intervalWord(int count) {
    if (count == 1) {
      return 'интервал';
    }
    if (count >= 2 && count <= 4) {
      return 'интервала';
    }
    return 'интервалов';
  }
}
