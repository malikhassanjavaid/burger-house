import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/app_primary_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary button owns brand styling and delegates its action', (
    tester,
  ) async {
    var presses = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: AppPrimaryButton(
              label: 'CONTINUE',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => presses++,
            ),
          ),
        ),
      ),
    );

    final buttonFinder = find.widgetWithText(FilledButton, 'CONTINUE');
    expect(buttonFinder, findsOneWidget);
    final button = tester.widget<FilledButton>(buttonFinder);
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      AppColors.red,
    );

    await tester.tap(buttonFinder);
    expect(presses, 1);
  });

  testWidgets('primary button shows a disabled loading state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(
            label: 'SAVING',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
