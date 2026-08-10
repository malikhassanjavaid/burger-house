import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../models/fulfillment_method.dart';

class StripePaymentResult {
  const StripePaymentResult({
    required this.paymentIntentId,
    required this.amountCents,
  });

  final String paymentIntentId;
  final int amountCents;
}

class StripePaymentException implements Exception {
  const StripePaymentException(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

/// Runs Stripe's native PaymentSheet while keeping the secret key on the
/// trusted Firebase Functions backend.
class StripePaymentService {
  StripePaymentService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;
  static const _callTimeout = Duration(seconds: 30);
  static const _retryDelay = Duration(milliseconds: 650);
  static const _useFunctionsEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  static const _functionsEmulatorHost = String.fromEnvironment(
    'FUNCTIONS_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  static const _functionsEmulatorPort = int.fromEnvironment(
    'FUNCTIONS_EMULATOR_PORT',
    defaultValue: 5001,
  );

  static bool get isConfigured {
    try {
      return Stripe.publishableKey.trim().startsWith('pk_test_');
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> payload,
  ) async {
    if (_useFunctionsEmulator) {
      return _callEmulatorFunction(name, payload);
    }

    FirebaseFunctionsException? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt > 0) {
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
          await Future<void>.delayed(_retryDelay);
        }

        final callable = _functions.httpsCallable(
          name,
          options: HttpsCallableOptions(timeout: _callTimeout),
        );
        final response = await callable.call<Map<String, dynamic>>(payload);
        return Map<String, dynamic>.from(response.data);
      } on FirebaseFunctionsException catch (error) {
        lastError = error;
        final canRetry = switch (error.code) {
          'unavailable' || 'deadline-exceeded' || 'unauthenticated' => true,
          _ => false,
        };
        if (attempt == 0 && canRetry) {
          continue;
        }
        rethrow;
      }
    }

    throw lastError ??
        const StripePaymentException(
          'The secure payment service could not be reached.',
        );
  }

  Future<Map<String, dynamic>> _callEmulatorFunction(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const StripePaymentException('Please sign in again before paying.');
    }

    final projectId = Firebase.app().options.projectId;
    final endpoint = Uri.parse(
      'http://$_functionsEmulatorHost:$_functionsEmulatorPort/'
      '$projectId/us-central1/$name',
    );

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final idToken = await user.getIdToken(attempt > 0);
        if (idToken == null || idToken.isEmpty) {
          throw const StripePaymentException(
            'Your sign-in session expired. Please sign in again and retry.',
          );
        }

