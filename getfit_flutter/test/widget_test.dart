import 'package:flutter_test/flutter_test.dart';
import 'package:getfit/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getfit/core/database/app_database.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final db = AppDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const GetFitApp(),
      ),
    );
    // App should render without crashing
    expect(find.byType(GetFitApp), findsOneWidget);
  });
}
