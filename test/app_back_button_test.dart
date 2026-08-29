import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/app_back_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared back button owns blue styling and navigation action', (
    tester,
  ) async {
    var pressed = false;
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
          body: Center(child: AppBackButton(onPressed: () => pressed = true)),
        ),
      ),
    );

    final button = find.byType(AppBackButton);
    expect(button, findsOneWidget);
    expect(tester.getSize(button), const Size.square(44));

    final icon = tester.widget<Icon>(
      find.byIcon(Icons.arrow_back_ios_new_rounded),
    );
    expect(icon.color, AppColors.navigationBlue);

    await tester.tap(button);
    expect(pressed, isTrue);
    final hapticCalls = platformCalls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
    expect(hapticCalls, hasLength(1));
    expect(hapticCalls.single.arguments, 'HapticFeedbackType.selectionClick');
  });
}
