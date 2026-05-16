import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pomorodo_todo/data/models.dart';
import 'package:pomorodo_todo/data/repositories.dart';
import 'package:pomorodo_todo/services/audio_service.dart';
import 'package:pomorodo_todo/services/gamification_service.dart';

class MockGamificationRepository extends Mock implements GamificationRepository {}
class MockAudioService extends Mock implements AudioService {}

void main() {
  setUpAll(() {
    registerFallbackValue(AudioEffect.achievementUnlock);
  });

  late GamificationService service;
  late MockGamificationRepository mockRepo;
  late MockAudioService mockAudio;

  const userId = 1;

  setUp(() {
    mockRepo = MockGamificationRepository();
    mockAudio = MockAudioService();
    service = GamificationService(mockRepo, mockAudio);

    // Default behaviors
    when(() => mockRepo.getProgress(any())).thenAnswer(
      (_) async => UserProgress.fromTotalXp(0),
    );
    when(() => mockRepo.getUnlockedAchievementIds(any())).thenAnswer(
      (_) async => {},
    );
    when(() => mockAudio.playEffect(any())).thenAnswer((_) async {});
  });

  group('load', () {
    test('loads progress and achievements', () async {
      final progress = UserProgress.fromTotalXp(150, streakDays: 5);
      final unlocked = {'first_task', 'first_pomodoro'};

      when(() => mockRepo.getProgress(userId)).thenAnswer((_) async => progress);
      when(() => mockRepo.getUnlockedAchievementIds(userId)).thenAnswer((_) async => unlocked);

      await service.load(userId);

      expect(service.progress.totalXp, 150);
      expect(service.progress.streakDays, 5);
      expect(service.unlockedIds, unlocked);
    });
  });

  group('recordEvent', () {
    test('adds XP and updates streak', () async {
      final updatedProgress = UserProgress.fromTotalXp(10);
      
      when(() => mockRepo.addXp(userId, 10)).thenAnswer((_) async => updatedProgress);
      when(() => mockRepo.updateStreak(userId)).thenAnswer((_) async => 1);
      when(() => mockRepo.unlockAchievement(any(), any())).thenAnswer((_) async {});

      await service.recordEvent(XpEvent.pomodoroComplete, userId: userId);

      verify(() => mockRepo.addXp(userId, 10)).called(1);
      verify(() => mockRepo.updateStreak(userId)).called(1);
      expect(service.progress.totalXp, 10);
      expect(service.consumeXpDeltas(), [10]);
    });

    test('unlocks achievement when criteria met (pomodoro)', () async {
      when(() => mockRepo.addXp(any(), any())).thenAnswer(
        (_) async => UserProgress.fromTotalXp(10),
      );
      when(() => mockRepo.updateStreak(any())).thenAnswer((_) async => 1);
      when(() => mockRepo.unlockAchievement(userId, 'first_pomodoro')).thenAnswer((_) async {});

      await service.recordEvent(
        XpEvent.pomodoroComplete,
        userId: userId,
        totalPomodoros: 1,
      );

      verify(() => mockRepo.unlockAchievement(userId, 'first_pomodoro')).called(1);
      verify(() => mockAudio.playEffect(AudioEffect.achievementUnlock)).called(1);
      
      final unlock = service.consumePendingUnlock();
      expect(unlock?.id, 'first_pomodoro');
    });

    test('awards bonus XP for achievements', () async {
      // 1. Initial event XP (pomodoro = 10)
      // 2. Achievement bonus XP (first_pomodoro = 50)
      
      var currentXp = 0;
      when(() => mockRepo.addXp(userId, any())).thenAnswer((inv) async {
        final delta = inv.positionalArguments[1] as int;
        currentXp += delta;
        return UserProgress.fromTotalXp(currentXp);
      });
      when(() => mockRepo.updateStreak(any())).thenAnswer((_) async => 1);
      when(() => mockRepo.unlockAchievement(any(), any())).thenAnswer((_) async {});

      await service.recordEvent(
        XpEvent.pomodoroComplete,
        userId: userId,
        totalPomodoros: 1,
      );

      expect(currentXp, 60); // 10 + 50
      expect(service.consumeXpDeltas(), [10, 50]);
    });

    test('does nothing if userId is null', () async {
      await service.recordEvent(XpEvent.taskComplete, userId: null);
      verifyNever(() => mockRepo.addXp(any(), any()));
    });
  });
}
