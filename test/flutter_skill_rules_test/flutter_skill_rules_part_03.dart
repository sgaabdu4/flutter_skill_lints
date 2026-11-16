part of '../flutter_skill_rules_test.dart';

const _providerTurnHopCodeName = 'avoid_provider_turn_hop';

final class _ProviderTurnHopTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_ProviderTurnHopTest)> get _allCases =>
      caseSet<_ProviderTurnHopTest>(
        parent: const {},
        own: {
          for (final row in allProviderTurnHopRows.where((row) => !row.realSdkOnly))
            'test_${row.id}': (t) => t._row(row),
        },
      );

  @override
  void setUp() {
    rule = AvoidSyncNotifierStateRead();
    newPackage('riverpod_annotation').addFile('lib/riverpod_annotation.dart', r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();

class KeepAliveLink {
  void close() {}
}

class Ref {
  KeepAliveLink keepAlive() => KeepAliveLink();
  void invalidateSelf() {}
  void onDispose(void Function() callback) {}
}
''');
    super.setUp();
  }

  Future<void> _row(TurnHopRow row) async {
    final path = '$testPackageLibPath/row.dart';
    newFile(path, row.source);
    result = await resolveFile(convertPath(path));
    final lines = [
      for (final diagnostic in result.diagnostics)
        if (diagnostic.diagnosticCode.lowerCaseName == _providerTurnHopCodeName)
          result.lineInfo.getLocation(diagnostic.offset).lineNumber,
    ]..sort();
    expect(lines, [...row.hopLines]..sort());
  }
}

void _defineFlutterSkillRulesPart03Tests() {
  analysisRuleSuite<_ProviderTurnHopTest>(
    'ProviderTurnHopTest',
    _ProviderTurnHopTest.new,
    _ProviderTurnHopTest._allCases,
  );
}
