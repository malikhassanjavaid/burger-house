import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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
  final _paymentService = StripePaymentService();
  bool _loading = false;

  Future<void> _openPaymentSheet() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final result = await _paymentService.pay(
        amount: widget.amount,
        fulfillmentMethod: widget.fulfillmentMethod,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } on StripePaymentException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!error.cancelled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The secure card form could not open.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.fulfillmentMethod.isPickup;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AppLoadingOverlay(
        loading: _loading,
        semanticsLabel: 'Opening secure card payment',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0x22304A5C),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox.square(
                          dimension: 44,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.red,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Card payment',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF23845),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33F23845),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'STRIPE TEST MODE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '\$${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        isPickup
                            ? 'Secure payment for store pickup'
                            : 'Secure payment for delivery',
                        style: const TextStyle(
                          color: Color(0xFFFFE7E9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HUNGRY SPOT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Test card details',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const _TestDetailRow(
                  icon: Icons.numbers_rounded,
                  label: 'Card number',
                  value: '4242 4242 4242 4242',
                ),
                const _TestDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Expiry',
                  value: 'Any future date',
                ),
                const _TestDetailRow(
                  icon: Icons.password_rounded,
                  label: 'CVC and ZIP',
                  value: 'Any valid values',
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.red,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Card details are collected by Stripe and never stored in Hungry Spot.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppPrimaryButton(
                  label: StripePaymentService.isConfigured
                      ? 'OPEN SECURE CARD FORM'
                      : 'STRIPE SETUP REQUIRED',
                  onPressed: _loading ? null : _openPaymentSheet,
                  height: 52,
                  borderRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TestDetailRow extends StatelessWidget {
  const _TestDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE9ECF1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.red, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
