import 'package:flutter/material.dart';

/// Live Add Card preview matched to the selected 550 x 333 reference.
class AddCardPreview extends StatelessWidget {
  const AddCardPreview({
    super.key,
    required this.name,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    this.hasCardInput = false,
  });

  static const _referenceWidth = 550.0;
  static const _referenceHeight = 333.0;
  static const _ink = Color(0xFF0C2729);

  final String name;
  final String? last4;
  final int? expiryMonth;
  final int? expiryYear;
  final bool hasCardInput;

  String get _displayName {
    final value = name.trim();
    return value.isEmpty ? 'Alena Syabian' : value;
  }

  String get _displayNumber {
    final suffix = last4?.trim();
    final inputStarted = hasCardInput || (suffix?.isNotEmpty ?? false);
    if (!inputStarted) return '4241 9214 7219 3456';
    if (suffix == null || suffix.isEmpty) return '•••• •••• •••• ••••';

    return '•••• •••• •••• ${suffix.padLeft(4, '•')}';
  }

  String get _displayExpiry {
    final year = expiryYear?.toString();
    if (expiryMonth == null || year == null || year.length < 2) {
      return hasCardInput ? 'MM/YY' : '12/24';
    }
    return '${expiryMonth.toString().padLeft(2, '0')}/${year.substring(year.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _referenceWidth / _referenceHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/add_card_reference_background.png',
              key: const ValueKey('add-card-reference-artwork'),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: _referenceWidth,
                height: _referenceHeight,
                child: Stack(
                  children: [
                    Positioned(
                      left: 42,
                      top: 43,
                      right: 215,
                      child: Text(
                        _displayName,
                        key: const ValueKey('add-card-preview-name'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 25,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 42,
                      top: 205,
                      right: 30,
                      child: Text(
                        _displayNumber,
                        key: const ValueKey('add-card-preview-number'),
                        maxLines: 1,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.15,
                          wordSpacing: 15,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 42,
                      top: 277,
                      child: Text(
                        _displayExpiry,
                        key: const ValueKey('add-card-preview-expiry'),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 23,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
