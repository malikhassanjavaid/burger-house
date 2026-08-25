import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../models/fulfillment_method.dart';
import '../services/stripe_payment_service.dart';

class StripeCardPaymentScreen extends StatefulWidget {
  const StripeCardPaymentScreen({
    super.key,
    required this.amount,
    required this.fulfillmentMethod,
  });

  final double amount;
  final FulfillmentMethod fulfillmentMethod;

  @override
  State<StripeCardPaymentScreen> createState() =>
      _StripeCardPaymentScreenState();
}

class _StripeCardPaymentScreenState extends State<StripeCardPaymentScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _cardController = CardEditController();
  final _paymentService = StripePaymentService();
  final _cardDetails = ValueNotifier<CardFieldInputDetails?>(null);

  bool _loading = false;
  bool _showErrors = false;

  bool get _canSubmit =>
      _nameController.text.trim().length >= 2 &&
      (_cardDetails.value?.complete ?? false);

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _cardController.dispose();
    _cardDetails.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_canSubmit) {
      setState(() => _showErrors = true);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _paymentService.payWithCard(
        amount: widget.amount,
        fulfillmentMethod: widget.fulfillmentMethod,
        cardholderName: _nameController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on StripePaymentException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!error.cancelled) _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('The secure payment could not be completed. Try again.');
    }
  }

  void _showError(String message) {
    AppNotification.show(
      context,
      message: message,
      tone: AppNotificationTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      loading: _loading,
      semanticsLabel: 'Processing secure payment',
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 18),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, name, _) {
                    return ValueListenableBuilder<CardFieldInputDetails?>(
                      valueListenable: _cardDetails,
                      builder: (context, details, _) {
                        return _CardPreview(name: name.text, details: details);
                      },
                    );
                  },
                ),
                const SizedBox(height: 22),
                const Text('Cardholder name', style: AppTypography.label),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    _nameFocusNode.unfocus();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _cardController.focus();
                    });
                  },
                  onTapOutside: (_) => _nameFocusNode.unfocus(),
                  decoration: _nameDecoration(),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, name, _) {
                    if (!_showErrors || name.text.trim().length >= 2) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: _FieldError('Enter the cardholder name.'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('Card details', style: AppTypography.label),
                const SizedBox(height: 8),
                _StableStripeCardField(
                  controller: _cardController,
                  details: _cardDetails,
                  showError: _showErrors,
                  onInteraction: _nameFocusNode.unfocus,
                  onCompleted: () {
                    if (mounted) setState(() => _showErrors = false);
                  },
                ),
                ValueListenableBuilder<CardFieldInputDetails?>(
                  valueListenable: _cardDetails,
                  builder: (context, details, _) {
                    if (!_showErrors || (details?.complete ?? false)) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: _FieldError(
                        'Enter a complete card number, expiry date and CVC.',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                const _SecurityNote(),
                const SizedBox(height: 12),
                const _TestCardHint(),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _PaymentActionBar(
          amount: widget.amount,
          loading: _loading,
          onPay: _pay,
        ),
      ),
    );
  }

  InputDecoration _nameDecoration() {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: 'Name on card',
      prefixIcon: const Icon(
        Icons.person_outline_rounded,
        size: 20,
        color: AppColors.red,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(const Color(0xFFE4E7EC)),
      enabledBorder: border(const Color(0xFFE4E7EC)),
      focusedBorder: border(AppColors.red, 1.5),
    );
  }
}

class _StableStripeCardField extends StatelessWidget {
  const _StableStripeCardField({
    required this.controller,
    required this.details,
    required this.showError,
    required this.onInteraction,
    required this.onCompleted,
  });

  final CardEditController controller;
  final ValueNotifier<CardFieldInputDetails?> details;
  final bool showError;
  final VoidCallback onInteraction;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showError && !(details.value?.complete ?? false)
              ? AppColors.red
              : const Color(0xFFE4E7EC),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F182230),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: CardField(
        key: const ValueKey('hungry-spot-stripe-card-field'),
        controller: controller,
        enablePostalCode: false,
        autofocus: false,
        onFocus: (focusedField) {
          if (focusedField != null) onInteraction();
        },
        dangerouslyGetFullCardDetails: false,
        dangerouslyUpdateFullCardDetails: false,
        style: const TextStyle(
          color: AppColors.dark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'Card number',
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        ),
        onCardChanged: (value) {
          final wasComplete = details.value?.complete ?? false;
          details.value = value;
          if (showError && !wasComplete && (value?.complete ?? false)) {
            onCompleted();
          }
        },
      ),
    );
  }
}

class _PaymentActionBar extends StatelessWidget {
  const _PaymentActionBar({
    required this.amount,
    required this.loading,
    required this.onPay,
  });

  final double amount;
  final bool loading;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 14,
      shadowColor: const Color(0x2417222D),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL', style: AppTypography.caption),
                  const SizedBox(height: 2),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: AppTypography.totalPrice,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppPrimaryButton(
                label: 'PAY & CONTINUE',
                icon: Icons.arrow_forward_rounded,
                height: 52,
                borderRadius: 16,
                isLoading: loading,
                onPressed: loading ? null : onPay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x1A17222D),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox.square(
              dimension: 44,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.red,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text('Add card', style: AppTypography.pageHeader),
        ),
      ],
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.name, required this.details});

  final String name;
  final CardFieldInputDetails? details;

  @override
  Widget build(BuildContext context) {
    final month = details?.expiryMonth;
    final yearText = details?.expiryYear?.toString() ?? '';
    final expiry = month == null || yearText.length < 2
        ? 'MM/YY'
        : '${month.toString().padLeft(2, '0')}/${yearText.substring(yearText.length - 2)}';
    final brand = (details?.brand ?? 'debit').toUpperCase();
    final displayName = name.trim().isEmpty
        ? 'YOUR NAME'
        : name.trim().toUpperCase();

    return AspectRatio(
      aspectRatio: 1.68,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      brand == 'UNKNOWN' ? 'DEBIT' : brand,
                      style: const TextStyle(
                        color: Color(0xFF171A21),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'HUNGRY SPOT',
                      style: TextStyle(
                        color: Color(0xFF171A21),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 31,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD45B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF4B926)),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Color(0xFF9C6A00),
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.contactless_rounded,
                      color: Color(0xFF171A21),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '\u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  \u2022\u2022\u2022\u2022  ${details?.last4 ?? '\u2022\u2022\u2022\u2022'}',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF171A21),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.7,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _CardDatum(
                        label: 'CARDHOLDER',
                        value: displayName,
                      ),
                    ),
                    _CardDatum(label: 'EXPIRES', value: expiry),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDatum extends StatelessWidget {
  const _CardDatum({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF171A21),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: AppColors.redDark,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.red, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Encrypted by Stripe. Hungry Spot never stores your full card number or CVC.',
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestCardHint extends StatelessWidget {
  const _TestCardHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0A0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_outlined, color: Color(0xFFC57B00), size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Demo card: 4242 4242 4242 4242 \u2022 any future expiry \u2022 any CVC',
              style: TextStyle(
                color: Color(0xFF835700),
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
