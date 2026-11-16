import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

const flutterWidgetsStub = r'''
class Key {
  const Key(String value);
}

class Color {
  const Color(int value);
}

class Alignment {
  const Alignment(double x, double y);
  static const Alignment center = Alignment(0, 0);
}

class EdgeInsets {
  const EdgeInsets.all(double value);
  const EdgeInsets.only({double left = 0, double top = 0, double right = 0, double bottom = 0});
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
  const EdgeInsets.fromLTRB(double left, double top, double right, double bottom);
}

class BoxConstraints {
  const BoxConstraints();
}

class BoxDecoration {
  const BoxDecoration();
}

class Widget {
  const Widget({Key? key});
}

class BuildContext {
  bool get mounted => true;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => BuildContext();
  bool get mounted => true;
  void initState() {}
  void dispose() {}
  void deactivate() {}
  void activate() {}
  void reassemble() {}
  void didChangeDependencies() {}
  void didUpdateWidget(T oldWidget) {}
  void setState(void Function() fn) => fn();
  Widget build(BuildContext context);
}

class Padding extends Widget {
  const Padding({super.key, required EdgeInsets padding, Widget? child});
}

class Align extends Widget {
  const Align({super.key, Alignment alignment = Alignment.center, Widget? child});
}

class Center extends Widget {
  const Center({super.key, Widget? child});
}

class ColoredBox extends Widget {
  const ColoredBox({super.key, required Color color, Widget? child});
}

class DecoratedBox extends Widget {
  const DecoratedBox({super.key, required BoxDecoration decoration, Widget? child});
}

class ConstrainedBox extends Widget {
  const ConstrainedBox({super.key, required BoxConstraints constraints, Widget? child});
}

class SizedBox extends Widget {
  const SizedBox({super.key, double? width, double? height, Widget? child});
  const SizedBox.square({super.key, double? dimension, Widget? child});
  const SizedBox.shrink({super.key});
}

class Opacity extends Widget {
  const Opacity({super.key, required double opacity, Widget? child});
}

class Container extends Widget {
  const Container({
    super.key,
    Alignment? alignment,
    EdgeInsets? padding,
    Color? color,
    double? width,
    double? height,
    Widget? child,
  });
}

enum Axis { horizontal, vertical }

enum MainAxisAlignment { start, end, center, spaceBetween, spaceAround, spaceEvenly }

class Flex extends Widget {
  const Flex({
    super.key,
    required Axis direction,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    double spacing = 0,
    List<Widget> children = const [],
  });
}

class Row extends Widget {
  const Row({
    super.key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    double spacing = 0,
    List<Widget> children = const [],
  });
}

class Column extends Widget {
  const Column({
    super.key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    double spacing = 0,
    List<Widget> children = const [],
  });
}

class Expanded extends Widget {
  const Expanded({super.key, Widget? child});
}

class Spacer extends Widget {
  const Spacer({super.key});
}

extension WidgetListSeparator on List<Widget> {
  List<Widget> separatedBy(Widget separator) => this;
}

class Animation<T> {
  const Animation();
}

class AlwaysStoppedAnimation<T> extends Animation<T> {
  const AlwaysStoppedAnimation(T value);
}

class Image extends Widget {
  const Image({super.key, Animation<double>? opacity, String? semanticLabel});
  const Image.network(String src, {super.key, Animation<double>? opacity});
}

class GestureDetector extends Widget {
  const GestureDetector({super.key, void Function()? onTap, void Function()? onLongPress, Widget? child});
}

class Text extends Widget {
  const Text(String data, {super.key});
}
''';

void addFlutterWidgets(AnalysisRuleTest test, [String extra = '']) {
  test.newPackage('flutter').addFile('lib/widgets.dart', '$flutterWidgetsStub$extra');
}
