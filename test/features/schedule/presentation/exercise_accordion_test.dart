import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_log/core/database/database.dart';
import 'package:gym_log/core/database/database_provider.dart';
import 'package:gym_log/features/schedule/presentation/home_screen.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('ExerciseAccordionCard basic expansion test', (tester) async {
    final plan = ExercisePlan(id: 'test-id', name: 'Bench Press', targetSets: '3', targetReps: '10');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseAccordionCard(
                plan: plan,
                routineId: 'routine-1',
                dayIndex: 1,
                isCompleted: false,
                allCompleted: false,
              ),
            ),
          ),
        ),
      ),
    );

    // Expand
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // Verify UI components
    expect(find.text('ADD EXTRA SET'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);
    
    // Should see 3 rows of inputs (3 target sets)
    expect(find.byType(TextField), findsNWidgets(6));

    // Cleanup to avoid Timer pending
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('ExerciseAccordionCard add extra set test', (tester) async {
    final plan = ExercisePlan(id: 'test-id', name: 'Bench Press', targetSets: '1', targetReps: '10');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ExerciseAccordionCard(
                plan: plan,
                routineId: 'routine-1',
                dayIndex: 1,
                isCompleted: false,
                allCompleted: false,
              ),
            ),
          ),
        ),
      ),
    );

    // Expand
    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // Initial 1 row (2 fields)
    expect(find.byType(TextField), findsNWidgets(2));

    // Tap Add Extra Set - This is now LOCAL only
    await tester.tap(find.text('ADD EXTRA SET'));
    await tester.pumpAndSettle();

    // Now 2 rows (4 fields)
    expect(find.byType(TextField), findsNWidgets(4));
    
    // Type in the second row (the extra one)
    // textfields: 0,1 (Set 1), 2,3 (Set 2)
    await tester.enterText(find.byType(TextField).at(2), '50');
    
    // Allow DB write to complete and Stream to fire
    // We need a longer delay for NativeDatabase to flush and Stream to notify
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    // Verify it saved and shifted to row 1 (since it fills target slot)
    expect(find.text('50.0'), findsOneWidget);
    // Now should have only 1 row total (logged set fills the only target slot)
    expect(find.byType(TextField), findsNWidgets(2));

    // Cleanup
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
