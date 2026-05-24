import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pomorodo_todo/data/models.dart';
import 'package:pomorodo_todo/data/repositories.dart';
import 'package:pomorodo_todo/view_models/task_detail_view_model.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late TaskDetailViewModel viewModel;
  late MockTaskRepository mockRepo;

  setUp(() {
    mockRepo = MockTaskRepository();
    // Default mock behavior for loading new task
    when(() => mockRepo.fetchCategories()).thenAnswer((_) async => []);
  });

  group('New Task Mode', () {
    setUp(() {
      viewModel = TaskDetailViewModel(mockRepo, null);
    });

    test('initial state', () async {
      await viewModel.load();
      expect(viewModel.isNew, true);
      expect(viewModel.task, isNotNull);
      expect(viewModel.task?.title, '');
      expect(viewModel.items, isEmpty);
    });

    test('checklist items added to draft', () async {
      await viewModel.load();
      await viewModel.addChecklistItem('Item 1');
      await viewModel.addChecklistItem('Item 2');

      expect(viewModel.items.length, 2);
      expect(viewModel.items[0].text, 'Item 1');
      expect(viewModel.items[0].id, -1); // Draft IDs are negative
    });

    test('saveDraft creates task and items', () async {
      when(
        () => mockRepo.saveTaskFull(
          title: any(named: 'title'),
          note: any(named: 'note'),
          categoryId: any(named: 'categoryId'),
          reminderType: any(named: 'reminderType'),
          reminderMinutes: any(named: 'reminderMinutes'),
          isDone: any(named: 'isDone'),
          isBurned: any(named: 'isBurned'),
          isHardcore: any(named: 'isHardcore'),
          items: any(named: 'items'),
        ),
      ).thenAnswer((_) async => 123);

      await viewModel.load();
      viewModel.updateTitle('Draft Task');
      await viewModel.addChecklistItem('Draft Item');
      
      final resultId = await viewModel.saveDraft();

      expect(resultId, 123);
      final captured = verify(
        () => mockRepo.saveTaskFull(
          title: 'Draft Task',
          note: any(named: 'note'),
          categoryId: any(named: 'categoryId'),
          reminderType: any(named: 'reminderType'),
          reminderMinutes: any(named: 'reminderMinutes'),
          isDone: false,
          isBurned: false,
          isHardcore: false,
          items: captureAny(named: 'items'),
        ),
      ).captured;
      final items = captured.single as List<TaskItem>;
      expect(items, hasLength(1));
      expect(items.single.text, 'Draft Item');
    });
  });

  group('Existing Task Mode', () {
    const taskId = 10;
    final existingTask = Task(
      id: taskId,
      title: 'Existing',
      isDone: false,
      isBurned: false,
      isHardcore: false,
      createdAt: DateTime.now(),
    );

    setUp(() {
      viewModel = TaskDetailViewModel(mockRepo, taskId);
      when(() => mockRepo.getTask(taskId)).thenAnswer((_) async => existingTask);
      when(() => mockRepo.fetchTaskItems(taskId)).thenAnswer((_) async => []);
    });

    test('loads existing task', () async {
      await viewModel.load();
      expect(viewModel.isNew, false);
      expect(viewModel.task?.id, taskId);
      expect(viewModel.task?.title, 'Existing');
    });

    test('updateTitle triggers repository call after debounce', () async {
      when(() => mockRepo.updateTaskTitle(any(), any())).thenAnswer((_) async {});
      await viewModel.load();
      
      viewModel.updateTitle('Updated');
      
      // Should not be called immediately due to debounce
      verifyNever(() => mockRepo.updateTaskTitle(any(), any()));

      // Wait for debounce (400ms)
      await Future.delayed(const Duration(milliseconds: 500));
      
      verify(() => mockRepo.updateTaskTitle(taskId, 'Updated')).called(1);
    });
  });
}
