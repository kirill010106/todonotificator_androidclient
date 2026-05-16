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
      final createdTask = Task(
        id: 123,
        title: 'Draft Task',
        isDone: false,
        isBurned: false,
        isHardcore: false,
        createdAt: DateTime.now(),
      );

      when(() => mockRepo.addTask(title: any(named: 'title')))
          .thenAnswer((_) async => createdTask);
      when(() => mockRepo.addTaskItem(taskId: any(named: 'taskId'), text: any(named: 'text')))
          .thenAnswer((inv) async => TaskItem(
                id: 1,
                taskId: inv.namedArguments[#taskId],
                text: inv.namedArguments[#text],
                isDone: false,
                position: 0,
              ));

      await viewModel.load();
      viewModel.updateTitle('Draft Task');
      await viewModel.addChecklistItem('Draft Item');
      
      final resultId = await viewModel.saveDraft();

      expect(resultId, 123);
      verify(() => mockRepo.addTask(title: 'Draft Task')).called(1);
      verify(() => mockRepo.addTaskItem(taskId: 123, text: 'Draft Item')).called(1);
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
