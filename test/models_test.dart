import 'package:flutter_test/flutter_test.dart';
import 'package:pomorodo_todo/data/models.dart';

void main() {
  group('UserProgress.fromTotalXp', () {
    test('Level 1: 0 XP', () {
      final progress = UserProgress.fromTotalXp(0);
      expect(progress.level, 1);
      expect(progress.xpInCurrentLevel, 0);
      expect(progress.xpForNextLevel, 100);
    });

    test('Level 1: 50 XP', () {
      final progress = UserProgress.fromTotalXp(50);
      expect(progress.level, 1);
      expect(progress.xpInCurrentLevel, 50);
      expect(progress.xpForNextLevel, 100);
    });

    test('Level 2 transition: 100 XP', () {
      // Level 1 needs 100 * 1 * 1 = 100 XP
      final progress = UserProgress.fromTotalXp(100);
      expect(progress.level, 2);
      expect(progress.xpInCurrentLevel, 0);
      expect(progress.xpForNextLevel, 100 * 2 * 2); // 400
    });

    test('Level 2 mid: 250 XP', () {
      final progress = UserProgress.fromTotalXp(250);
      expect(progress.level, 2);
      expect(progress.xpInCurrentLevel, 150);
      expect(progress.xpForNextLevel, 400);
    });

    test('Level 3 transition: 500 XP', () {
      // L1: 100
      // L2: 400
      // Total 500
      final progress = UserProgress.fromTotalXp(500);
      expect(progress.level, 3);
      expect(progress.xpInCurrentLevel, 0);
      expect(progress.xpForNextLevel, 100 * 3 * 3); // 900
    });
  });

  group('extractPlainNote', () {
    test('returns empty for null or empty', () {
      expect(extractPlainNote(null), '');
      expect(extractPlainNote(''), '');
    });

    test('returns plain text as is', () {
      expect(extractPlainNote('hello world'), 'hello world');
    });

    test('extracts text from JSON note', () {
      final jsonNote = '{"text": "Extracted text", "other": 123}';
      expect(extractPlainNote(jsonNote), 'Extracted text');
    });

    test('returns raw string if JSON is invalid or missing text key', () {
      expect(extractPlainNote('{"foo": "bar"}'), '{"foo": "bar"}');
      expect(extractPlainNote('{not json'), '{not json');
    });
  });
}
