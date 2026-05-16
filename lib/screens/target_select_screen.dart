import 'package:flutter/material.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';

import '../app/app_scope.dart';
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
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialId ?? 'tone';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isChanging
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                l10n.choosePace,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1C19),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.paceDescription,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildPaceCard(
                id: 'easy',
                icon: Icons.eco_outlined,
                title: l10n.paceEasyTitle,
                description: l10n.paceEasyDesc,
              ),
              const SizedBox(height: 16),
              _buildPaceCard(
                id: 'tone',
                icon: Icons.bolt_outlined,
                title: l10n.paceToneTitle,
                description: l10n.paceToneDesc,
              ),
              const SizedBox(height: 16),
              _buildPaceCard(
                id: 'burn',
                icon: Icons.local_fire_department_outlined,
                title: l10n.paceRoastTitle,
                description: l10n.paceRoastDesc,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedId == null ? null : _startDay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6CB9A1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.letsGo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaceCard({
    required String id,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedId == id;
    const selectedBorderColor = Color(0xFF176A57);
    const unselectedBorderColor = Color(0xFFE1E6E2);

    return GestureDetector(
      onTap: () => setState(() => _selectedId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedBorderColor : unselectedBorderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedBorderColor.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? selectedBorderColor : AppColors.mutedText,
                    size: 28,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? selectedBorderColor : const Color(0xFF1A1C19),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F4F1),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: selectedBorderColor,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
