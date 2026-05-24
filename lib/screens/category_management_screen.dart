import 'package:flutter/material.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';
import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../ui/theme/app_colors.dart';
import '../../view_models/category_management_view_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  late final CategoryManagementViewModel _vm;
  bool _didInit = false;

  final List<int> _palette = [
    0xFF176A57,
    0xFF1D8F6D,
    0xFFF5B400,
    0xFFE25C5C,
    0xFF4D7CFF,
    0xFF8B6DFF,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _vm = CategoryManagementViewModel(AppScope.of(context).tasks);
      _vm.addListener(_onVmChanged);
      _vm.load();
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: Text(l10n.manageCategories),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vm.categories.isEmpty
              ? Center(child: Text(l10n.noCategories))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vm.categories.length,
                  itemBuilder: (context, index) {
                    final stats = _vm.categories[index];
                    return _CategoryListTile(
                      stats: stats,
                      l10n: l10n,
                      onEdit: () => _showEditCategoryDialog(stats.category),
                      onDelete: () => _showDeleteConfirmation(stats.category),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppColors.primaryDark,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showAddCategoryDialog() async {
    final result = await _showCategoryDialog();
    if (result != null) {
      await _vm.addCategory(result.name, result.color);
    }
  }

  Future<void> _showEditCategoryDialog(Category category) async {
    final result = await _showCategoryDialog(
      initialName: category.name,
      initialColor: category.color,
    );
    if (result != null) {
      await _vm.updateCategory(category.id, name: result.name, color: result.color);
    }
  }

  Future<void> _showDeleteConfirmation(Category category) async {
    final l10n = AppLocalizations.of(context)!;
    final otherCategories = _vm.categories
        .where((c) => c.category.id != category.id)
        .map((c) => c.category)
        .toList();

    int? migrateToId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.deleteCategory),
              content: RadioGroup<int?>(
                groupValue: migrateToId,
                onChanged: (val) => setDialogState(() => migrateToId = val),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.notesCount(_vm.categories.firstWhere((c) => c.category.id == category.id).taskCount)}:'),
                    const SizedBox(height: 8),
                    RadioListTile<int?>(
                      title: Text(l10n.leaveCategoryless),
                      value: null,
                    ),
                    if (otherCategories.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(l10n.migrateTo),
                      ),
                      ...otherCategories.map((cat) => RadioListTile<int?>(
                            title: Text(cat.name),
                            value: cat.id,
                          )),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await _vm.deleteCategory(category.id, migrateToId: migrateToId);
    }
  }

  Future<_CategoryDialogResult?> _showCategoryDialog({
    String? initialName,
    int? initialColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: initialName);
    int selectedColor = initialColor ?? _palette.first;

    return showDialog<_CategoryDialogResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(initialName == null ? l10n.newCategory : l10n.editCategory),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(hintText: l10n.categoryNameHint),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _palette.map((color) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      Navigator.pop(
                        context,
                        _CategoryDialogResult(
                          name: nameController.text.trim(),
                          color: selectedColor,
                        ),
                      );
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  const _CategoryListTile({
    required this.stats,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryStats stats;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(stats.category.color),
          radius: 8,
        ),
        title: Text(stats.category.name),
        subtitle: Text(l10n.notesCountShort(stats.taskCount)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class _CategoryDialogResult {
  final String name;
  final int color;
  _CategoryDialogResult({required this.name, required this.color});
}
