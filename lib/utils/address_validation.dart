import 'package:flutter/services.dart';

/// Country-specific phone and postal/ZIP rules for checkout.
class CountryAddressRules {
  CountryAddressRules({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.minNationalDigits,
    required this.maxNationalDigits,
    required this.zipLabel,
    required this.zipPattern,
    required this.zipHint,
    required this.phoneHint,
    this.nationalStartsWith,
    this.zipAllowsLetters = false,
    this.zipMaxLength = 10,
  });

  final String code;
  final String name;
  final String dialCode;
  final int minNationalDigits;
  final int maxNationalDigits;
  final String? nationalStartsWith;
  final String zipLabel;
  final RegExp zipPattern;
  final String zipHint;
  final String phoneHint;
  final bool zipAllowsLetters;
  final int zipMaxLength;

  static final List<CountryAddressRules> supported = [
    CountryAddressRules(
      code: 'US',
      name: 'United States',
      dialCode: '+1',
      minNationalDigits: 10,
      maxNationalDigits: 10,
      zipLabel: 'ZIP Code',
      zipPattern: RegExp(r'^\d{5}(-\d{4})?$'),
      zipHint: '5 digits or 12345-6789',
      phoneHint: '10-digit mobile number',
      zipMaxLength: 10,
    ),
    CountryAddressRules(
      code: 'CA',
      name: 'Canada',
      dialCode: '+1',
      minNationalDigits: 10,
      maxNationalDigits: 10,
      zipLabel: 'Postal Code',
      zipPattern: RegExp(r'^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$'),
      zipHint: 'A1A 1A1',
      phoneHint: '10-digit phone number',
      zipAllowsLetters: true,
      zipMaxLength: 7,
    ),
    CountryAddressRules(
      code: 'GB',
      name: 'United Kingdom',
      dialCode: '+44',
      minNationalDigits: 10,
      maxNationalDigits: 10,
      nationalStartsWith: '7',
      zipLabel: 'Postcode',
      zipPattern: RegExp(r'^[A-Za-z]{1,2}\d[A-Za-z\d]?\s?\d[A-Za-z]{2}$'),
      zipHint: 'SW1A 1AA',
      phoneHint: '10 digits, usually starts with 7',
      zipAllowsLetters: true,
      zipMaxLength: 8,
    ),
    CountryAddressRules(
      code: 'PK',
      name: 'Pakistan',
      dialCode: '+92',
      minNationalDigits: 10,
      maxNationalDigits: 10,
      nationalStartsWith: '3',
      zipLabel: 'Postal Code',
      zipPattern: RegExp(r'^\d{5}$'),
      zipHint: '5 digits',
      phoneHint: '10 digits, starts with 3',
      zipMaxLength: 5,
    ),
    CountryAddressRules(
      code: 'AE',
      name: 'United Arab Emirates',
      dialCode: '+971',
      minNationalDigits: 9,
      maxNationalDigits: 9,
      nationalStartsWith: '5',
      zipLabel: 'Postal Code',
      zipPattern: RegExp(r'^\d{5}$'),
      zipHint: 'Optional 5 digits (e.g. 00000)',
      phoneHint: '9 digits, starts with 5',
      zipMaxLength: 5,
    ),
    CountryAddressRules(
      code: 'IN',
      name: 'India',
      dialCode: '+91',
      minNationalDigits: 10,
      maxNationalDigits: 10,
      zipLabel: 'PIN Code',
      zipPattern: RegExp(r'^\d{6}$'),
      zipHint: '6 digits',
      phoneHint: '10 digits, starts with 6–9',
      zipMaxLength: 6,
    ),
    CountryAddressRules(
      code: 'AU',
      name: 'Australia',
      dialCode: '+61',
      minNationalDigits: 9,
      maxNationalDigits: 9,
      nationalStartsWith: '4',
      zipLabel: 'Postcode',
      zipPattern: RegExp(r'^\d{4}$'),
      zipHint: '4 digits',
      phoneHint: '9 digits, starts with 4',
      zipMaxLength: 4,
    ),
    CountryAddressRules(
      code: 'SA',
      name: 'Saudi Arabia',
      dialCode: '+966',
      minNationalDigits: 9,
      maxNationalDigits: 9,
      nationalStartsWith: '5',
      zipLabel: 'Postal Code',
      zipPattern: RegExp(r'^\d{5}$'),
      zipHint: '5 digits',
      phoneHint: '9 digits, starts with 5',
      zipMaxLength: 5,
    ),
  ];

  static CountryAddressRules defaultCountry =
      supported.firstWhere((c) => c.code == 'PK', orElse: () => supported.first);

  static CountryAddressRules byCode(String code) {
    return supported.firstWhere(
      (c) => c.code == code,
      orElse: () => defaultCountry,
    );
  }

  String normalizeNationalPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  String? validateNationalPhone(String? value) {
    final digits = normalizeNationalPhone(value?.trim() ?? '');
    if (digits.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Use digits only (no spaces or symbols)';
    }
    if (digits.length < minNationalDigits || digits.length > maxNationalDigits) {
      return 'Enter $minNationalDigits–$maxNationalDigits digits for $name';
    }
    if (nationalStartsWith != null) {
      final prefixes = nationalStartsWith!.split('|');
      final ok = prefixes.any((p) => digits.startsWith(p));
      if (!ok) {
        return 'Number should start with ${prefixes.join(' or ')}';
      }
    }
    if (code == 'IN' && !RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  String toE164(String nationalRaw) {
    final digits = normalizeNationalPhone(nationalRaw);
    return '$dialCode$digits';
  }

  String? validateZip(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Please enter $zipLabel';
    }
    if (code == 'AE') {
      if (v == '00000' || RegExp(r'^\d{5}$').hasMatch(v)) return null;
      return 'Use 5 digits or 00000 if not applicable';
    }
    if (!zipPattern.hasMatch(v)) {
      return 'Enter a valid $zipLabel ($zipHint)';
    }
    return null;
  }

  String normalizeZip(String raw) {
    final trimmed = raw.trim();
    if (zipAllowsLetters) {
      return trimmed.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    }
    return trimmed;
  }

  List<TextInputFormatter> phoneInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxNationalDigits),
    ];
  }

  List<TextInputFormatter> zipInputFormatters() {
    if (zipAllowsLetters) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\s\-]')),
        LengthLimitingTextInputFormatter(zipMaxLength),
        _UpperCaseTextFormatter(),
      ];
    }
    if (code == 'US') {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
        LengthLimitingTextInputFormatter(zipMaxLength),
      ];
    }
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(zipMaxLength),
    ];
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
