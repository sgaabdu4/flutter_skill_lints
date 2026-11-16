import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test/test.dart';

typedef FixFactory = ResolvedCorrectionProducer Function(CorrectionProducerContext context);

abstract class FixRuleTest extends AnalysisRuleTest {
  Future<void> expectOnlyRuleDiagnostics(
    String source,
    List<({int offset, int length})> expected,
  ) async {
    final unit = await resolveFile(newFile(testFilePath, source).path);
    final found = [
      for (final d in unit.diagnostics)
        if (d.diagnosticCode.lowerCaseName == rule.name) (offset: d.offset, length: d.length),
    ];
    expect(found, expected);
  }

  Future<String?> applyFix(String source, FixFactory create, {int occurrence = 0}) async {
    final file = newFile(testFilePath, source);
    final unit = await resolveFile(file.path);
    final libraryResult = await (await session).getResolvedLibrary(file.path);
    final ruleName = rule.name;
    final reported = unit.diagnostics.where((d) => d.diagnosticCode.lowerCaseName == ruleName);
    expect(reported.length, greaterThan(occurrence), reason: 'rule $ruleName did not report');
    final Diagnostic diagnostic = reported.elementAt(occurrence);
    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult as ResolvedLibraryResult,
      unitResult: unit,
      diagnostic: diagnostic,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
    );
    return _editedSource(source, file.path, create(context));
  }

  Future<String?> applyAssist(
    String source,
    FixFactory create, {
    required int offset,
    int length = 0,
  }) async {
    final file = newFile(testFilePath, source);
    final unit = await resolveFile(file.path);
    final libraryResult = await (await session).getResolvedLibrary(file.path);
    final context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult as ResolvedLibraryResult,
      unitResult: unit,
      selectionOffset: offset,
      selectionLength: length,
    );
    return _editedSource(source, file.path, create(context));
  }

  Future<String?> _editedSource(
    String source,
    String path,
    ResolvedCorrectionProducer producer,
  ) async {
    final builder = ChangeBuilder(session: await session);
    await producer.compute(builder);
    final edits = builder.sourceChange.getFileEdit(path)?.edits;
    return edits == null ? null : SourceEdit.applySequence(source, edits);
  }

  Future<void> expectFix(
    String source,
    FixFactory create, {
    required String expected,
    int occurrence = 0,
  }) async {
    expect(await applyFix(source, create, occurrence: occurrence), expected);
  }

  Future<void> expectNoFix(String source, FixFactory create, {int occurrence = 0}) async {
    expect(await applyFix(source, create, occurrence: occurrence), isNull);
  }
}
