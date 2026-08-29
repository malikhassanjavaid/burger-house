import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/app_bottom_action_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom action compresses while held', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: AppBottomActionButton(label: 'CHECKOUT', onPressed: () {}),
          ),
        ),
      ),
    );

    final action = find.byType(AppBottomActionButton);
    final gesture = await tester.startGesture(tester.getCenter(action));
    await tester.pump(const Duration(milliseconds: 100));

    final scale = find.descendant(
      of: action,
      matching: find.byType(AnimatedScale),
    );
    expect(scale, findsOneWidget);
    expect(tester.widget<AnimatedScale>(scale).scale, .97);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
  });

  testWidgets('bottom actions use feedback matched to their consequence', (
    tester,
  ) async {
    const cases = <(String, String)>[
      ('CHECKOUT', 'HapticFeedbackType.lightImpact'),
      ('PLACE ORDER', 'HapticFeedbackType.mediumImpact'),
      ('PAY & CONTINUE', 'HapticFeedbackType.mediumImpact'),
    ];
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

    for (final actionCase in cases) {
      platformCalls.clear();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: AppBottomActionButton(
                label: actionCase.$1,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppBottomActionButton));
      await tester.pump();

      final hapticCalls = platformCalls
          .where((call) => call.method == 'HapticFeedback.vibrate')
          .toList();
      expect(hapticCalls, hasLength(1), reason: actionCase.$1);
      expect(
        hapticCalls.single.arguments,
        actionCase.$2,
        reason: actionCase.$1,
      );
    }
  });

  testWidgets('bottom action uses a red bar and semantic white button', (
    tester,
  ) async {
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppBottomActionBar(
            eyebrow: '2 ITEMS',
            amount: r'$24.98',
            caption: 'Inclusive of taxes',
            actionLabel: 'CHECKOUT',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );

    final surface = tester.widget<Material>(
      find.byKey(const ValueKey('app-bottom-action-surface')),
    );
    expect(surface.color, AppColors.red);

    final action = find.byType(AppBottomActionButton);
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, 46);
    final iconFinder = find.descendant(of: action, matching: find.byType(Icon));
    expect(iconFinder, findsOneWidget);
    if (iconFinder.evaluate().isEmpty) return;
    final icon = tester.widget<Icon>(iconFinder);
    expect(icon.icon, Icons.shopping_bag_outlined);

    final label = tester.widget<Text>(
      find.descendant(of: action, matching: find.text('CHECKOUT')),
    );
    expect(label.style?.color, AppColors.red);
    expect(label.style?.fontSize, 11);
    expect(label.style?.fontWeight, FontWeight.w700);

    await tester.tap(action);
    expect(pressed, isTrue);
  });

  testWidgets('order and payment actions use matching icons', (tester) async {
    const cases = <(String, IconData)>[
      ('PLACE ORDER', Icons.receipt_long_rounded),
      ('CONFIRM PICKUP', Icons.storefront_rounded),
      ('PAY & CONTINUE', Icons.lock_rounded),
    ];

    for (final actionCase in cases) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppBottomActionButton(
                label: actionCase.$1,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);
      if (iconFinder.evaluate().isEmpty) return;
      final icon = tester.widget<Icon>(iconFinder);
      expect(
        icon.icon,
        actionCase.$2,
        reason: 'Wrong icon for ${actionCase.$1}',
      );
      expect(find.text(actionCase.$1), findsOneWidget);
    }
  });
}
