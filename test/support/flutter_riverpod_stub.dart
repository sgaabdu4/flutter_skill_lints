import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

const flutterRiverpodStub = r'''
import 'package:flutter/widgets.dart';

class WidgetRef {
  T watch<T>(Object provider) => throw UnimplementedError();
  T read<T>(Object provider) => throw UnimplementedError();
}

abstract class ConsumerWidget extends Widget {
  const ConsumerWidget({super.key});
  Widget build(BuildContext context, WidgetRef ref);
}

abstract class ConsumerStatefulWidget extends StatefulWidget {
  const ConsumerStatefulWidget({super.key});
}
''';

void addFlutterRiverpod(AnalysisRuleTest test) {
  test.newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', flutterRiverpodStub);
}
