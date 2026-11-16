import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

void addMocktail(AnalysisRuleTest test) {
  final mocktail = test.newPackage('mocktail');
  mocktail.addFile('lib/mocktail.dart', "export 'src/mocktail.dart';");
  mocktail.addFile('lib/src/mocktail.dart', r'''
final class VerificationResult {
  void called(int count) {}
}

typedef Verify = VerificationResult Function<T>(T Function() invocation);
typedef VerifyInOrder = List<VerificationResult> Function<T>(List<T Function()> invocations);

Verify _makeVerify(bool never) => <T>(T Function() invocation) => VerificationResult();
VerifyInOrder _makeVerifyInOrder() => <T>(List<T Function()> invocations) => [];

Verify get verify => _makeVerify(false);
Verify get verifyNever => _makeVerify(true);
VerifyInOrder get verifyInOrder => _makeVerifyInOrder();
''');
}
