import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';

import '../data/local_database.dart';
import '../data/repositories.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required SettingsRepository settingsRepository,
    required AuthRepository authRepository,
  }) : _settingsRepository = settingsRepository,
       _authRepository = authRepository;

  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;

  bool _darkTheme = false;
  bool _strictMode = false;
  String _languageCode = 'ru';
  String _targetTitle = 'tone';
  bool _isLoading = true;

  bool get darkTheme => _darkTheme;
  bool get strictMode => _strictMode;
  String get languageCode => _languageCode;
  String get targetTitle => _targetTitle;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _strictMode = await _settingsRepository.isStrictModeEnabled();
    _languageCode = await _settingsRepository.getLocale() ?? 'ru';

    final targetId = await _settingsRepository.getSelectedTarget();
    if (targetId == 'easy') {
      _targetTitle = 'easy';
    } else if (targetId == 'burn') {
      _targetTitle = 'burn';
    } else {
      _targetTitle = 'tone';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setDarkTheme(bool value) {
    _darkTheme = value;
    notifyListeners();
  }

  Future<void> setStrictMode(bool value) async {
    _strictMode = value;
    await _settingsRepository.setStrictModeEnabled(value);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    await _settingsRepository.setLocale(code);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    // In a real app we would call a delete API here.
    await _authRepository.logout();
  }

  Future<String?> getSelectedTargetId() async {
    return await _settingsRepository.getSelectedTarget();
  }

  Future<bool> exportData(AppLocalizations l10n) async {
    try {
      final json = await LocalDatabase.instance.exportData();
      final tempDir = await getTemporaryDirectory();
      final date = DateTime.now().toString().split(' ')[0].replaceAll('-', '');
      final file = File('${tempDir.path}/pomodoro_backup_$date.json');
      await file.writeAsString(json);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.exportData,
      );
      return true;
    } catch (e) {
      debugPrint('[SettingsViewModel] Export error: $e');
      return false;
    }
  }

  Future<bool?> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return null; // Cancelled
      }

      final file = File(result.files.single.path!);
      final json = await file.readAsString();

      await LocalDatabase.instance.importData(json);
      await load();
      return true;
    } catch (e) {
      debugPrint('[SettingsViewModel] Import error: $e');
      return false;
    }
  }
}
