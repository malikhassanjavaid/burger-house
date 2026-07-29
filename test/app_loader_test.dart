import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/core/widgets/app_loader.dart';

void main() {
  testWidgets('loading overlay shows animation without visible loading text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoadingOverlay(
            loading: true,
            semanticsLabel: 'Signing in',
            child: Text('Page content'),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Signing in'), findsNothing);
    expect(find.text('Page content'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLoadingOverlay(loading: false, child: Text('Page content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
