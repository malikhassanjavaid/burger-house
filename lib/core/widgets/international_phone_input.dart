import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _fallbackCountryCode = 'SA';

String? validateInternationalPhoneNumber(String? value) {
  final raw = value?.trim() ?? '';
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  final minimumDigits = raw.startsWith('+') ? 8 : 7;
  if (digits.length < minimumDigits || digits.length > 15) {
    return 'Enter a valid phone number';
  }
  return null;
}

class InternationalPhoneInput extends StatefulWidget {
  const InternationalPhoneInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.countrySelectorKey,
    required this.phoneFieldKey,
    this.defaultCountryCode,
    this.validator,
    this.errorText,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.fieldDecoration = const InputDecoration(),
    this.countryBackgroundColor = Colors.white,
    this.countryBorderColor = const Color(0xFFD9D9DE),
    this.countryAccentColor = const Color(0xFFF23845),
    this.countryWidth = 108,
    this.countryHeight = 48,
    this.textStyle,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final Key countrySelectorKey;
  final Key phoneFieldKey;
  final String? defaultCountryCode;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final InputDecoration fieldDecoration;
  final Color countryBackgroundColor;
  final Color countryBorderColor;
  final Color countryAccentColor;
  final double countryWidth;
  final double countryHeight;
  final TextStyle? textStyle;

  @override
  State<InternationalPhoneInput> createState() =>
      _InternationalPhoneInputState();
}

class _InternationalPhoneInputState extends State<InternationalPhoneInput> {
  final _countryService = CountryService();
  final _nationalController = TextEditingController();
  late Country _country;
  bool _resolvedInitialCountry = false;

  String get _normalizedNationalNumber {
    var digits = _nationalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 7 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  String get _completeNumber =>
      '+${_country.phoneCode}$_normalizedNationalNumber';

  @override
  void initState() {
    super.initState();
    _country =
        _countryService.findByCode(widget.defaultCountryCode) ??
        _countryService.findByCode(_fallbackCountryCode)!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedInitialCountry) return;
    final localeCountry =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode ??
        Localizations.localeOf(context).countryCode;
    final preferredCountry =
        _countryService.findByCode(widget.defaultCountryCode) ??
        _countryService.findByCode(localeCountry) ??
        _countryService.findByCode(_fallbackCountryCode)!;
    _applyValue(widget.value, fallback: preferredCountry);
    _resolvedInitialCountry = true;
  }

  @override
  void didUpdateWidget(covariant InternationalPhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_resolvedInitialCountry || widget.value == oldWidget.value) return;
    if (_canonicalDigits(widget.value) == _canonicalDigits(_completeNumber)) {
      return;
    }
    _applyValue(widget.value, fallback: _country);
  }

  @override
  void dispose() {
    _nationalController.dispose();
    super.dispose();
  }

  String _canonicalDigits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  void _applyValue(String value, {required Country fallback}) {
    final trimmed = value.trim();
    final digits = _canonicalDigits(trimmed);
    var selected = fallback;
    var national = digits;

    if ((trimmed.startsWith('+') || trimmed.startsWith('00')) &&
        digits.isNotEmpty) {
      final matches =
          _countryService
              .getAll()
              .where((country) => digits.startsWith(country.phoneCode))
              .toList()
            ..sort(
              (left, right) =>
                  right.phoneCode.length.compareTo(left.phoneCode.length),
            );
      if (matches.isNotEmpty) {
        final longestCodeLength = matches.first.phoneCode.length;
        final longestMatches = matches
            .where((country) => country.phoneCode.length == longestCodeLength)
            .toList();
        selected = longestMatches.firstWhere(
          (country) => country.countryCode == fallback.countryCode,
          orElse: () => longestMatches.first,
        );
        national = digits.substring(selected.phoneCode.length);
      }
    }

    _country = selected;
    _nationalController.text = national;
  }

  void _emitValue() => widget.onChanged(_completeNumber);

  void _selectCountry() {
    FocusScope.of(context).unfocus();
    final pickerHeight = MediaQuery.sizeOf(context).height * 0.5;
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      useSafeArea: true,
      showDragHandle: false,
      moveAlongWithKeyboard: true,
      favorite: const ['SA', 'PK', 'AE', 'GB', 'US'],
      header: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9DE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.countryAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.public_rounded,
                    color: widget.countryAccentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your country',
                        style: TextStyle(
                          color: Color(0xFF1A1A20),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select a flag and phone code',
                        style: TextStyle(
                          color: Color(0xFF7A7A84),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        bottomSheetHeight: pickerHeight,
        flagSize: 27,
        inputDecoration: InputDecoration(
          hintText: 'Search country or dial code',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: widget.countryAccentColor,
          ),
          filled: true,
          fillColor: const Color(0xFFF7F7F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (country) {
        setState(() => _country = country);
        _emitValue();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxNationalLength = 15 - _country.phoneCode.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: widget.countryWidth,
          height: widget.countryHeight,
          child: Material(
            color: widget.countryBackgroundColor,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              key: widget.countrySelectorKey,
              onTap: _selectCountry,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: widget.countryBorderColor),
                ),
                child: Row(
                  children: [
                    Text(
                      _country.flagEmoji,
                      style: const TextStyle(fontSize: 20),
                      textScaler: TextScaler.noScaling,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '+${_country.phoneCode}',
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          color: Color(0xFF1A1A20),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.countryAccentColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: TextFormField(
            key: widget.phoneFieldKey,
            controller: _nationalController,
            autofocus: widget.autofocus,
            keyboardType: TextInputType.phone,
            textInputAction: widget.textInputAction,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(maxNationalLength),
            ],
            style: widget.textStyle,
            decoration: widget.fieldDecoration.copyWith(
              errorText: widget.errorText,
              counterText: '',
            ),
            validator: widget.validator == null
                ? null
                : (_) => widget.validator!(_completeNumber),
            onChanged: (_) => _emitValue(),
            onFieldSubmitted: widget.onFieldSubmitted,
          ),
        ),
      ],
    );
  }
}
