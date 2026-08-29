import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/app_primary_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary button compresses while held', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: AppPrimaryButton(label: 'CONTINUE', onPressed: () {}),
          ),
        ),
      ),
    );

    final button = find.widgetWithText(FilledButton, 'CONTINUE');
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 100));

    final scale = find.ancestor(
      of: button,
      matching: find.byType(AnimatedScale),
    );
    expect(scale, findsOneWidget);
    expect(tester.widget<AnimatedScale>(scale).scale, .97);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
  });

  testWidgets('press compression cancels when the pointer becomes a drag', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: AppPrimaryButton(label: 'CONTINUE', onPressed: () {}),
          ),
        ),
      ),
    );

    final button = find.widgetWithText(FilledButton, 'CONTINUE');
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 100));
    final scale = find.ancestor(
      of: button,
      matching: find.byType(AnimatedScale),
    );
    expect(tester.widget<AnimatedScale>(scale).scale, .97);

    await gesture.moveBy(const Offset(0, 18));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<AnimatedScale>(scale).scale, 1);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('primary button emits light haptic feedback on activation', (
    tester,
  ) async {
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: AppPrimaryButton(label: 'CONTINUE', onPressed: () {}),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'CONTINUE'));
    await tester.pump();

    final hapticCalls = platformCalls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
    expect(hapticCalls, hasLength(1));
    expect(hapticCalls.single.arguments, 'HapticFeedbackType.lightImpact');
  });

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
