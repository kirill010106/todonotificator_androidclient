import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomorodo_todo/ui/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField displays hint and handles input', (WidgetTester tester) async {
    final controller = TextEditingController();
    const hint = 'Enter task name';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            hintText: hint,
          ),
        ),
      ),
    );

    // Verify hint text is present
    expect(find.text(hint), findsOneWidget);

    // Enter text
    await tester.enterText(find.byType(AppTextField), 'New Task');
    expect(controller.text, 'New Task');
  });

  testWidgets('AppTextField displays error text', (WidgetTester tester) async {
    final controller = TextEditingController();
    const error = 'Field required';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            hintText: 'Hint',
            errorText: error,
          ),
        ),
      ),
    );

    expect(find.text(error), findsOneWidget);
  });
}
