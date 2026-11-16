part of '../source_scanner_rules_test.dart';

final class _VoPublicRawConstructorTest extends _ValueObjectRuleTest {
  static Map<String, Future<void> Function(_VoPublicRawConstructorTest)> get _allCases =>
      caseSet<_VoPublicRawConstructorTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsPrivateRawRedirect': (t) => t._allowsPrivateRawRedirect(),
          'test_allowsValidatedFactoryWithoutRedirect': (t) =>
              t._allowsValidatedFactoryWithoutRedirect(),
          'test_allowsRedirectOutsideValueObjectsPath': (t) =>
              t._allowsRedirectOutsideValueObjectsPath(),
          'test_allowsParameterlessPublicRedirect': (t) => t._allowsParameterlessPublicRedirect(),
          'test_reportsAnonymousPublicRawRedirect': (t) => t._reportsAnonymousPublicRawRedirect(),
          'test_reportsNullablePrimitiveParam': (t) => t._reportsNullablePrimitiveParam(),
          'test_reportsMultiParamPublicRawRedirect': (t) => t._reportsMultiParamPublicRawRedirect(),
          'test_allowsCompositeCanonicalRedirect': (t) => t._allowsCompositeCanonicalRedirect(),
          'test_reportsSingleFieldAndNonConstPublicRedirects': (t) =>
              t._reportsSingleFieldAndNonConstPublicRedirects(),
          'test_reportsPassthroughPublicFactory': (t) => t._reportsPassthroughPublicFactory(),
          'test_allowsValidatedFactoryWithAssert': (t) => t._allowsValidatedFactoryWithAssert(),
          'test_allowsTransformingFactory': (t) => t._allowsTransformingFactory(),
          'test_reportsMultiLinePublicRawRedirect': (t) => t._reportsMultiLinePublicRawRedirect(),
        },
      );

  @override
  String get ruleName => 'vo_public_raw_constructor';
  @override
  String get needle => 'const factory Distance.meters';
  @override
  String get path => '$testPackageLibPath/core/domain/values/distance.dart';
  @override
  String get source => r'''
class Distance {
  const factory Distance.meters(double value) = _Meters;
  const Distance._();
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''';

  Future<void> _allowsPrivateRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
class Distance {
  const factory Distance._meters(double value) = _Meters;
  const Distance._();
  factory Distance.fromMeters(double m) {
    assert(m >= 0);
    return Distance._meters(m);
  }
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsValidatedFactoryWithoutRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method, undefined_identifier
class Email {
  const Email._raw(this.value);
  factory Email(String input) {
    return Email._raw(input);
  }
  final String value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsRedirectOutsideValueObjectsPath() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const factory User.empty(double placeholder) = _User;
  const User._();
}
class _User extends User {
  const _User(this.placeholder) : super._();
  final double placeholder;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsParameterlessPublicRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
class Distance {
  const factory Distance.zero() = _DistanceZero;
  const Distance._();
}
class _DistanceZero extends Distance {
  const _DistanceZero() : super._();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsAnonymousPublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email(String value) = _Email;
  const Email._();
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Email(String value) = _Email;', ruleName),
    ]);
  }

  Future<void> _reportsNullablePrimitiveParam() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email.raw(String? value) = _Email;
  const Email._();
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String? value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Email.raw(String? value) = _Email;', ruleName),
    ]);
  }

  Future<void> _reportsMultiParamPublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/money.dart';
    const source = r'''
// ignore_for_file: undefined_method, undefined_class
class Money {
  const factory Money.usd(int cents, Currency currency) = _UsdMoney;
  const Money._();
}
class _UsdMoney extends Money {
  const _UsdMoney(this.cents, this.currency) : super._();
  final int cents;
  final Currency currency;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(
        source,
        'const factory Money.usd(int cents, Currency currency) = _UsdMoney;',
        ruleName,
      ),
    ]);
  }

  Future<void> _allowsCompositeCanonicalRedirect() async {
    await assertAllows(r'''
// ignore_for_file: redirect_to_non_class
enum Currency { usd, eur }
class Money {
  const Money._();
  const factory Money({required int cents, required Currency currency}) = _Money;
  factory Money.usd(double dollars) => Money(cents: (dollars * 100).round(), currency: .usd);
}
''', path: '$testPackageLibPath/core/domain/values/money.dart');
  }

  Future<void> _reportsSingleFieldAndNonConstPublicRedirects() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    const source = r'''
// ignore_for_file: redirect_to_non_class
class Email {
  const factory Email({required String value}) = _Email;
  factory Email.raw(String value) = _RawEmail;
  const Email._();
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Email({required String value}) = _Email;', ruleName),
      compatLint(source, 'factory Email.raw(String value) = _RawEmail;', ruleName),
    ]);
  }

  Future<void> _reportsPassthroughPublicFactory() async {
    final filePath = '$testPackageLibPath/core/domain/values/weight_adjustment.dart';
    const source = r'''
// ignore_for_file: undefined_method
class WeightAdjustment {
  const factory WeightAdjustment._kilograms(double value) = _Kg;
  const WeightAdjustment._();
  factory WeightAdjustment.kilograms(double value) => WeightAdjustment._kilograms(value);
}
class _Kg extends WeightAdjustment {
  const _Kg(this.value) : super._();
  final double value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'factory WeightAdjustment.kilograms', ruleName),
    ]);
  }

  Future<void> _allowsValidatedFactoryWithAssert() async {
    final filePath = '$testPackageLibPath/core/domain/values/weight.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method
class Weight {
  const factory Weight._kilograms(double value) = _Kg;
  const Weight._();
  factory Weight.kilograms(double value) {
    assert(value >= 0, 'Weight cannot be negative');
    return Weight._kilograms(value);
  }
}
class _Kg extends Weight {
  const _Kg(this.value) : super._();
  final double value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsTransformingFactory() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email._raw(String value) = _Email;
  const Email._();
  factory Email(String input) => Email._raw(input.trim());
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsMultiLinePublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Distance {
  const factory Distance.meters(
    double value,
  ) = _Meters;
  const Distance._();
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Distance.meters(', ruleName),
    ]);
  }
}

void _defineSourceScannerRulesPart12BTests() {
  analysisRuleSuite<_VoPublicRawConstructorTest>(
    'VoPublicRawConstructorTest',
    _VoPublicRawConstructorTest.new,
    _VoPublicRawConstructorTest._allCases,
  );
}
