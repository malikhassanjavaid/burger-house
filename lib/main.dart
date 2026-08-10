import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Firebase initialization is asynchronous. This line makes sure Flutter is
  // ready before we await Firebase.initializeApp().
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase Functions requires the Blaze plan only when the backend is
  // deployed. For local Stripe demos, route callable functions to the local
  // emulator instead. This is opt-in so normal builds keep using Firebase.
  const useFunctionsEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  if (useFunctionsEmulator) {
    const emulatorHost = String.fromEnvironment(
      'FUNCTIONS_EMULATOR_HOST',
      defaultValue: '127.0.0.1',
    );
    const emulatorPort = int.fromEnvironment(
      'FUNCTIONS_EMULATOR_PORT',
      defaultValue: 5001,
    );
    FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, emulatorPort);
  }

  const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  if (stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = stripePublishableKey;
    await Stripe.instance.applySettings();
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const HungrySpotApp());
}
