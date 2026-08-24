import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kinetic_precision/core/database/app_database.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const KineticPrecisionApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(KineticPrecisionApp), findsOneWidget);
    await db.close();
  });
}
