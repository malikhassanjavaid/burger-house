import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

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

  static const _publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  final FirebaseFunctions _functions;

  static bool get isConfigured => _publishableKey.startsWith('pk_test_');

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
      throw const StripePaymentException(
        'Please sign in again before paying.',
      );
    }

    final amountCents = (amount * 100).round();
    final nonce = Random.secure().nextInt(1 << 32).toRadixString(16);
    final idempotencyKey = '${user.uid}-${DateTime.now().microsecondsSinceEpoch}-$nonce';

    try {
      final callable = _functions.httpsCallable('createPaymentIntent');
      final response = await callable.call<Map<String, dynamic>>({
        'amount': amountCents,
        'currency': 'usd',
        'fulfillmentMethod': fulfillmentMethod.firestoreValue,
        'idempotencyKey': idempotencyKey,
      });
      final data = Map<String, dynamic>.from(response.data);
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
          primaryButtonLabel: 'Pay \${amount.toStringAsFixed(2)}',
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

      final verify = _functions.httpsCallable('verifyPaymentIntent');
      final verification = await verify.call<Map<String, dynamic>>({
        'paymentIntentId': paymentIntentId,
      });
      final verificationData = Map<String, dynamic>.from(verification.data);
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
      throw StripePaymentException(
        error.message ?? 'The secure payment service is unavailable.',
      );
    }
  }
}
