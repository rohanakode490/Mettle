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

  testWidgets('HomeScreen shows Rest Day when nothing is scheduled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('No routine scheduled for today.'), findsOneWidget);
    expect(find.text('Rest Day'), findsNWidgets(7));

    // Force disposal of the widget tree to trigger stream unsubscription
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('HomeScreen shows scheduled routine for today', (tester) async {
    final routineId = await db.into(db.routines).insert(
          RoutinesCompanion.insert(name: 'Massive Quads'),
        );
    final today = DateTime.now().weekday;
    await db.into(db.schedules).insert(
          SchedulesCompanion.insert(dayOfWeek: today, routineId: routineId),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Massive Quads'), findsAtLeast(1));
    expect(find.text('START WORKOUT'), findsOneWidget);

    // Force disposal
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
