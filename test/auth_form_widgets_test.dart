import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/brand_logo.dart';
import 'package:flutter_application_1/features/auth/widgets/auth_form_widgets.dart';
import 'package:flutter_application_1/features/auth/widgets/password_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reference auth design fits a phone and uses Hungry Spot theme', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final email = TextEditingController();
    final password = TextEditingController();
    addTearDown(email.dispose);
    addTearDown(password.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthFormShell(
          headline: 'Log in to the\ngood stuff',
          topSpacing: 38,
          headlineFontSize: 23,
          headlineFontWeight: FontWeight.w500,
          logoSize: 210,
          logoContentScale: 1.24,
          bottomAction: AuthPrimaryButton(
            label: 'LOG IN',
            icon: Icons.login_rounded,
            onPressed: () {},
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: email,
                label: 'Email',
                hintText: 'Enter Email',
              ),
              const SizedBox(height: 18),
              PasswordField(controller: password),
              const SizedBox(height: 19),
              AuthFooterPrompt(
                message: 'Not a member yet?',
                actionLabel: 'Sign up',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Log in to the\ngood stuff'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Not a member yet?'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);

    final logo = tester.widget<HungrySpotLogo>(find.byType(HungrySpotLogo));
    expect(logo.size, 210);
    expect(logo.contentScale, 1.24);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve({}), AppColors.red);
    expect(
      tester.getTopLeft(find.text('Log in to the\ngood stuff')).dy,
      inInclusiveRange(90, 120),
    );
    expect(tester.getRect(find.byType(FilledButton)).bottom, greaterThan(800));
    expect(tester.takeException(), isNull);
  });
}