        final response = await http
            .post(
              endpoint,
              headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json; charset=utf-8',
              },
              body: jsonEncode({'data': payload}),
            )
            .timeout(_callTimeout);

        final decoded = response.body.isEmpty
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(
                jsonDecode(response.body) as Map<dynamic, dynamic>,
              );
        final functionError = decoded['error'];
        final isUnauthenticated =
            response.statusCode == 401 ||
            (functionError is Map &&
                functionError['status'] == 'UNAUTHENTICATED');

        if (isUnauthenticated && attempt == 0) {
          await user.getIdToken(true);
          await Future<void>.delayed(_retryDelay);
          continue;
        }

        if (response.statusCode < 200 ||
            response.statusCode >= 300 ||
            functionError != null) {
          final message = functionError is Map
              ? functionError['message'] as String?
              : null;
          throw StripePaymentException(
            message ?? 'The secure payment service is unavailable.',
          );
        }

        final result = decoded['result'] ?? decoded['data'];
        if (result is! Map) {
          throw const StripePaymentException(
            'The payment service returned an invalid response.',
          );
        }
        return Map<String, dynamic>.from(result);
      } on TimeoutException {
        throw const StripePaymentException(
          'The local Stripe test service timed out. Keep the phone connected '
          'by USB and restart the local test service.',
        );
      } on http.ClientException {
        throw const StripePaymentException(
          'The local Stripe test service cannot be reached. Keep the phone '
          'connected by USB and start the app with run_hot_reload.ps1.',
        );
      } on FormatException {
        throw const StripePaymentException(
          'The local Stripe test service returned an invalid response.',
        );
      }
    }

    throw const StripePaymentException(
      'Your sign-in session expired. Please sign in again and retry.',
    );
  }

  StripePaymentException _functionsError(FirebaseFunctionsException error) {
    return switch (error.code) {
      'unauthenticated' => const StripePaymentException(
        'Your sign-in session expired. Please sign in again and retry.',
      ),
      'unavailable' || 'deadline-exceeded' => const StripePaymentException(
        'The local Stripe test service cannot be reached. Keep your phone '
        'connected by USB and start the app with run_hot_reload.ps1.',
      ),
      _ => StripePaymentException(
        error.message ?? 'The secure payment service is unavailable.',
      ),
    };
  }

  Future<StripePaymentResult> pay({
    required double amount,
    required FulfillmentMethod fulfillmentMethod,
  }) async {
    if (!isConfigured) {
      throw const StripePaymentException(
        'Stripe test mode is not configured on this device yet.',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const StripePaymentException('Please sign in again before paying.');
    }

    final amountCents = (amount * 100).round();
    final nonce = Random.secure().nextInt(1 << 32).toRadixString(16);
    final idempotencyKey =
        '${user.uid}-${DateTime.now().microsecondsSinceEpoch}-$nonce';

    try {
      final data = await _callFunction('createPaymentIntent', {
        'amount': amountCents,
        'currency': 'usd',
        'fulfillmentMethod': fulfillmentMethod.firestoreValue,
        'idempotencyKey': idempotencyKey,
      });
      final clientSecret = data['paymentIntentClientSecret'] as String?;
      final paymentIntentId = data['paymentIntentId'] as String?;
      if (clientSecret == null || paymentIntentId == null) {
        throw const StripePaymentException(
          'Stripe did not return a valid payment session.',
        );
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Hungry Spot',
          primaryButtonLabel: 'Pay USD ${amount.toStringAsFixed(2)}',
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFF23845),
              background: Colors.white,
              componentBackground: Color(0xFFFFF8F8),
              componentBorder: Color(0xFFF6D9DD),
              componentDivider: Color(0xFFF0E5E7),
              componentText: Color(0xFF15161C),
              primaryText: Color(0xFF15161C),
              secondaryText: Color(0xFF858C98),
              placeholderText: Color(0xFFA0A5AE),
              icon: Color(0xFFF23845),
              error: Color(0xFFC92531),
            ),
            shapes: PaymentSheetShape(borderRadius: 16, borderWidth: 1),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      final verificationData = await _callFunction('verifyPaymentIntent', {
        'paymentIntentId': paymentIntentId,
      });
      if (verificationData['status'] != 'succeeded') {
        throw const StripePaymentException(
          'The card payment could not be verified.',
        );
      }

      return StripePaymentResult(
        paymentIntentId: paymentIntentId,
        amountCents: amountCents,
      );
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        throw const StripePaymentException(
          'Payment was cancelled.',
          cancelled: true,
        );
      }
      throw StripePaymentException(
        error.error.localizedMessage ?? 'Stripe could not process the card.',
      );
    } on FirebaseFunctionsException catch (error) {
      throw _functionsError(error);
    }
  }

  /// Confirms a card collected by Stripe's PCI-compliant CardFormField.
  ///
  /// Only the cardholder name is supplied by the app. The card number, expiry,
  /// and CVC remain inside Stripe's native SDK and are never available to this
  /// service or written to Firestore.
  Future<StripePaymentResult> payWithCard({
    required double amount,
    required FulfillmentMethod fulfillmentMethod,
    required String cardholderName,
  }) async {
    if (!isConfigured) {
      throw const StripePaymentException(
        'Stripe test mode is not configured on this device yet.',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const StripePaymentException('Please sign in again before paying.');
    }

    final amountCents = (amount * 100).round();
    final nonce = Random.secure().nextInt(1 << 32).toRadixString(16);
    final idempotencyKey =
        '${user.uid}-${DateTime.now().microsecondsSinceEpoch}-$nonce';

    try {
      final data = await _callFunction('createPaymentIntent', {
        'amount': amountCents,
        'currency': 'usd',
        'fulfillmentMethod': fulfillmentMethod.firestoreValue,
        'idempotencyKey': idempotencyKey,
      });
      final clientSecret = data['paymentIntentClientSecret'] as String?;
      final paymentIntentId = data['paymentIntentId'] as String?;
      if (clientSecret == null || paymentIntentId == null) {
        throw const StripePaymentException(
          'Stripe did not return a valid payment session.',
        );
      }

      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(name: cardholderName.trim()),
          ),
        ),
      );

      final verificationData = await _callFunction('verifyPaymentIntent', {
        'paymentIntentId': paymentIntentId,
      });
      if (verificationData['status'] != 'succeeded') {
        throw const StripePaymentException(
          'The card payment could not be verified.',
        );
      }

      return StripePaymentResult(
        paymentIntentId: paymentIntentId,
        amountCents: amountCents,
      );
    } on StripeException catch (error) {
      if (error.error.code == FailureCode.Canceled) {
        throw const StripePaymentException(
          'Payment was cancelled.',
          cancelled: true,
        );
      }
      throw StripePaymentException(
        error.error.localizedMessage ?? 'Stripe could not process the card.',
      );
    } on FirebaseFunctionsException catch (error) {
      throw _functionsError(error);
    }
  }
}
